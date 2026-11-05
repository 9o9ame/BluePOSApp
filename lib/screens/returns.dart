import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/sale_attempt.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';
import 'money_actions.dart';

enum ReturnDocumentKind { sale, purchase }

extension ReturnSpec on ReturnDocumentKind {
  String get title => this == ReturnDocumentKind.sale
    ? 'Sales Returns' : 'Purchase Returns';
  String get path => this == ReturnDocumentKind.sale
    ? '/api/sales-returns' : '/api/purchase-returns';
  String get sourcePath => this == ReturnDocumentKind.sale
    ? '/api/sales' : '/api/purchases';
  String get sourceKey => this == ReturnDocumentKind.sale
    ? 'sale_ulid' : 'purchase_ulid';
  String get lineKey => this == ReturnDocumentKind.sale
    ? 'sale_item_ulid' : 'purchase_line_ulid';
  String get sourceField => this == ReturnDocumentKind.sale
    ? 'original_sale' : 'original_purchase';
  String get viewPermission => this == ReturnDocumentKind.sale
    ? 'sales.return' : 'purchase_returns.view';
  String get createPermission => this == ReturnDocumentKind.sale
    ? 'sales.return' : 'purchase_returns.create';
  String get editPermission => this == ReturnDocumentKind.sale
    ? 'sales.return' : 'purchase_returns.edit';
  String get postPermission => this == ReturnDocumentKind.sale
    ? 'sales.return' : 'purchase_returns.post';
}

class ReturnDocumentsScreen extends StatelessWidget {
  const ReturnDocumentsScreen({
    super.key, required this.app, required this.kind,
  });
  final AppController app;
  final ReturnDocumentKind kind;

  @override
  Widget build(BuildContext context) => TransactionDirectory(
    app: app, title: kind.title, endpoint: kind.path,
    dateKey: 'return_date', createPermission: kind.createPermission,
    onCreate: (ctx) async => await Navigator.push<bool>(ctx,
      MaterialPageRoute(builder: (_) =>
        ReturnDocumentEditor(app: app, kind: kind))) ?? false,
    onOpen: (ctx, row) async {
      final ulid = field(row['ulid']);
      if (!validPublicUlid(ulid)) return false;
      return await Navigator.push<bool>(ctx,
        MaterialPageRoute(builder: (_) =>
          ReturnDocumentEditor(app: app, kind: kind,
            documentUlid: ulid))) ?? false;
    },
  );
}

class ReturnDocumentEditor extends StatefulWidget {
  const ReturnDocumentEditor({
    super.key, required this.app, required this.kind, this.documentUlid,
  });
  final AppController app;
  final ReturnDocumentKind kind;
  final String? documentUlid;
  @override
  State<ReturnDocumentEditor> createState() => _ReturnDocumentEditorState();
}

class _ReturnDocumentEditorState extends State<ReturnDocumentEditor> {
  final reason = TextEditingController();
  final notes = TextEditingController();
  final pending = const SaleReturnAttemptStore();
  DateTime date = DateTime.now();
  Map<String, dynamic>? source, document;
  List<Map<String, dynamic>> available = const [];
  bool loading = false, saving = false, createUncertain = false;
  String? error, pendingKey;
  Map<String, dynamic>? pendingPayload;

  bool get created => validPublicUlid(field(document?['ulid']));
  String get id => field(document?['ulid']);
  String get sourceUlid => field(source?['ulid']);
  bool get draft => field(document?['status'], 'draft') == 'draft';
  bool get editable => widget.app.hasPermission(widget.kind.editPermission);
  bool get canPost => widget.app.hasPermission(widget.kind.postPermission);

  @override
  void initState() {
    super.initState();
    if (widget.documentUlid != null) {
      refresh();
    } else if (widget.kind == ReturnDocumentKind.sale) {
      restorePending();
    }
  }

  @override
  void dispose() {
    reason.dispose(); notes.dispose();
    super.dispose();
  }

  Future<void> restorePending() async {
    final request = await pending.read(
      userUlid: widget.app.currentUserUlid,
      tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
      branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
    );
    if (request == null || !mounted) return;
    setState(() {
      createUncertain = true;
      pendingKey = field(request['key']);
      pendingPayload = objectOf(request['payload']);
      error = 'Sales Return draft creation was not confirmed. '
        'Only the saved request may be retried.';
    });
  }

