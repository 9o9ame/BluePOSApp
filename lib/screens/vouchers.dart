import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/sale_attempt.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';

enum VoucherKind { payment, receiving, journal, opening }

extension VoucherSpec on VoucherKind {
  String get label => switch (this) {
    VoucherKind.payment => 'Payment Voucher',
    VoucherKind.receiving => 'Receiving Voucher',
    VoucherKind.journal => 'Journal Voucher',
    VoucherKind.opening => 'Opening Balance Voucher',
  };
  String get apiName => name;
  IconData get icon => switch (this) {
    VoucherKind.payment => Icons.call_made_rounded,
    VoucherKind.receiving => Icons.call_received_rounded,
    VoucherKind.journal => Icons.menu_book_outlined,
    VoucherKind.opening => Icons.account_balance_outlined,
  };
  bool get hasHeader => this == VoucherKind.payment ||
    this == VoucherKind.receiving;
}

class VoucherRowDraft {
  VoucherRowDraft({
    required this.account,
    this.amount = '0',
    this.debit = '0',
    this.credit = '0',
    this.narration = '',
  });
  final Map<String, dynamic> account;
  String amount, debit, credit, narration;

  Map<String, dynamic> payload(VoucherKind kind) => {
    'account_ulid': field(account['ulid']),
    'narration': narration,
    if (kind.hasHeader) 'amount': amount,
    if (!kind.hasHeader) ...{'debit': debit, 'credit': credit},
  };
}

class VoucherDirectoryScreen extends StatelessWidget {
  const VoucherDirectoryScreen({super.key, required this.app});
  final AppController app;
  @override
  Widget build(BuildContext context) => TransactionDirectory(
    app: app, title: 'Accounting Vouchers',
    endpoint: '/api/vouchers',
    numberKey: 'voucher_number', dateKey: 'entry_date',
    amountKey: 'total_debit', createPermission: 'vouchers.create',
    onCreate: (ctx) async => await Navigator.push<bool>(ctx,
      MaterialPageRoute(builder: (_) =>
        VoucherEditor(app: app))) ?? false,
    onOpen: (ctx, row) async {
      final ulid = field(row['ulid']);
      if (!validPublicUlid(ulid)) return false;
      return await Navigator.push<bool>(ctx,
        MaterialPageRoute(builder: (_) =>
          VoucherEditor(app: app, voucherUlid: ulid))) ?? false;
    },
  );
}

/// Payment/receiving cash header, general journal and opening entries use the
/// same authoritative ManageVoucherAction on the existing Laravel backend.
class VoucherEditor extends StatefulWidget {
  const VoucherEditor({
    super.key, required this.app, this.voucherUlid,
  });
  final AppController app;
  final String? voucherUlid;
  @override
  State<VoucherEditor> createState() => _VoucherEditorState();
}

class _VoucherEditorState extends State<VoucherEditor> {
  final description = TextEditingController();
  final book = TextEditingController();
  final rows = <VoucherRowDraft>[];
  final pending = const VoucherAttemptStore();
  DateTime entryDate = DateTime.now();
  VoucherKind kind = VoucherKind.payment;
  Map<String, dynamic>? headerAccount, voucher;
  Map<String, dynamic>? unconfirmedPayload;
  String? unconfirmedKey, error;
  bool saving = false, loading = false, pendingAttempt = false;

  bool get created => validPublicUlid(field(voucher?['ulid']));
  String get id => field(voucher?['ulid']);
  bool get draft => field(voucher?['status'], 'draft') == 'draft';
  bool get canEdit => widget.app.hasPermission('vouchers.create');
  bool get canPost => widget.app.hasPermission('vouchers.approve');

  @override
  void initState() {
    super.initState();
    if (widget.voucherUlid != null) {
      refresh();
    } else {
      restorePending();
    }
  }

  @override
  void dispose() {
    description.dispose();
    book.dispose();
    super.dispose();
  }

  Future<void> restorePending() async {
    final data = await pending.read(
      userUlid: widget.app.currentUserUlid,
      tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
      branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
    );
    if (data == null || !mounted) return;
    setState(() {
      pendingAttempt = true;
      unconfirmedPayload = objectOf(data['payload']);
      unconfirmedKey = field(data['key']);
      error = 'An earlier voucher save is unconfirmed. Retry it using the same request.';
    });
  }

