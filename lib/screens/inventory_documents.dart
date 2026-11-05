import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';

enum InventoryDocumentKind { opening, stockTake, adjustment }

extension InventoryDocumentSpec on InventoryDocumentKind {
  String get title => switch (this) {
    InventoryDocumentKind.opening => 'Opening Stock',
    InventoryDocumentKind.stockTake => 'Stock Taking',
    InventoryDocumentKind.adjustment => 'Stock Adjustments',
  };
  String get path => switch (this) {
    InventoryDocumentKind.opening => '/api/inventory/opening-balances',
    InventoryDocumentKind.stockTake => '/api/inventory/stock-takes',
    InventoryDocumentKind.adjustment => '/api/inventory/adjustments',
  };
  String get dateField => switch (this) {
    InventoryDocumentKind.opening => 'document_date',
    InventoryDocumentKind.stockTake => 'count_date',
    InventoryDocumentKind.adjustment => 'adjustment_date',
  };
  String get editPermission => switch (this) {
    InventoryDocumentKind.opening => 'inventory.opening_balance.edit',
    _ => 'inventory.adjust',
  };
  String get createPermission => switch (this) {
    InventoryDocumentKind.opening => 'inventory.opening_balance.create',
    _ => 'inventory.adjust',
  };
  String get postPermission => switch (this) {
    InventoryDocumentKind.opening => 'inventory.opening_balance.post',
    InventoryDocumentKind.stockTake => 'inventory.stock_take.approve',
    InventoryDocumentKind.adjustment => 'inventory.adjust',
  };
}

class InventoryDocumentDirectory extends StatelessWidget {
  const InventoryDocumentDirectory({
    super.key, required this.app, required this.kind,
  });
  final AppController app;
  final InventoryDocumentKind kind;

  @override
  Widget build(BuildContext context) => TransactionDirectory(
    app: app, title: kind.title, endpoint: kind.path,
    dateKey: kind.dateField,
    amountKey: kind == InventoryDocumentKind.adjustment
      ? 'net_amount' : 'total_cost',
    createPermission: kind.createPermission,
    onCreate: (ctx) async => await Navigator.push<bool>(ctx,
      MaterialPageRoute(builder: (_) =>
        InventoryDocumentEditor(app: app, kind: kind))) ?? false,
    onOpen: (ctx, row) async {
      final id = field(row['ulid']);
      if (!validPublicUlid(id)) return false;
      return await Navigator.push<bool>(ctx,
        MaterialPageRoute(builder: (_) => InventoryDocumentEditor(
          app: app, kind: kind, documentUlid: id))) ?? false;
    },
  );
}

/// All three inventory workflows reuse existing draft/line/post endpoints.
/// Signed quantities and values are calculated by the stock domain service.
class InventoryDocumentEditor extends StatefulWidget {
  const InventoryDocumentEditor({
    super.key, required this.app, required this.kind, this.documentUlid,
  });
  final AppController app;
  final InventoryDocumentKind kind;
  final String? documentUlid;
  @override
  State<InventoryDocumentEditor> createState() =>
    _InventoryDocumentEditorState();
}

class _InventoryDocumentEditorState extends State<InventoryDocumentEditor> {
  final notes = TextEditingController();
  DateTime documentDate = DateTime.now();
  Map<String, dynamic>? document, account;
  bool loading = false, saving = false, uncertainCreate = false;
  String? error;
  bool get created => validPublicUlid(field(document?['ulid']));
  String get id => field(document?['ulid']);
  bool get draft => field(document?['status'], 'draft') == 'draft';
  bool get canEdit => widget.app.hasPermission(widget.kind.editPermission);
  bool get canPost => widget.app.hasPermission(widget.kind.postPermission);
  String get activeWarehouseUlid => field(
    objectOf(widget.app.session?['warehouse'])['ulid']);

