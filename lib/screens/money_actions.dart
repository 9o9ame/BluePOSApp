import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/sale_attempt.dart';
import '../core/session.dart';
import '../widgets/common.dart';
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
      if (mounted) setState(() =>
        error = 'Unable to load secure pending financial request.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseAccount({required bool expense}) async {
    final account = await pickApiRecord(
      context: context, app: widget.app,
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
      if (expense) expenseAccount = account;
      else paymentAccount = account;
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
        if (mounted) setState(() =>
          error = 'Cannot securely save the request. No money was sent.');
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
      if (mounted) setState(() => error = unconfirmed
        ? 'Financial request still unconfirmed. Retry the same saved request.'
        : ex.message);
    } catch (_) {
      if (mounted) setState(() => error =
        'Financial request unconfirmed. Retry only the saved request.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                if (v != null) setState(() {
                  method = v; paymentAccount = null;
                });
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
  List<Map<String, dynamic>> rows = const [];
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await widget.app.api.get('/api/sales/expenses?per_page=100');
      if (mounted) setState(() => rows = recordsOf(response));
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses'),
        actions: [IconButton(onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh_rounded))]),
      floatingActionButton: widget.app.hasPermission('expenses.create')
        ? FloatingActionButton.extended(
          onPressed: () async {
            final saved = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) =>
                MoneyActionScreen(app: widget.app, kind: MoneyActionKind.expense)));
            if (saved == true && mounted) await load();
          },
          icon: const Icon(Icons.add_rounded), label: const Text('New Expense'))
        : null,
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Recorded expenses'),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else if (rows.isEmpty) const EmptyState(title: 'No expenses')
          else for (final row in rows) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(padding: const EdgeInsets.all(13),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(field(objectOf(row['expense_account'])['name'], 'Expense'),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(field(row['expense_date']),
                  style: TextStyle(color: palette.onSurfaceVariant, fontSize: 11)),
                Text(field(row['description'])),
                Text('Paid from: ${field(
                  objectOf(row['payment_account'])['name'])}'),
                Text(money(row['amount'], widget.app.currency),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              ]))),
          const SizedBox(height: 80),
        ])),
    );
  }
}