  Future<void> refresh() async {
    final target = widget.voucherUlid ?? id;
    if (!validPublicUlid(target)) return;
    setState(() { loading = true; error = null; });
    try {
      final data = resourceOf(await widget.app.api.get('/api/vouchers/$target'));
      if (!mounted) return;
      final type = field(data['type']);
      setState(() {
        voucher = data;
        kind = VoucherKind.values.firstWhere(
          (k) => k.name == type, orElse: () => VoucherKind.journal);
        description.text = field(data['description']);
        book.text = field(data['book_number']);
        entryDate = DateTime.tryParse(field(data['entry_date']))
          ?? DateTime.now();
        headerAccount = objectOf(data['header_account']);
        rows.clear();
        for (final line in recordsOf(data['lines'])) {
          if (line['is_header'] == true) continue;
          final acct = objectOf(line['account']);
          if (!validPublicUlid(field(acct['ulid']))) continue;
          rows.add(VoucherRowDraft(
            account: acct,
            amount: kind.hasHeader
              ? field(line[kind == VoucherKind.payment ? 'debit' : 'credit'], '0')
              : '0',
            debit: field(line['debit'], '0'),
            credit: field(line['credit'], '0'),
            narration: field(line['narration']),
          ));
        }
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseDate() async {
    final chosen = await showDatePicker(
      context: context, firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
      initialDate: entryDate);
    if (chosen != null && mounted) setState(() => entryDate = chosen);
  }

  Future<void> chooseHeader() async {
    final selected = await pickApiRecord(context,
      app: widget.app, title: 'Cash or bank account',
      path: '/api/vouchers/accounts?cash_only=1&as_of=${isoLocalDate(entryDate)}');
    if (selected != null && mounted) setState(() => headerAccount = selected);
  }

  Future<void> addLine([VoucherRowDraft? original]) async {
    if (!canEdit || created && !draft || pendingAttempt || saving) return;
    Map<String, dynamic> account = original?.account ?? {};
    final amount = TextEditingController(text: original?.amount ?? '0');
    final debit = TextEditingController(text: original?.debit ?? '0');
    final credit = TextEditingController(text: original?.credit ?? '0');
    final narration = TextEditingController(text: original?.narration ?? '');
    String? formError;
    try {
      final accepted = await showModalBottomSheet<bool>(context: context,
        useSafeArea: true, showDragHandle: true, isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, update) => Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16,
              MediaQuery.viewInsetsOf(ctx).bottom + 15),
            child: ListView(shrinkWrap: true, children: [
              Text(original == null ? 'Add voucher line' : 'Edit voucher line',
                style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 11),
              ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: Text(field(account['name'], 'Select account')),
                subtitle: Text(field(account['code'])),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final chosen = await pickApiRecord(ctx,
                    app: widget.app, title: 'Voucher account',
                    path: '/api/vouchers/accounts?as_of=${isoLocalDate(entryDate)}');
                  if (chosen != null && ctx.mounted) {
                    update(() => account = chosen);
                  }
                }),
              if (kind.hasHeader) TextField(controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount *'))
              else ...[
                TextField(controller: debit,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Debit')),
                const SizedBox(height: 8),
                TextField(controller: credit,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Credit')),
              ],
              const SizedBox(height: 9),
              TextField(controller: narration,
                maxLength: 500, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Narration')),
              if (formError != null) Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(formError!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: () {
                if (!validPublicUlid(field(account['ulid'])) ||
                    (kind.hasHeader
                      ? !validPositiveDecimal(amount.text.trim(), 4)
                      : !validNonNegativeDecimal(debit.text.trim(), 4) ||
                        !validNonNegativeDecimal(credit.text.trim(), 4) ||
                        (debit.text.trim() == '0' && credit.text.trim() == '0') ||
                        (debit.text.trim() != '0' && credit.text.trim() != '0')) ||
                    (kind.hasHeader &&
                      field(account['ulid']) == field(headerAccount?['ulid']))) {
                  update(() => formError =
                    'Select distinct accounts and a positive amount on one side.');
                  return;
                }
                Navigator.pop(ctx, true);
              }, icon: const Icon(Icons.save_outlined),
                label: const Text('Save line')),
            ]),
          ),
        ));
      if (accepted == true && mounted) setState(() {
        final replacement = VoucherRowDraft(
          account: account,
          amount: amount.text.trim(),
          debit: debit.text.trim(),
          credit: credit.text.trim(),
          narration: narration.text.trim(),
        );
        if (original == null) rows.add(replacement);
        else rows[rows.indexOf(original)] = replacement;
      });
    } finally {
      amount.dispose(); debit.dispose(); credit.dispose(); narration.dispose();
    }
  }

  Map<String, dynamic> get payload => {
    if (!created) 'type': kind.apiName,
    'entry_date': isoLocalDate(entryDate),
    'book_number': book.text.trim(),
    'description': description.text.trim(),
    if (kind.hasHeader) 'header_account_ulid': field(headerAccount?['ulid']),
    'lines': rows.map((row) => row.payload(kind)).toList(),
  };

  Future<void> save() async {
    if (!canEdit || saving || created && !draft) return;
    if (!pendingAttempt) {
      if (rows.isEmpty ||
          (kind == VoucherKind.journal && rows.length < 2) ||
          (kind.hasHeader && !validPublicUlid(field(headerAccount?['ulid'])))) {
        setState(() => error = 'Enter a valid cash account and voucher lines.');
        return;
      }
      if (created) {
        await updateDraft();
        return;
      }
      unconfirmedKey = AppController.newIdempotencyKey();
      unconfirmedPayload = payload;
      pendingAttempt = true;
      try {
        await pending.write(
          userUlid: widget.app.currentUserUlid,
          tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
          branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
          attemptKey: unconfirmedKey!, payload: unconfirmedPayload!,
        );
      } catch (_) {
        pendingAttempt = false;
        unconfirmedKey = null;
        unconfirmedPayload = null;
        if (mounted) setState(() => error =
          'Cannot securely store voucher request. Nothing was sent.');
        return;
      }
    }
    setState(() { saving = true; error = null; });
    try {
      final reply = resourceOf(await widget.app.api.post(
        '/api/vouchers', unconfirmedPayload!,
        idempotencyKey: unconfirmedKey));
      if (!validPublicUlid(field(reply['ulid']))) {
        throw const ApiFailure('UNCONFIRMED_VOUCHER',
          'Server voucher confirmation missing.', 502);
      }
      await pending.clear();
      if (!mounted) return;
      setState(() {
        voucher = reply;
        pendingAttempt = false;
        unconfirmedPayload = null;
        unconfirmedKey = null;
      });
      await refresh();
    } on ApiFailure catch (ex) {
      if (!mounted) return;
      if (ex.status == 422 || ex.status == 403) {
        await pending.clear();
        pendingAttempt = false;
        unconfirmedKey = null;
        unconfirmedPayload = null;
      }
      if (mounted) setState(() => error = pendingAttempt
        ? 'Voucher save is unconfirmed. Retry this saved request safely.'
        : ex.message);
    } catch (_) {
      if (mounted) setState(() => error =
        'Voucher save is unconfirmed. Retry this saved request safely.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> updateDraft() async {
    if (!created || !draft || !canEdit || saving) return;
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.request('PUT', '/api/vouchers/$id',
        body: payload);
      await refresh();
    } catch (ex) {
      if (mounted) setState(() => error =
        'Draft update unconfirmed. Refresh this voucher before editing again. $ex');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> post() async {
    if (!created || !draft || !canPost || saving) return;
    if (!await confirmMutation(context,
      title: 'Post ${kind.label}?',
      warning: 'BluePOS verifies account entries and posts an immutable '
        'journal document. Posted vouchers cannot be edited.',
      actionLabel: 'Post Voucher')) return;
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.post('/api/vouchers/$id/post', {});
      await refresh();
    } catch (ex) {
      if (mounted) {
        await refresh();
        if (mounted) setState(() => error =
          'Posting status uncertain. Check the voucher status before retrying. $ex');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deleteDraft() async {
    if (!created || !draft || !canEdit || saving) return;
    if (!await confirmMutation(context,
      title: 'Delete unposted voucher?',
      warning: 'This deletes the draft and its journal lines. '
        'Posted accounting entries cannot be deleted.',
      actionLabel: 'Delete Draft')) return;
    setState(() => saving = true);
    try {
      await widget.app.api.request('DELETE', '/api/vouchers/$id');
      if (mounted) Navigator.pop(context, true);
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final editable = !saving && !pendingAttempt &&
      (!created || draft && canEdit);
    return Scaffold(
      appBar: AppBar(title: Text(created
        ? field(voucher?['voucher_number'], kind.label) : 'New Voucher'),
        actions: [if (created) IconButton(
          onPressed: saving || loading ? null : refresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh')]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionHeading('Manual accounting voucher'),
        if (loading) pageLoading()
        else ...[
          if (!created && !pendingAttempt)
            DropdownButtonFormField<VoucherKind>(
              initialValue: kind,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Voucher Type'),
              items: VoucherKind.values.map((v) => DropdownMenuItem(
                value: v,
                child: Row(children: [
                  Icon(v.icon, size: 18), const SizedBox(width: 9),
                  Text(v.label),
                ]))).toList(),
              onChanged: editable ? (v) {
                if (v == null) return;
                setState(() {
                  kind = v;
                  rows.clear();
                  headerAccount = null;
                });
              } : null),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: editable ? chooseDate : null,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(isoLocalDate(entryDate))),
          const SizedBox(height: 9),
          TextField(controller: book, maxLength: 50, readOnly: !editable,
            decoration: const InputDecoration(labelText: 'Book number')),
          TextField(controller: description, maxLength: 500, readOnly: !editable,
            decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          if (kind.hasHeader) Surface(child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(field(headerAccount?['name'],
              'Choose cash or bank account')),
            subtitle: Text(field(headerAccount?['code'])),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: editable ? chooseHeader : null)),
          Row(children: [
            Expanded(child: SectionHeading('Voucher lines (${rows.length})')),
            if (editable && canEdit)
              IconButton(onPressed: () => addLine(),
                icon: Icon(Icons.add_circle_outline_rounded,
                  color: colors.primary), tooltip: 'Add account line'),
          ]),
          for (final row in rows) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(field(row.account['name']),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(kind.hasHeader
                    ? 'Amount: ${money(row.amount, widget.app.currency)}'
                    : 'Debit: ${money(row.debit, widget.app.currency)} · '
                      'Credit: ${money(row.credit, widget.app.currency)}',
                    style: TextStyle(fontSize: 11,
                      color: colors.onSurfaceVariant)),
                  if (row.narration.isNotEmpty)
                    Text(row.narration, style: const TextStyle(fontSize: 11)),
                ])),
                if (editable && canEdit) IconButton(
                  onPressed: () => addLine(row),
                  icon: const Icon(Icons.edit_outlined), tooltip: 'Edit line'),
                if (editable && canEdit) IconButton(
                  onPressed: () => setState(() => rows.remove(row)),
                  icon: Icon(Icons.close_rounded, color: colors.error),
                  tooltip: 'Remove line'),
              ]))),
          if (created) Surface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Server Debit: ${money(voucher?['total_debit'], widget.app.currency)}'),
              Text('Server Credit: ${money(voucher?['total_credit'], widget.app.currency)}'),
              Text('Status: ${field(voucher?['status'])}'),
            ])),
          if (pendingAttempt) const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('Unconfirmed voucher attempt. Only the original payload can be retried.')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 10),
            child: Text(error!, style: TextStyle(color: colors.error))),
          const SizedBox(height: 12),
          if (canEdit && (!created || draft))
            FilledButton.icon(onPressed: saving ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: Text(saving ? 'Saving…' :
                pendingAttempt ? 'Retry Saved Voucher' :
                created ? 'Save Draft Changes' : 'Create Voucher Draft')),
          if (created && draft && canPost) Padding(
            padding: const EdgeInsets.only(top: 9),
            child: FilledButton.icon(onPressed: saving ? null : post,
              icon: const Icon(Icons.verified_rounded),
              label: Text('Post ${kind.label}'))),
          if (created && draft && canEdit)
            Padding(padding: const EdgeInsets.only(top: 9),
              child: OutlinedButton.icon(
                onPressed: saving ? null : deleteDraft,
                icon: Icon(Icons.delete_outline, color: colors.error),
                label: const Text('Delete Draft'))),
        ],
        const SizedBox(height: 35),
      ]),
    );
  }
}
