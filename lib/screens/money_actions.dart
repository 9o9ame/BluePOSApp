import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/sale_attempt.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'transaction_widgets.dart';

/// The backend owns posted balances, bank account rules and money. Every
/// financial mutation here is sent with a persistent idempotency key.
enum MoneyActionKind { salePayment, purchasePayment, saleRefund, expense }

extension MoneyActionSpec on MoneyActionKind {
  String get title => switch (this) {
    MoneyActionKind.salePayment => 'Receive Sale Payment',
    MoneyActionKind.purchasePayment => 'Pay Purchase Invoice',
    MoneyActionKind.saleRefund => 'Refund Sales Return',
    MoneyActionKind.expense => 'Record Expense',
  };
  String endpoint(String documentUlid) => switch (this) {
    MoneyActionKind.salePayment => '/api/sales/$documentUlid/payments',
    MoneyActionKind.purchasePayment => '/api/purchases/$documentUlid/payments',
    MoneyActionKind.saleRefund => '/api/sales-returns/$documentUlid/refunds',
    MoneyActionKind.expense => '/api/sales/expenses',
  };
  String get requiredPermission => switch (this) {
    MoneyActionKind.saleRefund => 'sales.return',
    MoneyActionKind.expense => 'expenses.create',
    _ => 'payments.create',
  };
}

class MoneyActionScreen extends StatefulWidget {
  const MoneyActionScreen({
    super.key, required this.app, required this.kind, this.documentUlid = '',
  });
  final AppController app;
  final MoneyActionKind kind;
  final String documentUlid;

  @override
  State<MoneyActionScreen> createState() => _MoneyActionScreenState();
}

class _MoneyActionScreenState extends State<MoneyActionScreen> {
  final amount = TextEditingController();
  final reference = TextEditingController();
  final description = TextEditingController();
  final store = const MoneyActionAttemptStore();
  String method = 'cash';
  Map<String, dynamic>? expenseAccount, paymentAccount;
  DateTime expenseDate = DateTime.now();
  bool loading = true, busy = false, unconfirmed = false;
  Map<String, dynamic>? activePending;
  String? key, error;

  @override
  void initState() {
    super.initState();
    if (widget.kind == MoneyActionKind.expense) {
      _restore();
    } else {
      _restore();
    }
  }

