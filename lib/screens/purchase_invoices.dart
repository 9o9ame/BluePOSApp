import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';
import 'money_actions.dart';

/// Purchase invoices are staged on the server: draft header, separately
/// persisted lines, review and explicit posting through the existing atomic
/// accounting+stock PostPurchaseInvoiceAction. Client totals are informational.
class PurchaseInvoicesScreen extends StatelessWidget {
  const PurchaseInvoicesScreen({super.key, required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) => TransactionDirectory(
    app: app,
    title: 'Purchase Invoices',
    endpoint: '/api/purchases',
    dateKey: 'invoice_date',
    createPermission: 'purchases.create',
    onCreate: (ctx) async => await Navigator.push<bool>(ctx,
      MaterialPageRoute(builder: (_) =>
        PurchaseInvoiceEditor(app: app))) ?? false,
    onOpen: (ctx, row) async {
      final ulid = field(row['ulid']);
      if (!validPublicUlid(ulid)) return false;
      return await Navigator.push<bool>(ctx,
        MaterialPageRoute(builder: (_) =>
          PurchaseInvoiceEditor(app: app, documentUlid: ulid))) ?? false;
    },
  );
}

class PurchaseInvoiceEditor extends StatefulWidget {
  const PurchaseInvoiceEditor({
    super.key, required this.app, this.documentUlid,
  });
  final AppController app;
  final String? documentUlid;
  @override
  State<PurchaseInvoiceEditor> createState() => _PurchaseInvoiceEditorState();
}

class _PurchaseInvoiceEditorState extends State<PurchaseInvoiceEditor> {
  final notes = TextEditingController();
  final supplierInvoice = TextEditingController();
  Map<String, dynamic>? supplier, document;
  DateTime date = DateTime.now();
  bool loading = false, saving = false, uncertainCreate = false;
  String? error;
  bool get hasDocument => validPublicUlid(field(document?['ulid']));
  String get ulid => field(document?['ulid']);
  bool get draft => field(document?['status'], 'draft') == 'draft';
  String get warehouseUlid =>
    field(objectOf(widget.app.session?['warehouse'])['ulid']);
  bool get canEdit => widget.app.hasPermission('purchases.edit');
  bool get canPost => widget.app.hasPermission('purchases.post');

  @override
  void initState() {
    super.initState();
    if (widget.documentUlid != null) refresh();
  }