  @override
  void initState() {
    super.initState();
    if (widget.documentUlid != null) refresh();
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    final targetId = widget.documentUlid ?? id;
    if (!validPublicUlid(targetId)) return;
    setState(() { loading = true; error = null; });
    try {
      final fetched = resourceOf(
        await widget.app.api.get('${widget.kind.path}/$targetId'));
      if (mounted) setState(() {
        document = fetched;
        account = objectOf(fetched['account']);
        notes.text = field(fetched['notes']);
        documentDate = DateTime.tryParse(
          field(fetched[widget.kind.dateField])) ?? DateTime.now();
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseDate() async {
    final picked = await showDatePicker(context: context,
      initialDate: documentDate, firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)));
    if (picked != null && mounted) setState(() => documentDate = picked);
  }

  Future<void> chooseAccount() async {
    final selected = await pickApiRecord(context, app: widget.app,
      title: 'Adjustment account',
      path: '/api/inventory/adjustments/accounts');
    if (selected != null && mounted) setState(() => account = selected);
  }

  Map<String, dynamic> get header {
    final isAdjustment = widget.kind == InventoryDocumentKind.adjustment;
    return {
      if (!isAdjustment && !created)
        'warehouse_ulid': activeWarehouseUlid,
      if (isAdjustment && validPublicUlid(field(account?['ulid'])))
        'account_ulid': field(account?['ulid']),
      widget.kind.dateField: isoLocalDate(documentDate),
      'notes': notes.text.trim(),
    };
  }

  Future<void> create() async {
    if (created || saving || uncertainCreate ||
        !widget.app.hasPermission(widget.kind.createPermission)) return;
    if (widget.kind == InventoryDocumentKind.adjustment
        ? !validPublicUlid(field(account?['ulid']))
        : !validPublicUlid(activeWarehouseUlid)) {
      setState(() => error = 'Select an authorized location/account.');
      return;
    }
    if (!await confirmMutation(context,
      title: 'Create draft?',
      warning: 'No stock changes occur until the server posts this document.',
      actionLabel: 'Create Draft')) return;
    setState(() { saving = true; error = null; uncertainCreate = true; });
    try {
      final result = resourceOf(
        await widget.app.api.post(widget.kind.path, header));
      if (!validPublicUlid(field(result['ulid']))) {
        throw const ApiFailure('UNCONFIRMED_DRAFT',
          'The server did not confirm this document.', 502);
      }
      if (!mounted) return;
      setState(() { document = result; uncertainCreate = false; });
      await refresh();
    } on ApiFailure catch (ex) {
      if (!mounted) return;
      if (ex.status == 422 || ex.status == 403) uncertainCreate = false;
      setState(() => error = uncertainCreate
        ? 'Draft status uncertain. Check the document list before creating another.'
        : ex.message);
    } catch (_) {
      if (mounted) setState(() => error =
        'Draft status uncertain. Check the document list before creating again.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> updateHeader() async {
    if (!created || !draft || !canEdit || saving) return;
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.patch('${widget.kind.path}/$id', header);
      await refresh();
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> lineEditor([Map<String, dynamic>? original]) async {
    if (!created || !draft || !canEdit || saving) return;
    final kind = widget.kind;
    Map<String, dynamic> product = objectOf(original?['product']);
    final count = TextEditingController(text: field(
      original?[kind == InventoryDocumentKind.opening ? 'quantity' :
      kind == InventoryDocumentKind.stockTake ? 'counted_quantity' :
      'qty_plus'], '0'));
    final cost = TextEditingController(text: field(original?['unit_cost'], '0'));
    final minus = TextEditingController(text: field(original?['qty_minus'], '0'));
    final description = TextEditingController(text:
      field(original?[kind == InventoryDocumentKind.adjustment
        ? 'remarks' : 'notes']));
    String? formError;
    bool inFlight = false;
    bool ambiguous = false;
    try {
      final accepted = await showModalBottomSheet<bool>(context: context,
        showDragHandle: true, useSafeArea: true, isScrollControlled: true,
        builder: (sheet) => StatefulBuilder(
          builder: (sheet, update) => Padding(
            padding: EdgeInsets.fromLTRB(16, 7, 16,
              MediaQuery.viewInsetsOf(sheet).bottom + 14),
            child: ListView(shrinkWrap: true, children: [
              Text(original == null ? 'Add stock line' : 'Edit stock line',
                style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(field(product['name'], 'Choose product')),
                subtitle: Text(field(product['product_number'])),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: inFlight || ambiguous ? null : () async {
                  final chosen = await pickApiRecord(sheet, app: widget.app,
                    title: 'Select product',
                    path: '/api/products?per_page=100&active_only=1',
                    subtitleKey: 'product_number');
                  if (chosen != null && sheet.mounted) {
                    update(() => product = chosen);
                  }
                }),
              const SizedBox(height: 8),
              TextField(controller: count,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText:
                  kind == InventoryDocumentKind.adjustment
                    ? 'Add quantity (plus)' :
                  kind == InventoryDocumentKind.stockTake
                    ? 'Counted quantity' : 'Opening quantity')),
              if (kind == InventoryDocumentKind.adjustment)
                Padding(padding: const EdgeInsets.only(top: 9),
                  child: TextField(controller: minus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Remove quantity (minus)'))),
              if (kind == InventoryDocumentKind.opening)
                Padding(padding: const EdgeInsets.only(top: 9),
                  child: TextField(controller: cost,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Opening unit cost'))),
              const SizedBox(height: 9),
              TextField(controller: description, maxLength: 500,
                decoration: const InputDecoration(labelText: 'Notes')),
              if (formError != null) Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(formError!,
                  style: TextStyle(color: Theme.of(sheet).colorScheme.error))),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: inFlight || ambiguous ? null : () async {
                  if (!validPublicUlid(field(product['ulid'])) ||
                      !validNonNegativeDecimal(count.text.trim(), 6) ||
                      (kind == InventoryDocumentKind.opening &&
                        (!validNonNegativeDecimal(cost.text.trim(), 4))) ||
                      (kind == InventoryDocumentKind.adjustment &&
                        (!validNonNegativeDecimal(minus.text.trim(), 6) ||
                        (count.text.trim() == '0' && minus.text.trim() == '0') ||
                        (count.text.trim() != '0' && minus.text.trim() != '0')))) {
                    update(() => formError = 'Enter a valid product and quantities.');
                    return;
                  }
                  final payload = <String, dynamic>{
                    'product_ulid': field(product['ulid']),
                    if (kind == InventoryDocumentKind.opening) ...{
                      'quantity': count.text.trim(),
                      'unit_cost': cost.text.trim(),
                    },
                    if (kind == InventoryDocumentKind.stockTake)
                      'counted_quantity': count.text.trim(),
                    if (kind == InventoryDocumentKind.adjustment) ...{
                      'qty_plus': count.text.trim(),
                      'qty_minus': minus.text.trim(),
                    },
                    'notes': description.text.trim(),
                  };
                  update(() { inFlight = true; formError = null; });
                  try {
                    if (original == null) {
                      await widget.app.api.post(
                        '${kind.path}/$id/lines', payload);
                    } else {
                      final lineUlid = field(original['ulid']);
                      if (!validPublicUlid(lineUlid)) {
                        throw const FormatException('Invalid stock line.');
                      }
                      await widget.app.api.patch(
                        '${kind.path}/$id/lines/$lineUlid', payload);
                    }
                    if (sheet.mounted) Navigator.pop(sheet, true);
                  } on ApiFailure catch (ex) {
                    if (sheet.mounted) update(() {
                      ambiguous = ex.status == 0 || ex.status >= 500;
                      formError = ambiguous
                        ? 'Line save unconfirmed. Close and reload the document before retrying.'
                        : ex.message;
                    });
                  } catch (_) {
                    if (sheet.mounted) update(() {
                      ambiguous = true;
                      formError = 'Line save unconfirmed. Reload the document before retrying.';
                    });
                  } finally {
                    if (sheet.mounted) update(() => inFlight = false);
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: Text(inFlight ? 'Saving…' : 'Save Stock Line')),
            ]),
          ),
        ));
      if (accepted == true && mounted) await refresh();
    } finally {
      count.dispose(); cost.dispose(); minus.dispose(); description.dispose();
    }
  }

  Future<void> removeLine(Map<String, dynamic> line) async {
    if (!created || !draft || !canEdit || saving) return;
    final lineUlid = field(line['ulid']);
    if (!validPublicUlid(lineUlid)) return;
    if (!await confirmMutation(context,
      title: 'Delete draft line?',
      warning: 'The unposted line will be deleted.',
      actionLabel: 'Delete Line')) return;
    setState(() => saving = true);
    try {
      await widget.app.api.request('DELETE',
        '${widget.kind.path}/$id/lines/$lineUlid');
      await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> post() async {
    if (!created || !draft || !canPost || saving ||
        recordsOf(document?['lines']).isEmpty) return;
    if (!await confirmMutation(context,
      title: 'Post ${widget.kind.title}?',
      warning: 'The BluePOS inventory service will permanently post these '
        'stock movements. Posted records cannot be edited or deleted.',
      actionLabel: 'Post Stock')) return;
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.post('${widget.kind.path}/$id/post', {});
      await refresh();
    } catch (ex) {
      if (mounted) {
        await refresh();
        if (mounted) setState(() => error =
          'Posting unconfirmed. Review current server status before another attempt: $ex');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> removeDraft() async {
    if (!created || !draft || !canEdit || saving) return;
    if (!await confirmMutation(context,
      title: 'Delete unposted document?',
      warning: 'This permanently deletes the DRAFT and its lines. '
        'Posted stock records cannot be deleted.',
      actionLabel: 'Delete Draft')) return;
    setState(() => saving = true);
    try {
      await widget.app.api.request('DELETE', '${widget.kind.path}/$id');
      if (mounted) Navigator.pop(context, true);
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    final lines = recordsOf(document?['lines']);
    return Scaffold(
      appBar: AppBar(title: Text(created
        ? field(document?['document_number'], widget.kind.title)
        : 'New ${widget.kind.title}'),
        actions: [if (created) IconButton(
          onPressed: saving || loading ? null : refresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh from server')]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionHeading(widget.kind.title),
        Text('Branch: ${widget.app.branchName} · '
          'Warehouse: ${widget.app.warehouseName}',
          style: TextStyle(fontSize: 12,
            color: palette.onSurfaceVariant)),
        const SizedBox(height: 10),
        if (loading) pageLoading()
        else ...[
          Surface(child: Column(children: [
            if (widget.kind == InventoryDocumentKind.adjustment)
              ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: Text(field(account?['name'], 'Choose adjustment account')),
                subtitle: Text(field(account?['code'])),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: !created || (draft && canEdit) ? chooseAccount : null),
            OutlinedButton.icon(
              onPressed: !created || (draft && canEdit) ? chooseDate : null,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Date: ${isoLocalDate(documentDate)}')),
            const SizedBox(height: 9),
            TextField(controller: notes,
              readOnly: created && (!draft || !canEdit),
              maxLength: 500, maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes')),
            if (!created && widget.app.hasPermission(widget.kind.createPermission))
              FilledButton.icon(
                onPressed: saving || uncertainCreate ? null : create,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Create Draft')),
            if (created && draft && canEdit)
              OutlinedButton.icon(onPressed: saving ? null : updateHeader,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Header')),
          ])),
          if (created) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: SectionHeading('Stock lines (${lines.length})')),
              if (draft && canEdit && !saving)
                IconButton(onPressed: () => lineEditor(),
                  icon: Icon(Icons.add_circle_outline, color: palette.primary),
                  tooltip: 'Add stock line'),
            ]),
            if (lines.isEmpty) const EmptyState(
              title: 'No stock lines',
              subtitle: 'Add a product and its quantity.')
            else for (final line in lines)
              Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Surface(padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(objectOf(line['product'])['name']),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (widget.kind == InventoryDocumentKind.opening) ...[
                      Text('Opening: ${field(line['quantity'])}'),
                      Text('Unit cost: ${money(line['unit_cost'], widget.app.currency)}'),
                      Text('Total cost: ${money(line['total_cost'], widget.app.currency)}'),
                    ] else if (widget.kind == InventoryDocumentKind.stockTake) ...[
                      Text('System: ${field(line['system_quantity'])}'),
                      Text('Counted: ${field(line['counted_quantity'])}'),
                      Text('Variance: ${field(line['variance_quantity'])}'),
                    ] else ...[
                      Text('In stock: ${field(line['in_stock'])}'),
                      Text('Add: ${field(line['qty_plus'])} · '
                        'Remove: ${field(line['qty_minus'])}'),
                      Text('After stock: ${field(line['after_stock'])}'),
                    ],
                    if (draft && canEdit) Row(
                      mainAxisAlignment: MainAxisAlignment.end, children: [
                      IconButton(onPressed: saving ? null : () => lineEditor(line),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit stock line'),
                      IconButton(onPressed: saving ? null : () => removeLine(line),
                        icon: Icon(Icons.delete_outline_rounded,
                          color: palette.error), tooltip: 'Remove line'),
                    ]),
                  ]))),
            const SizedBox(height: 10),
            Surface(child: Text('Status: ${field(document?['status'])}',
              style: const TextStyle(fontWeight: FontWeight.w800))),
            if (draft && canPost && lines.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(onPressed: saving ? null : post,
                  icon: const Icon(Icons.verified_rounded),
                  label: Text('Post ${widget.kind.title}'))),
            if (draft && canEdit)
              Padding(padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: saving ? null : removeDraft,
                  icon: Icon(Icons.delete_outline_rounded,
                    color: palette.error),
                  label: const Text('Delete Draft'))),
          ],
        ],
        if (uncertainCreate)
          const Text('Draft status uncertain. Check the document directory before retrying.'),
        if (error != null) Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(error!, style: TextStyle(color: palette.error))),
        const SizedBox(height: 30),
      ]),
    );
  }
}