  @override
  void dispose() {
    amount.dispose();
    reference.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final pending = await store.read(
        userUlid: widget.app.currentUserUlid,
        tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
        branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
      );
      if (!mounted) return;
      if (pending != null) {
        setState(() {
          unconfirmed = true;
          activePending = objectOf(pending['payload']);
          key = field(pending['key']);
          error = 'An earlier financial save is unconfirmed. '
            'Only its original request can be retried.';
        });
      }
    } catch (_) {
      if (mounted) { setState(() =>
        error = 'Unable to load secure pending financial request.'); }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseAccount({required bool expense}) async {
    final account = await pickApiRecord(
      context, app: widget.app,
      title: expense ? 'Expense account' : 'Paying account',
      path: widget.kind == MoneyActionKind.expense
        ? '/api/sales/expenses/accounts'
        : '/api/sales/payment-accounts',
    );
    if (account == null || !mounted) return;
    if (!expense && widget.kind == MoneyActionKind.salePayment &&
        method != 'cash' && account['is_bank'] != true) {
      await showApiError(context, 'Select a bank account for this payment.');
      return;
    }
    setState(() {
      if (expense) { expenseAccount = account; }
      else { paymentAccount = account; }
    });
  }

  Future<void> chooseDate() async {
    final chosen = await showDatePicker(context: context,
      initialDate: expenseDate,
      firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 2)));
    if (chosen != null && mounted) setState(() => expenseDate = chosen);
  }

  Future<void> save() async {
    if (busy || loading || !widget.app.hasPermission(widget.kind.requiredPermission)) {
      return;
    }
    if (!unconfirmed) {
      if (widget.kind != MoneyActionKind.expense &&
          !validPublicUlid(widget.documentUlid)) {
        setState(() => error = 'Document identifier is not valid.');
        return;
      }
      if (!validPositiveDecimal(amount.text.trim(), 4)) {
        setState(() => error = 'Enter an amount greater than zero (max 4 decimals).');
        return;
      }
      if (widget.kind == MoneyActionKind.expense &&
          (!validPublicUlid(field(expenseAccount?['ulid'])) ||
           !validPublicUlid(field(paymentAccount?['ulid'])))) {
        setState(() => error = 'Choose an expense and payment account.');
        return;
      }
      if (widget.kind == MoneyActionKind.salePayment && method != 'cash' &&
          (!validPublicUlid(field(paymentAccount?['ulid'])) ||
            paymentAccount?['is_bank'] != true)) {
        setState(() => error = 'Choose a receiving bank account.');
        return;
      }
      final accepted = await confirmMutation(context,
        title: '${widget.kind.title}?',
        warning: 'BluePOS will post a financial transaction and recompute '
          'the available balance on the server. A successful posting cannot '
          'be edited from this screen.',
        actionLabel: 'Confirm',
      );
      if (!accepted || !mounted) return;
      final body = <String, dynamic>{
        'amount': amount.text.trim(),
        if (widget.kind != MoneyActionKind.expense) 'method': method,
        if (reference.text.trim().isNotEmpty)
          'reference': reference.text.trim(),
        if (widget.kind == MoneyActionKind.salePayment &&
            method != 'cash')
          'account_ulid': field(paymentAccount?['ulid']),
        if (widget.kind == MoneyActionKind.expense) ...{
          'expense_date': isoLocalDate(expenseDate),
          'expense_account_ulid': field(expenseAccount?['ulid']),
          'payment_account_ulid': field(paymentAccount?['ulid']),
          'description': description.text.trim(),
        },
      };
      activePending = {
        'endpoint': widget.kind.endpoint(widget.documentUlid),
        'body': body,
      };
      key = AppController.newIdempotencyKey();
      try {
        await store.write(
          userUlid: widget.app.currentUserUlid,
          tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
          branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
          attemptKey: key!, payload: activePending!,
        );
        unconfirmed = true;
      } catch (_) {
        activePending = null;
        key = null;
        if (mounted) { setState(() =>
          error = 'Cannot securely save the request. No money was sent.'); }
        return;
      }
    }
    final request = activePending;
    final uri = field(request?['endpoint']);
    final body = objectOf(request?['body']);
    if (!uri.startsWith('/api/') || key == null || key!.isEmpty) {
      setState(() => error =
        'Pending request is invalid. Do not resubmit until reconciled.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      final result = resourceOf(await widget.app.api.post(
        uri, body, idempotencyKey: key,
      ));
      if (!validPublicUlid(field(result['ulid']))) {
        throw const ApiFailure('UNCONFIRMED_PAYMENT',
          'Server confirmation was incomplete.', 502);
      }
      await store.clear();
      if (!mounted) return;
      await showDialog<void>(context: context,
        barrierDismissible: false,
        builder: (dialog) => AlertDialog(
          title: const Text('Transaction confirmed'),
          content: Text('Server amount: ${money(result['amount'], widget.app.currency)}'),
          actions: [FilledButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Done'))],
        ));
      if (mounted) Navigator.pop(context, true);
    } on ApiFailure catch (ex) {
      if (!mounted) return;
      if (ex.status == 422 || ex.status == 403) {
        // Server explicitly rejects this request; no successful post.
        await store.clear();
        unconfirmed = false;
        activePending = null;
        key = null;
      }
      if (mounted) { setState(() => error = unconfirmed
        ? 'Financial request still unconfirmed. Retry the same saved request.'
        : ex.message); }
    } catch (_) {
      if (mounted) { setState(() => error =
        'Financial request unconfirmed. Retry only the saved request.'); }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget expenseReference(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    final inputStyle = InputDecoration(
      isDense: true,
      filled: true,
      fillColor: style.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 9, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: style.line)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: style.line)),
    );
    Widget picker(String text, VoidCallback? onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: const BoxConstraints(minHeight: 31),
        padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: style.line)),
        child: Row(children: [
          Expanded(child: Text(text,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.7,
              color: text.startsWith('Select')
                ? style.muted : style.ink))),
          Icon(Icons.chevron_right_rounded,
            color: style.muted, size: 16),
        ]),
      ),
    );
    Widget input(TextEditingController controller, String hint,
        {int lines = 1, bool numeric = false}) => TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
      style: TextStyle(fontSize: 11, color: style.ink),
      decoration: inputStyle.copyWith(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 10,
          color: style.muted)),
    );

    return Scaffold(
      backgroundColor: style.page,
      appBar: const BpReferenceSubpageAppBar(
        title: 'Create Expense Voucher', titleBelowBack: true),
      bottomNavigationBar: BpReferenceWorkflowActions(
        leftLabel: 'Cancel',
        rightLabel: unconfirmed ? 'Retry Saved Request'
          : 'Confirm Expense',
        leftIcon: Icons.close_rounded,
        rightIcon: Icons.check_circle_outline_rounded,
        leftKey: const ValueKey('expense-cancel'),
        rightKey: const ValueKey('expense-post'),
        rightColor: style.scheme.primary,
        onLeft: busy || unconfirmed ? null
          : () => Navigator.pop(context),
        onRight: busy || loading ||
          !widget.app.hasPermission('expenses.create')
            ? null : save,
      ),
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        ListView(
          key: const ValueKey('expense-reference-entry'),
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 95),
          children: [
            if (loading) pageLoading()
            else if (unconfirmed)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: style.card(radius: 13),
                child: const Text(
                  'Expense request unconfirmed. Retry only the '
                  'original saved payload and idempotency key.'))
            else ...[
              BpReferenceInlinePanel(children: [
                BpReferenceInlineRow(
                  label: 'Expense Account',
                  requiredField: true,
                  icon: Icons.sell_outlined,
                  iconColor: const Color(0xFFF59B23),
                  child: picker(
                    field(expenseAccount?['name'],
                      'Select expense account'),
                    () => chooseAccount(expense: true))),
                BpReferenceInlineRow(
                  label: 'Date',
                  requiredField: true,
                  icon: Icons.calendar_month_outlined,
                  iconColor: const Color(0xFFEE9141),
                  child: picker(isoLocalDate(expenseDate), chooseDate)),
                BpReferenceInlineRow(
                  label: 'Paid From Account',
                  requiredField: true,
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFF11B657),
                  child: picker(
                    field(paymentAccount?['name'],
                      'Select payment account'),
                    () => chooseAccount(expense: false))),
                BpReferenceInlineRow(
                  label: 'Amount',
                  requiredField: true,
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF078FE6),
                  child: input(amount, '0.0000', numeric: true)),
                BpReferenceInlineRow(
                  label: 'Reference No.',
                  icon: Icons.tag_outlined,
                  iconColor: const Color(0xFF9561EA),
                  child: input(reference, 'Optional reference')),
                BpReferenceInlineRow(
                  label: 'Description',
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF0EBC62),
                  minHeight: 49,
                  child: input(description, 'Expense details', lines: 2)),
              ]),
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: amount,
                builder: (context, inputValue, _) {
                  final preview = inputValue.text.trim();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 13),
                    decoration: BoxDecoration(
                      color: style.dark
                        ? const Color(0xFF1B472F)
                        : const Color(0xFFDCF9E3),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: style.green.withValues(alpha: .2))),
                    child: Row(children: [
                      Icon(Icons.account_balance_wallet_outlined,
                        color: style.green),
                      const SizedBox(width: 9),
                      Expanded(child: Text('Amount to Post',
                        style: TextStyle(fontWeight: FontWeight.w900,
                          color: style.ink, fontSize: 12))),
                      Text(preview.isEmpty ? '—'
                        : '${widget.app.currency} $preview',
                        style: TextStyle(fontWeight: FontWeight.w900,
                          fontSize: 15, color: style.green)),
                    ]),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Confirm Expense posts immediately after server '
                  'validation. No draft or separate post API exists.',
                  style: TextStyle(fontSize: 10, color: style.muted))),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: TextStyle(
                  color: style.scheme.error, fontSize: 11))),
          ],
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kind == MoneyActionKind.expense) {
      return expenseReference(context);
    }
    final palette = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.kind.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionHeading(widget.kind.title),
        if (widget.documentUlid.isNotEmpty)
          Text('Document: ${widget.documentUlid}',
            style: TextStyle(fontSize: 11, color: palette.onSurfaceVariant)),
        const SizedBox(height: 10),
        if (loading) pageLoading()
        else if (unconfirmed) ...[
          Surface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unconfirmed financial transaction',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Endpoint: ${field(activePending?['endpoint'])}'),
              Text('Amount: ${field(
                objectOf(activePending?['body'])['amount'])}'),
              const Text('Review the previous request before retrying. '
                'Its original amount and idempotency key will be reused.'),
            ],
          )),
        ] else ...[
          TextField(controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount *', prefixIcon: Icon(Icons.payments_outlined))),
          const SizedBox(height: 10),
          if (widget.kind != MoneyActionKind.expense)
            DropdownButtonFormField<String>(
              initialValue: method,
              decoration: const InputDecoration(labelText: 'Method'),
              items: [
                for (final item in [
                  'cash', 'card', 'bank',
                  if (widget.kind == MoneyActionKind.saleRefund) 'credit',
                ]) DropdownMenuItem(value: item,
                  child: Text(item.toUpperCase())),
              ],
              onChanged: (v) {
                if (v != null) { setState(() {
                  method = v; paymentAccount = null;
                }); }
              },
            ),
          if (widget.kind == MoneyActionKind.salePayment &&
              method != 'cash')
            Padding(padding: const EdgeInsets.only(top: 9),
              child: Surface(child: ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: Text(field(paymentAccount?['name'],
                  'Choose receiving bank account')),
                subtitle: Text(field(paymentAccount?['code'])),
                onTap: () => chooseAccount(expense: false),
              ))),
          if (widget.kind == MoneyActionKind.expense) ...[
            OutlinedButton.icon(onPressed: chooseDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Expense Date: ${isoLocalDate(expenseDate)}')),
            Surface(child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(field(expenseAccount?['name'], 'Expense account')),
              onTap: () => chooseAccount(expense: true),
            )),
            const SizedBox(height: 9),
            Surface(child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(field(paymentAccount?['name'], 'Payment account')),
              onTap: () => chooseAccount(expense: false),
            )),
            const SizedBox(height: 9),
            TextField(controller: description, maxLength: 500,
              decoration: const InputDecoration(labelText: 'Description')),
          ],
          TextField(controller: reference, maxLength: 100,
            decoration: const InputDecoration(labelText: 'Reference (optional)')),
        ],
        if (error != null) Padding(padding: const EdgeInsets.only(top: 10),
          child: Text(error!, style: TextStyle(color: palette.error))),
        const SizedBox(height: 13),
        if (!loading)
          FilledButton.icon(
            onPressed: busy ? null : save,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(busy ? 'Saving…' :
              unconfirmed ? 'Retry Original Request' : 'Confirm & Save')),
        const SizedBox(height: 36),
      ]),
    );
  }
}