  @override
  void dispose() {
    notes.dispose();
    supplierInvoice.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    final id = widget.documentUlid ?? ulid;
    if (!validPublicUlid(id)) return;
    setState(() { loading = true; error = null; });
    try {
      final data = resourceOf(await widget.app.api.get('/api/purchases/$id'));
      if (!mounted) return;
      setState(() {
        document = data;
        supplier = objectOf(data['supplier']);
        notes.text = field(data['notes']);
        supplierInvoice.text = field(data['supplier_invoice_number']);
        date = DateTime.tryParse(field(data['invoice_date'])) ?? DateTime.now();
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> chooseSupplier() async {
    final selected = await pickApiRecord(context, app: widget.app,
      title: 'Select supplier', path: '/api/parties?type=vendor');
    if (selected != null && mounted) setState(() => supplier = selected);
  }

  Future<void> chooseDate() async {
    final d = await showDatePicker(context: context, initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)));
    if (d != null && mounted) setState(() => date = d);
  }

  Future<void> createDraft() async {
    if (saving || hasDocument || uncertainCreate ||
      !widget.app.hasPermission('purchases.create')) return;
    final supplierUlid = field(supplier?['ulid']);
    if (!validPublicUlid(supplierUlid) ||
        !validPublicUlid(warehouseUlid)) {
      setState(() => error =
        'Select an active supplier and active warehouse before creating a draft.');
      return;
    }
    if (!await confirmMutation(context,
      title: 'Create purchase draft?',
      warning: 'The purchase will remain DRAFT until you add lines and post it.',
      actionLabel: 'Create Draft')) return;
    setState(() { saving = true; error = null; uncertainCreate = true; });
    try {
      final result = resourceOf(await widget.app.api.post('/api/purchases', {
        'supplier_ulid': supplierUlid,
        'warehouse_ulid': warehouseUlid,
        'invoice_date': isoLocalDate(date),
        'supplier_invoice_number': supplierInvoice.text.trim(),
        'notes': notes.text.trim(),
      }));
      if (!validPublicUlid(field(result['ulid']))) {
        throw const ApiFailure('UNCONFIRMED_PURCHASE',
          'The server has not confirmed this draft.', 502);
      }
      if (!mounted) return;
      setState(() {
        document = result;
        uncertainCreate = false;
      });
      await refresh();
    } on ApiFailure catch (ex) {
      if (!mounted) return;
      if (ex.status == 403 || ex.status == 422) uncertainCreate = false;
      setState(() => error = uncertainCreate
        ? 'Draft save is unconfirmed. Check Purchase Invoices history before starting another draft.'
        : ex.message);
    } catch (_) {
      if (mounted) setState(() => error =
        'Draft save is unconfirmed. Check Purchase Invoices history before creating again.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveHeader() async {
    if (saving || !hasDocument || !draft || !canEdit) return;
    if (!validPublicUlid(field(supplier?['ulid']))) return;
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.patch('/api/purchases/$ulid', {
        'supplier_ulid': field(supplier?['ulid']),
        'invoice_date': isoLocalDate(date),
        'supplier_invoice_number': supplierInvoice.text.trim(),
        'notes': notes.text.trim(),
      });
      await refresh();
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> lineEditor([Map<String, dynamic>? original]) async {
    if (!hasDocument || !draft || !canEdit) return;
    Map<String, dynamic> product = objectOf(original?['product']);
    Map<String, dynamic> unit = objectOf(original?['unit']);
    final qty = TextEditingController(text: field(original?['quantity'], '1'));
    final cost = TextEditingController(text: field(original?['unit_cost'], '0'));
    final batch = TextEditingController(text: field(original?['batch_number']));
    final notesController = TextEditingController(text: field(original?['notes']));
    DateTime? expiry = DateTime.tryParse(field(original?['expiry_date']));
    String? formError;
    bool inFlight = false;
    bool ambiguous = false;
    try {
      final saved = await showModalBottomSheet<bool>(context: context,
        showDragHandle: true, isScrollControlled: true, useSafeArea: true,
        builder: (sheet) => StatefulBuilder(builder: (sheet, change) =>
          Padding(padding: EdgeInsets.fromLTRB(16, 7, 16,
            MediaQuery.viewInsetsOf(sheet).bottom + 16),
            child: ListView(shrinkWrap: true, children: [
              Text(original == null ? 'Add purchase line' : 'Edit purchase line',
                style: Theme.of(sheet).textTheme.titleLarge),
              const SizedBox(height: 12),
              Surface(child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(field(product['name'], 'Select product')),
                subtitle: Text(field(unit['name'], 'Base unit')),
                trailing: const Icon(Icons.chevron_right),
                onTap: original != null || inFlight ? null : () async {
                  final selected = await pickApiRecord(sheet,
                    app: widget.app, title: 'Choose product',
                    path: '/api/products?per_page=100&active_only=1',
                    subtitleKey: 'product_number');
                  if (selected == null || !sheet.mounted) return;
                  final base = objectOf(selected['base_unit']);
                  if (!validPublicUlid(field(base['ulid']))) {
                    change(() => formError =
                      'Product has no supported base unit.');
                    return;
                  }
                  change(() { product = selected; unit = base; formError = null; });
                })),
              const SizedBox(height: 10),
              TextField(controller: qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity *')),
              const SizedBox(height: 9),
              TextField(controller: cost,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Unit cost *')),
              const SizedBox(height: 9),
              TextField(controller: batch,
                maxLength: 100,
                decoration: InputDecoration(labelText:
                  product['track_batch'] == true
                    ? 'Batch number *' : 'Batch number (optional)')),
              const SizedBox(height: 7),
              OutlinedButton.icon(
                onPressed: inFlight ? null : () async {
                  final selected = await showDatePicker(context: sheet,
                    initialDate: expiry ?? DateTime.now(),
                    firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (selected != null && sheet.mounted) {
                    change(() => expiry = selected);
                  }
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(expiry == null
                  ? product['track_expiry'] == true
                    ? 'Expiry date *' : 'Expiry date (optional)'
                  : isoLocalDate(expiry!))),
              TextField(controller: notesController, maxLength: 500,
                decoration: const InputDecoration(labelText: 'Line notes')),
              if (formError != null) Text(formError!,
                style: TextStyle(color: Theme.of(sheet).colorScheme.error)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: inFlight || ambiguous ? null : () async {
                  final id = field(product['ulid']);
                  final base = field(unit['ulid']);
                  if (!validPublicUlid(id) || !validPublicUlid(base) ||
                      !validPositiveDecimal(qty.text.trim(), 6) ||
                      !validNonNegativeDecimal(cost.text.trim(), 4) ||
                      (product['track_batch'] == true &&
                        batch.text.trim().isEmpty) ||
                      (product['track_expiry'] == true && expiry == null)) {
                    change(() => formError =
                      'Enter a product, valid quantities/cost and required batch/expiry.');
                    return;
                  }
                  change(() { inFlight = true; formError = null; });
                  try {
                    final payload = <String, dynamic>{
                      'product_ulid': id,
                      'unit_ulid': base,
                      'quantity': qty.text.trim(),
                      'unit_cost': cost.text.trim(),
                      if (batch.text.trim().isNotEmpty)
                        'batch_number': batch.text.trim(),
                      if (expiry != null) 'expiry_date': isoLocalDate(expiry!),
                      'notes': notesController.text.trim(),
                    };
                    if (original == null) {
                      await widget.app.api.post('/api/purchases/$ulid/lines', payload);
                    } else {
                      final lineUlid = field(original['ulid']);
                      if (!validPublicUlid(lineUlid)) {
                        throw const FormatException('Invalid purchase line.');
                      }
                      await widget.app.api.patch(
                        '/api/purchases/$ulid/lines/$lineUlid', payload);
                    }
                    if (sheet.mounted) Navigator.pop(sheet, true);
                  } on ApiFailure catch (ex) {
                    if (sheet.mounted) change(() {
                      ambiguous = ex.status == 0 || ex.status >= 500;
                      formError = ambiguous
                        ? 'Save status uncertain. Close and refresh the invoice before retrying this line.'
                        : ex.message;
                    });
                  } catch (_) {
                    if (sheet.mounted) change(() {
                      ambiguous = true;
                      formError = 'Save status uncertain. Close and refresh before trying again.';
                    });
                  } finally {
                    if (sheet.mounted) change(() => inFlight = false);
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: Text(inFlight ? 'Saving…' : 'Save line')),
            ])),
        ));
      if (saved == true && mounted) await refresh();
    } finally {
      qty.dispose(); cost.dispose(); batch.dispose(); notesController.dispose();
    }
  }

  Future<void> deleteLine(Map<String, dynamic> line) async {
    if (!draft || !canEdit || saving || !hasDocument) return;
    final lineUlid = field(line['ulid']);
    if (!validPublicUlid(lineUlid)) return;
    if (!await confirmMutation(context,
      title: 'Remove draft line?',
      warning: 'Only this unposted line will be removed.',
      actionLabel: 'Remove')) return;
    setState(() => saving = true);
    try {
      await widget.app.api.request('DELETE', '/api/purchases/$ulid/lines/$lineUlid');
      await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> post() async {
    final lines = recordsOf(document?['lines']);
    if (!hasDocument || !draft || !canPost || lines.isEmpty || saving) return;
    if (!await confirmMutation(context,
      title: 'Post Purchase Invoice?',
      warning: 'This action posts supplier accounting and stock movements '
        'through the BluePOS server. Posted records are immutable.',
      actionLabel: 'Post Invoice')) return;
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.post('/api/purchases/$ulid/post', {});
      await refresh();
    } catch (ex) {
      if (mounted) {
        await refresh();
        if (mounted) setState(() => error =
          'Posting could not be confirmed. Review the server status before retrying. $ex');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final serverLines = recordsOf(document?['lines']);
    final displayDate = isoLocalDate(date);
    return Scaffold(
      appBar: AppBar(title: Text(hasDocument
        ? field(document?['document_number'], 'Purchase Invoice')
        : 'New Purchase Invoice'),
        actions: [if (hasDocument) IconButton(
          onPressed: loading || saving ? null : refresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Reload server document')]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SectionHeading('Purchase Invoice'),
        Text('Current branch: ${widget.app.branchName} · '
          'Warehouse: ${widget.app.warehouseName}',
          style: TextStyle(fontSize: 12,
            color: colors.onSurfaceVariant)),
        const SizedBox(height: 11),
        if (loading) pageLoading()
        else ...[
          Surface(child: Column(children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(field(supplier?['name'], 'Choose supplier')),
              subtitle: Text(field(supplier?['code'])),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: hasDocument && (!draft || !canEdit) ? null : chooseSupplier),
            OutlinedButton.icon(
              onPressed: !hasDocument || (draft && canEdit) ? chooseDate : null,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Invoice Date: $displayDate')),
            TextField(controller: supplierInvoice,
              maxLength: 100,
              readOnly: hasDocument && (!draft || !canEdit),
              decoration: const InputDecoration(
                labelText: 'Supplier invoice number')),
            TextField(controller: notes,
              maxLength: 5000, maxLines: 2,
              readOnly: hasDocument && (!draft || !canEdit),
              decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 8),
            if (!hasDocument && widget.app.hasPermission('purchases.create'))
              FilledButton.icon(onPressed: saving || uncertainCreate
                ? null : createDraft,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Create Draft')),
            if (hasDocument && draft && canEdit)
              OutlinedButton.icon(onPressed: saving ? null : saveHeader,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Header')),
          ])),
          if (hasDocument) ...[
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: SectionHeading('Purchase lines (${serverLines.length})')),
              if (draft && canEdit && !saving)
                IconButton(onPressed: () => lineEditor(),
                  icon: Icon(Icons.add_circle_outline, color: colors.primary),
                  tooltip: 'Add purchase line'),
            ]),
            if (serverLines.isEmpty) const EmptyState(
              title: 'No draft lines',
              subtitle: 'Add products before posting.')
            else for (final line in serverLines)
              Padding(padding: const EdgeInsets.only(bottom: 9),
                child: Surface(padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(objectOf(line['product'])['name'], 'Product'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text('Quantity: ${field(line['quantity'])}  ·  '
                      'Cost: ${money(line['unit_cost'], widget.app.currency)}'),
                    Text('Line total: ${money(line['line_total'], widget.app.currency)}'),
                    if (field(line['batch_number']).isNotEmpty)
                      Text('Batch: ${field(line['batch_number'])}'),
                    if (draft && canEdit) Row(
                      mainAxisAlignment: MainAxisAlignment.end, children: [
                      IconButton(onPressed: saving ? null :
                        () => lineEditor(line),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit line'),
                      IconButton(onPressed: saving ? null :
                        () => deleteLine(line),
                        icon: Icon(Icons.delete_outline, color: colors.error),
                        tooltip: 'Remove draft line'),
                    ]),
                  ]))),
            const SizedBox(height: 12),
            Surface(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Server-calculated total',
                style: TextStyle(color: colors.onSurfaceVariant,
                  fontSize: 12)),
              Text(money(document?['grand_total'], widget.app.currency),
                style: const TextStyle(fontWeight: FontWeight.w900,
                  fontSize: 22)),
              Text('Status: ${field(document?['status'])}',
                style: const TextStyle(fontSize: 12)),
              if (field(document?['status']) == 'posted') ...[
                Text('Paid: ${money(document?['paid_amount'], widget.app.currency)}'),
                Text('Balance: ${money(document?['balance_payable'], widget.app.currency)}'),
              ],
            ])),
            if (field(document?['status']) == 'posted' &&
                widget.app.hasPermission('payments.create'))
              Padding(padding: const EdgeInsets.only(top: 13),
                child: OutlinedButton.icon(
                  onPressed: saving ? null : () async {
                    final saved = await Navigator.push<bool>(context,
                      MaterialPageRoute(builder: (_) => MoneyActionScreen(
                        app: widget.app, kind: MoneyActionKind.purchasePayment,
                        documentUlid: ulid)));
                    if (saved == true && mounted) await refresh();
                  },
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Record Purchase Payment'))),
            if (draft && canPost) Padding(
              padding: const EdgeInsets.only(top: 13),
              child: FilledButton.icon(
                onPressed: saving || serverLines.isEmpty ? null : post,
                icon: const Icon(Icons.verified_rounded),
                label: const Text('Review & Post Purchase Invoice'))),
          ],
        ],
        if (uncertainCreate) const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Draft request status uncertain. Use invoice history to reconcile.')),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 9),
          child: Text(error!, style: TextStyle(color: colors.error))),
        const SizedBox(height: 36),
      ]),
    );
  }
}