  Future<void> refresh() async {
    final target = widget.documentUlid ?? id;
    if (!validPublicUlid(target)) return;
    setState(() { loading = true; error = null; });
    try {
      final fetched = resourceOf(await widget.app.api.get(
        '${widget.kind.path}/$target'));
      final oldSource = objectOf(fetched[widget.kind.sourceField]);
      if (!mounted) return;
      setState(() {
        document = fetched;
        source = oldSource.isNotEmpty ? oldSource : null;
        date = DateTime.tryParse(field(fetched['return_date']))
          ?? DateTime.now();
        reason.text = field(fetched['reason']);
        notes.text = field(fetched['notes']);
      });
      if (validPublicUlid(sourceUlid)) await loadAvailable();
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseSource() async {
    if (created || createUncertain) return;
    final picked = await pickApiRecord(context, app: widget.app,
      title: 'Choose posted source document',
      path: '${widget.kind.sourcePath}?per_page=100',
      nameKey: 'document_number',
      subtitleKey: widget.kind == ReturnDocumentKind.sale
        ? 'sale_date' : 'invoice_date');
    if (picked == null || !mounted) return;
    if (field(picked['status']) != 'posted') {
      await showApiError(context,
        'Only posted invoices can be returned.');
      return;
    }
    setState(() { source = picked; available = []; error = null; });
    await loadAvailable();
  }

  Future<void> loadAvailable() async {
    if (!validPublicUlid(sourceUlid)) return;
    final path = '${widget.kind.sourcePath}/$sourceUlid/returnable-lines';
    try {
      final full = await widget.app.api.get(
        created ? '$path?exclude_return_ulid=$id' : path);
      if (mounted) setState(() => available = recordsOf(full));
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    }
  }

  Future<void> chooseDate() async {
    final picked = await showDatePicker(context: context,
      initialDate: date, firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)));
    if (picked != null && mounted) setState(() => date = picked);
  }