/// Expense history has no detail/show endpoint: list rows are complete server
/// resources and open a read-only detail sheet instead of inventing a route.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.app});
  final AppController app;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = const [];
  bool loading = true, moreLoading = false;
  int page = 1, total = 0, serial = 0;
  String? error;
  DateTimeRange? period;

  @override
  void initState() { super.initState(); load(); }

  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> choosePeriod() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context, firstDate: DateTime(2020),
      lastDate: today.add(const Duration(days: 2)),
      initialDateRange: period ?? DateTimeRange(
        start: today.subtract(const Duration(days: 30)),
        end: today),
    );
    if (picked != null && mounted) {
      setState(() => period = picked);
      await load();
    }
  }

  Future<void> load({bool more = false}) async {
    if (more && (loading || moreLoading || rows.length >= total)) return;
    final request = more ? serial : ++serial;
    setState(() {
      if (more) { moreLoading = true; }
      else { loading = true; error = null; }
    });
    try {
      final target = more ? page + 1 : 1;
      final params = <String, String>{
        'per_page': '40', 'page': '$target',
        if (search.text.trim().isNotEmpty) 'q': search.text.trim(),
        if (period != null) ...{
          'date_from': isoLocalDate(period!.start),
          'date_to': isoLocalDate(period!.end),
        },
      };
      final url = Uri(path: '/api/sales/expenses',
        queryParameters: params).toString();
      final response = objectOf(await widget.app.api.get(url));
      if (!mounted || request != serial) return;
      final incoming = recordsOf(response);
      setState(() {
        rows = more ? [...rows, ...incoming] : incoming;
        page = target;
        total = int.tryParse(field(objectOf(response['meta'])['total']))
          ?? rows.length;
      });
    } catch (ex) {
      if (mounted && request == serial) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && request == serial) {
        setState(() { loading = false; moreLoading = false; });
      }
    }
  }

  void showExpense(Map<String, dynamic> row) {
    final style = BpReferenceStyle.of(context);
    showModalBottomSheet<void>(context: context,
      showDragHandle: true, useSafeArea: true,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(15, 5, 15, 22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Recorded Expense',
            style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.w900, color: style.ink)),
          BpReferenceDetailLine(label: 'Date',
            icon: Icons.calendar_month_outlined,
            value: field(row['expense_date'])),
          BpReferenceDetailLine(label: 'Expense account',
            icon: Icons.account_balance_outlined,
            value: field(objectOf(row['expense_account'])['name'])),
          BpReferenceDetailLine(label: 'Paid from',
            icon: Icons.account_balance_wallet_outlined,
            value: field(objectOf(row['payment_account'])['name'])),
          BpReferenceDetailLine(label: 'Amount',
            icon: Icons.payments_outlined,
            value: money(row['amount'], widget.app.currency)),
          if (field(row['reference']).isNotEmpty)
            BpReferenceDetailLine(label: 'Reference',
              icon: Icons.tag_outlined, value: field(row['reference'])),
          if (field(row['description']).isNotEmpty)
            BpReferenceDetailLine(label: 'Description',
              icon: Icons.notes_outlined, value: field(row['description'])),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Scaffold(
      backgroundColor: style.page,
      appBar: const BpReferenceSubpageAppBar(title: 'Expense Vouchers'),
      floatingActionButton: widget.app.hasPermission('expenses.create')
        ? FloatingActionButton.extended(
            key: const ValueKey('expense-create'),
            backgroundColor: const Color(0xFF08B951),
            foregroundColor: Colors.white,
            onPressed: () async {
              final result = await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) => MoneyActionScreen(
                  app: widget.app, kind: MoneyActionKind.expense)));
              if (result == true && mounted) await load();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Expense'))
        : null,
      body: Stack(children: [
        RefreshIndicator(onRefresh: () => load(),
          child: ListView(
            key: const ValueKey('expense-vouchers-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
            children: [
              Row(children: [
                Expanded(child: TextField(
                  key: const ValueKey('expense-search'),
                  controller: search,
                  onSubmitted: (_) => load(),
                  decoration: style.search(
                    'Search expense head, reference, description...',
                    prefixIcon: const Icon(Icons.search_rounded)))),
                const SizedBox(width: 7),
                IconButton(
                  key: const ValueKey('expense-filter'),
                  tooltip: 'Filter by date (server)',
                  onPressed: choosePeriod,
                  icon: const Icon(Icons.date_range_outlined)),
                IconButton(onPressed: loading ? null : () => load(),
                  tooltip: 'Search / Refresh',
                  icon: const Icon(Icons.search_rounded)),
              ]),
              if (period != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() => period = null);
                    load();
                  },
                  icon: const Icon(Icons.close_rounded, size: 15),
                  label: Text('${isoLocalDate(period!.start)} – '
                    '${isoLocalDate(period!.end)}')),
              const SizedBox(height: 10),
              if (loading) pageLoading()
              else if (error != null)
                FailureState(message: error!, retry: () => load())
              else if (rows.isEmpty)
                const EmptyState(title: 'No recorded expenses',
                  subtitle: 'No matching expenses returned by BluePOS.')
              else for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: InkWell(
                    onTap: () => showExpense(row),
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: style.card(radius: 13),
                      child: Row(children: [
                        Container(width: 41, height: 42,
                          decoration: BoxDecoration(
                            color: style.scheme.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.receipt_long_outlined,
                            color: style.scheme.primary)),
                        const SizedBox(width: 8),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field(objectOf(row['expense_account'])['name'],
                              'Expense'),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w900,
                                fontSize: 11, color: style.ink)),
                            if (field(row['reference']).isNotEmpty)
                              Text(field(row['reference']),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10,
                                  color: style.muted)),
                            Text(field(row['expense_date']),
                              style: TextStyle(fontSize: 10,
                                color: style.muted)),
                          ])),
                        const SizedBox(width: 6),
                        Column(crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Recorded', style: TextStyle(
                              color: style.green, fontSize: 10,
                              fontWeight: FontWeight.w800)),
                            Text(money(row['amount'], widget.app.currency),
                              style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: style.ink)),
                          ]),
                        const Icon(Icons.chevron_right_rounded, size: 18),
                      ]),
                    ),
                  ),
                ),
              if (!loading && rows.length < total)
                OutlinedButton(
                  onPressed: moreLoading ? null : () => load(more: true),
                  child: Text(moreLoading
                    ? 'Loading...' : 'Load more ($total total)')),
            ],
          ),
        ),
        const Positioned(bottom: 0, left: 0, right: 0,
          child: IgnorePointer(child: BpReferenceFooterWave())),
      ]),
    );
  }
}