  Future<void> createDraft() async {
    if (created || saving ||
        !widget.app.hasPermission(widget.kind.createPermission)) return;
    if (!createUncertain) {
      if (!validPublicUlid(sourceUlid) || available.isEmpty) {
        setState(() => error =
          'Select a posted invoice with returnable lines first.');
        return;
      }
      final accepted = await confirmMutation(context,
        title: 'Create return draft?',
        warning: 'The original document is not reversed until the '
          'return is reviewed and explicitly posted.',
        actionLabel: 'Create Draft');
      if (!accepted || !mounted) return;
      pendingPayload = {
        widget.kind.sourceKey: sourceUlid,
        'return_date': isoLocalDate(date),
        'reason': reason.text.trim(),
        'notes': notes.text.trim(),
      };
      if (widget.kind == ReturnDocumentKind.purchase) {
        // Purchase Returns may accept an active warehouse, but the server
        // always enforces its own branch and warehouse authorization.
        final active = field(
          objectOf(widget.app.session?['warehouse'])['ulid']);
        if (validPublicUlid(active)) pendingPayload!['warehouse_ulid'] = active;
      }
      if (widget.kind == ReturnDocumentKind.sale) {
        pendingKey = AppController.newIdempotencyKey();
        try {
          await pending.write(
            userUlid: widget.app.currentUserUlid,
            tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
            branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
            attemptKey: pendingKey!, payload: pendingPayload!,
          );
        } catch (_) {
          if (mounted) setState(() => error =
            'Cannot securely store this return request. No request was sent.');
          return;
        }
      }
      createUncertain = true;
    }
    setState(() { saving = true; error = null; });
    try {
      final result = resourceOf(await widget.app.api.post(
        widget.kind.path, pendingPayload!,
        idempotencyKey: widget.kind == ReturnDocumentKind.sale
          ? pendingKey : null));
      if (!validPublicUlid(field(result['ulid']))) {
        throw const ApiFailure('RETURN_UNCONFIRMED',
          'Return draft not confirmed.', 502);
      }
      if (widget.kind == ReturnDocumentKind.sale) await pending.clear();
      if (!mounted) return;
      setState(() {
        document = result;
        createUncertain = false;
        pendingPayload = null;
        pendingKey = null;
      });
      await refresh();
    } on ApiFailure catch (ex) {
      if (!mounted) return;
      if (ex.status == 422 || ex.status == 403) {
        if (widget.kind == ReturnDocumentKind.sale) await pending.clear();
        createUncertain = false;
        pendingPayload = null;
        pendingKey = null;
      }
      if (mounted) setState(() => error = createUncertain
        ? widget.kind == ReturnDocumentKind.sale
          ? 'Return draft status unknown. Retry the saved request with the same idempotency key.'
          : 'Purchase Return creation status unknown. Search history before another create.'
        : ex.message);
    } catch (_) {
      if (mounted) setState(() => error =
        'Return draft status unknown. Check documents before another attempt.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveHeader() async {
    if (!created || !draft || !editable || saving) return;
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.patch('${widget.kind.path}/$id', {
        'return_date': isoLocalDate(date),
        'reason': reason.text.trim(),
        'notes': notes.text.trim(),
      });
      await refresh();
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> editLine([Map<String, dynamic>? current]) async {
    if (!created || !draft || !editable || saving ||
        !validPublicUlid(sourceUlid)) return;
    Map<String, dynamic> selection = {};
    if (current != null) {
      final sourceLine = field(current[widget.kind.lineKey]);
      for (final item in available) {
        if (field(item[widget.kind.lineKey]) == sourceLine) {
          selection = item;
          break;
        }
      }
    }
    final quantity = TextEditingController(text:
      field(current?['quantity'], '1'));
    final comment = TextEditingController(text:
      field(current?['reason']));
    var inFlight = false, ambiguous = false;
    String? formError;
    try {
      final saved = await showModalBottomSheet<bool>(context: context,
        isScrollControlled: true, useSafeArea: true, showDragHandle: true,
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, change) => Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16,
              MediaQuery.viewInsetsOf(sheet).bottom + 16),
            child: ListView(shrinkWrap: true, children: [
              Text('Return line', style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.assignment_return_outlined),
                title: Text(field(
                  objectOf(selection['product'])['name'],
                  'Choose an original invoice line')),
                subtitle: Text(field(
                  selection[widget.kind == ReturnDocumentKind.sale
                    ? 'remaining_returnable_quantity'
                    : 'remaining_returnable_base_quantity'],
                  'Remaining quantity from server')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: current != null || inFlight || ambiguous ? null :
                  () async {
                    final chosen = await showModalBottomSheet<
                      Map<String, dynamic>>(context: sheet,
                      isScrollControlled: true, useSafeArea: true,
                      showDragHandle: true,
                      builder: (selector) => FractionallySizedBox(
                        heightFactor: .7, child: ListView(
                          padding: const EdgeInsets.all(12), children: [
                          const SectionHeading('Returnable invoice lines'),
                          for (final option in available) ListTile(
                            title: Text(field(
                              objectOf(option['product'])['name'], 'Product')),
                            subtitle: Text(field(option[
                              widget.kind == ReturnDocumentKind.sale
                                ? 'remaining_returnable_quantity'
                                : 'remaining_returnable_base_quantity'], '0')),
                            onTap: () => Navigator.pop(selector, option)),
                        ])));
                    if (chosen != null && sheet.mounted) {
                      change(() => selection = chosen);
                    }
                  }),
              const SizedBox(height: 8),
              TextField(controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Return quantity *')),
              TextField(controller: comment, maxLength: 255,
                decoration: const InputDecoration(labelText: 'Reason')),
              if (formError != null) Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(formError!,
                  style: TextStyle(color: Theme.of(sheet).colorScheme.error))),
              const SizedBox(height: 11),
              FilledButton.icon(onPressed: inFlight || ambiguous ? null :
                () async {
                  final lineId = field(selection[widget.kind.lineKey]);
                  if (!validPublicUlid(lineId) ||
                      !validPositiveDecimal(quantity.text.trim(), 6)) {
                    change(() => formError =
                      'Choose a source line and a positive quantity.');
                    return;
                  }
                  change(() { inFlight = true; formError = null; });
                  try {
                    final payload = {
                      widget.kind.lineKey: lineId,
                      'quantity': quantity.text.trim(),
                      'reason': comment.text.trim(),
                    };
                    if (current == null) {
                      await widget.app.api.post(
                        '${widget.kind.path}/$id/lines', payload);
                    } else {
                      final currentId = field(current['ulid']);
                      if (!validPublicUlid(currentId)) {
                        throw const FormatException('Invalid return line.');
                      }
                      await widget.app.api.patch(
                        '${widget.kind.path}/$id/lines/$currentId', payload);
                    }
                    if (sheet.mounted) Navigator.pop(sheet, true);
                  } on ApiFailure catch (ex) {
                    if (sheet.mounted) change(() {
                      ambiguous = ex.status == 0 || ex.status >= 500;
                      formError = ambiguous
                        ? 'Line save unconfirmed. Close and refresh before retrying.'
                        : ex.message;
                    });
                  } catch (_) {
                    if (sheet.mounted) change(() {
                      ambiguous = true;
                      formError = 'Line save unconfirmed. Reload before retrying.';
                    });
                  } finally {
                    if (sheet.mounted) change(() => inFlight = false);
                  }
                }, icon: const Icon(Icons.save_outlined),
                label: Text(inFlight ? 'Saving…' : 'Save return line')),
            ]),
          ),
        ));
      if (saved == true && mounted) await refresh();
    } finally {
      quantity.dispose(); comment.dispose();
    }
  }

  Future<void> deleteLine(Map<String, dynamic> line) async {
    if (!created || !draft || !editable || saving) return;
    final lineUlid = field(line['ulid']);
    if (!validPublicUlid(lineUlid)) return;
    if (!await confirmMutation(context,
      title: 'Remove return line?',
      warning: 'Only this unposted return line will be removed.',
      actionLabel: 'Remove')) return;
    setState(() => saving = true);
    try {
      await widget.app.api.request('DELETE',
        '${widget.kind.path}/$id/lines/$lineUlid');
      await refresh();
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> post() async {
    if (!created || !draft || !canPost || saving ||
        recordsOf(document?['lines']).isEmpty) return;
    if (!await confirmMutation(context,
      title: 'Post ${widget.kind.title}?',
      warning: 'The server will validate returnable quantities and update '
        'stock using its existing append-only inventory flow.',
      actionLabel: 'Post Return')) return;
    setState(() => saving = true);
    try {
      await widget.app.api.post('${widget.kind.path}/$id/post', {});
      await refresh();
    } catch (ex) {
      if (mounted) {
        await refresh();
        if (mounted) setState(() => error =
          'Return posting status uncertain. Check current status first. $ex');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    final lines = recordsOf(document?['lines']);
    final canEditNow = !saving && !createUncertain &&
      (!created || draft && editable);
    return Scaffold(
      appBar: AppBar(title: Text(created
        ? field(document?['document_number'], widget.kind.title)
        : 'New ${widget.kind.title}'),
        actions: [if (created) IconButton(onPressed: saving || loading
          ? null : refresh, icon: const Icon(Icons.refresh_rounded))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionHeading(widget.kind.title),
        const SizedBox(height: 5),
        Text('Source-linked returns use server-authorized posted invoices.',
          style: TextStyle(color: palette.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 12),
        if (loading) pageLoading()
        else ...[
          Surface(child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(field(source?['document_number'],
                'Choose original posted invoice')),
              subtitle: Text(field(source?['status'])),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: !created && !createUncertain ? chooseSource : null),
            OutlinedButton.icon(onPressed: canEditNow ? chooseDate : null,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(isoLocalDate(date))),
            const SizedBox(height: 8),
            TextField(controller: reason,
              maxLength: 255, readOnly: !canEditNow,
              decoration: const InputDecoration(labelText: 'Reason')),
            TextField(controller: notes,
              maxLength: 5000, maxLines: 2, readOnly: !canEditNow,
              decoration: const InputDecoration(labelText: 'Notes')),
            if (!created && widget.app.hasPermission(widget.kind.createPermission))
              FilledButton.icon(
                onPressed: saving ||
                  (createUncertain && widget.kind == ReturnDocumentKind.purchase)
                    ? null : createDraft,
                icon: const Icon(Icons.note_add_outlined),
                label: Text(createUncertain ? 'Retry Saved Draft' : 'Create Draft')),
            if (created && draft && editable)
              OutlinedButton.icon(onPressed: saving ? null : saveHeader,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Header')),
          ])),
          if (created) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: SectionHeading('Return lines (${lines.length})')),
              if (canEditNow) IconButton(
                onPressed: () => editLine(),
                icon: Icon(Icons.add_circle_outline, color: palette.primary),
                tooltip: 'Add return line'),
            ]),
            if (lines.isEmpty) const EmptyState(
              title: 'No return lines',
              subtitle: 'Choose a remaining line from the original document.')
            else for (final line in lines) Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Surface(padding: const EdgeInsets.all(12), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(field(objectOf(line['product'])['name'], 'Product'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('Quantity: ${field(line['quantity'])}'),
                Text('Line total: ${money(line['line_total'], widget.app.currency)}'),
                if (canEditNow) Row(
                  mainAxisAlignment: MainAxisAlignment.end, children: [
                  IconButton(onPressed: () => editLine(line),
                    icon: const Icon(Icons.edit_outlined)),
                  IconButton(onPressed: () => deleteLine(line),
                    icon: Icon(Icons.delete_outline, color: palette.error)),
                ]),
              ]))),
            Surface(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Server total: ${money(document?['grand_total'], widget.app.currency)}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
              Text('Status: ${field(document?['status'])}'),
            ])),
            if (widget.kind == ReturnDocumentKind.sale &&
                field(document?['status']) == 'posted' &&
                widget.app.hasPermission('payments.create'))
              Padding(padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: saving ? null : () async {
                    final saved = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => MoneyActionScreen(
                        app: widget.app, kind: MoneyActionKind.saleRefund,
                        documentUlid: id)));
                    if (saved == true && mounted) await refresh();
                  },
                  icon: const Icon(Icons.currency_exchange_outlined),
                  label: const Text('Record Customer Refund'))),
            if (draft && canPost && lines.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: saving ? null : post,
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Review & Post Return'))),
          ],
        ],
        if (createUncertain) const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Unconfirmed draft: do not generate another request.')),
        if (error != null) Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(error!, style: TextStyle(color: palette.error))),
        const SizedBox(height: 35),
      ]),
    );
  }
}
