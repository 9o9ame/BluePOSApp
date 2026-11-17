import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import '../widgets/party_ledger_summary.dart';
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
    referenceStyle: true,
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
  final freight = TextEditingController();
  final otherDiscount = TextEditingController();
  final paymentTerms = TextEditingController();
  Map<String, dynamic>? supplier, document;
  DateTime date = DateTime.now();
  DateTime? dueDate;
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
    freight.dispose(); otherDiscount.dispose(); paymentTerms.dispose();
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
        freight.text = field(data['freight_amount']);
        otherDiscount.text = field(data['other_discount']);
        paymentTerms.text = field(data['payment_terms']);
        dueDate = DateTime.tryParse(field(data['due_date']));
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

  bool get validHeaderMoney =>
    (freight.text.trim().isEmpty ||
      validNonNegativeDecimal(freight.text.trim(), 4)) &&
    (otherDiscount.text.trim().isEmpty ||
      validNonNegativeDecimal(otherDiscount.text.trim(), 4));

  Map<String, dynamic> get supportedHeaderFields => {
    if (freight.text.trim().isNotEmpty)
      'freight_amount': freight.text.trim(),
    if (otherDiscount.text.trim().isNotEmpty)
      'other_discount': otherDiscount.text.trim(),
    if (paymentTerms.text.trim().isNotEmpty)
      'payment_terms': paymentTerms.text.trim(),
    if (dueDate != null) 'due_date': isoLocalDate(dueDate!),
  };

  Future<void> chooseDueDate() async {
    if (hasDocument && (!draft || !canEdit)) return;
    final chosen = await showDatePicker(context: context,
      initialDate: dueDate ?? date, firstDate: DateTime(2020),
      lastDate: DateTime(2100));
    if (chosen != null && mounted) setState(() => dueDate = chosen);
  }

  Future<void> createDraft() async {
    if (saving || hasDocument || uncertainCreate ||
      !widget.app.hasPermission('purchases.create')) { return; }
    final supplierUlid = field(supplier?['ulid']);
    if (!validPublicUlid(supplierUlid) ||
        !validPublicUlid(warehouseUlid)) {
      setState(() => error =
        'Select an active supplier and active warehouse before creating a draft.');
      return;
    }
    if (!validHeaderMoney) {
      setState(() => error = 'Freight and Other Discount must be non-negative amounts with up to four decimal places.');
      return;
    }
    if (!await confirmMutation(context,
      title: 'Create purchase draft?',
      warning: 'The purchase will remain DRAFT until you add lines and post it.',
      actionLabel: 'Create Draft')) { return; }
    setState(() { saving = true; error = null; uncertainCreate = true; });
    try {
      final result = resourceOf(await widget.app.api.post('/api/purchases', {
        'supplier_ulid': supplierUlid,
        'warehouse_ulid': warehouseUlid,
        'invoice_date': isoLocalDate(date),
        'supplier_invoice_number': supplierInvoice.text.trim(),
        'notes': notes.text.trim(),
        ...supportedHeaderFields,
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
      if (mounted) { setState(() => error =
        'Draft save is unconfirmed. Check Purchase Invoices history before creating again.'); }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveHeader() async {
    if (saving || !hasDocument || !draft || !canEdit) return;
    if (!validPublicUlid(field(supplier?['ulid']))) return;
    if (!validHeaderMoney) {
      setState(() => error = 'Enter valid non-negative freight and discount amounts.');
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.patch('/api/purchases/$ulid', {
        'supplier_ulid': field(supplier?['ulid']),
        'invoice_date': isoLocalDate(date),
        'supplier_invoice_number': supplierInvoice.text.trim(),
        'notes': notes.text.trim(),
        ...supportedHeaderFields,
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
                    if (sheet.mounted) { change(() {
                      ambiguous = ex.status == 0 || ex.status >= 500;
                      formError = ambiguous
                        ? 'Save status uncertain. Close and refresh the invoice before retrying this line.'
                        : ex.message;
                    }); }
                  } catch (_) {
                    if (sheet.mounted) { change(() {
                      ambiguous = true;
                      formError = 'Save status uncertain. Close and refresh before trying again.';
                    }); }
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
      actionLabel: 'Remove')) { return; }
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
      actionLabel: 'Post Invoice')) { return; }
    setState(() { saving = true; error = null; });
    try {
      await widget.app.api.post('/api/purchases/$ulid/post', {});
      await refresh();
    } catch (ex) {
      if (mounted) {
        await refresh();
        if (mounted) { setState(() => error =
          'Posting could not be confirmed. Review the server status before retrying. $ex'); }
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> printPurchase() async {
    if (!hasDocument || field(document?['status']) != 'posted' ||
        saving) { return; }
    setState(() => saving = true);
    try {
      // Read-only document: all amounts, rates and quantities come from the
      // authorized server purchase invoice, never mobile calculations.
      final purchase = document!;
      final rows = recordsOf(purchase['lines']);
      final pdf = pw.Document(
        title: 'BluePOS Purchase ${field(purchase['document_number'])}');
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Header(level: 0, child: pw.Text('BLUEPOS — PURCHASE INVOICE',
            style: pw.TextStyle(fontSize: 19,
              fontWeight: pw.FontWeight.bold))),
          pw.Text(widget.app.tenantName),
          pw.Text('${widget.app.branchName} · ${widget.app.warehouseName}'),
          pw.SizedBox(height: 10),
          pw.Text('Invoice: ${field(purchase['document_number'])}'),
          pw.Text('Date: ${field(purchase['invoice_date'])}'),
          pw.Text('Status: ${field(purchase['status'])}'),
          pw.Text('Supplier: ${field(supplier?['name'])}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Product', 'Qty', 'Rate', 'Line total'],
            data: rows.map((line) => [
              field(objectOf(line['product'])['name']),
              field(line['quantity']),
              field(line['unit_cost']),
              field(line['line_total']),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          if (purchase['subtotal'] != null)
            pw.Text('Subtotal: ${field(purchase['subtotal'])}'),
          if (purchase['tax_amount'] != null)
            pw.Text('Tax: ${field(purchase['tax_amount'])}'),
          pw.Text('Grand total: ${field(purchase['grand_total'])}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),
          pw.Text('Generated from authorized BluePOS server records.',
            style: const pw.TextStyle(fontSize: 9)),
        ],
      ));
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'BluePOS Purchase ${field(purchase['document_number'])}');
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final serverLines = recordsOf(document?['lines']);
    final displayDate = isoLocalDate(date);
    final style = BpReferenceStyle.of(context);
    final mayCreate = widget.app.hasPermission('purchases.create');
    return Scaffold(
      backgroundColor: style.page,
      appBar: BpReferenceSubpageAppBar(
        title: hasDocument ? 'Purchase Invoice Detail'
          : 'Create Purchase Invoice'),
      bottomNavigationBar: !loading &&
          ((!hasDocument && mayCreate) ||
           (hasDocument && draft && (canEdit || canPost)))
        ? BpReferenceWorkflowActions(
          leftKey: const ValueKey('purchase-save-draft'),
          rightKey: const ValueKey('purchase-post'),
          leftLabel: hasDocument ? 'Save Draft' : 'Create Draft',
          rightLabel: 'Post Purchase',
          onLeft: saving || uncertainCreate ? null
            : !hasDocument ? createDraft
            : draft && canEdit ? saveHeader : null,
          onRight: saving || !hasDocument || !draft ||
              !canPost || serverLines.isEmpty ? null : post,
        )
        : hasDocument && !draft && !loading
          ? BpReferenceWorkflowActions(
              leftKey: const ValueKey('purchase-detail-print'),
              rightKey: const ValueKey('purchase-detail-ledger'),
              leftLabel: 'Print',
              rightLabel: 'View Ledger',
              rightColor: const Color(0xFF006DF6),
              leftIcon: Icons.print_outlined,
              rightIcon: Icons.layers_outlined,
              onLeft: saving || field(document?['status']) != 'posted'
                ? null : printPurchase,
              onRight: saving ||
                  !validPublicUlid(field(supplier?['ulid'])) ||
                  !(widget.app.hasPermission('suppliers.view') ||
                    widget.app.hasPermission('suppliers.manage'))
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BpPartyLedgerScreen(
                      app: widget.app, partyType: 'vendor',
                      partyUlid: field(supplier?['ulid'])))),
            )
          : null,
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        ListView(
          key: const ValueKey('reference-purchase-editor'),
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 46),
          children: [
        if (hasDocument && !draft) ...[
          Container(
            padding: const EdgeInsets.all(11),
            decoration: style.card(radius: 15),
            child: Row(children: [
              Container(width: 41, height: 41,
                decoration: BoxDecoration(
                  color: style.scheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.receipt_long_outlined,
                  color: style.scheme.primary)),
              const SizedBox(width: 9),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field(document?['document_number']),
                    style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w900, color: style.ink)),
                  Text(field(supplier?['name'], 'Supplier unavailable'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: style.muted)),
                  Text(field(document?['invoice_date']),
                    style: TextStyle(fontSize: 10, color: style.muted)),
                ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: field(document?['status']) == 'posted'
                    ? const Color(0xFFD7F8E2)
                    : style.surfaceEnd,
                  borderRadius: BorderRadius.circular(11)),
                child: Text(field(document?['status'], 'Unknown'),
                  style: TextStyle(fontSize: 10,
                    color: const Color(0xFF087C45),
                    fontWeight: FontWeight.w900))),
            ]),
          ),
          const SizedBox(height: 7),
          if (field(document?['status']) == 'posted')
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 9),
              decoration: style.card(radius: 13),
              child: Row(children: [
                Icon(Icons.inventory_2_outlined, color: style.green),
                const SizedBox(width: 8),
                Expanded(child: Text('Purchase posted — inventory was processed by BluePOS',
                  style: TextStyle(color: style.green,
                    fontWeight: FontWeight.w800, fontSize: 11))),
                Icon(Icons.check_circle, color: style.green),
              ]),
            ),
          const SizedBox(height: 8),
        ] else if (hasDocument) ...[
          Text('Draft — not posted', style: TextStyle(
            color: style.muted, fontSize: 11)),
          const SizedBox(height: 7),
        ],
        if (loading) pageLoading()
        else ...[

          if (!hasDocument || draft) ...[
            Row(children: [
              Expanded(child: BpReferenceCompactField(
                label: 'Supplier *', icon: Icons.person_outline_rounded,
                hint: 'Select supplier', value: field(supplier?['name']),
                onTap: hasDocument && (!draft || !canEdit)
                  ? null : chooseSupplier)),
              const SizedBox(width: 7),
              Expanded(child: BpReferenceCompactField(
                label: 'Invoice Number (server)',
                icon: Icons.receipt_long_outlined,
                value: field(document?['document_number']),
                hint: 'Assigned on draft')),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: BpReferenceCompactField(
                label: 'Invoice Date', icon: Icons.calendar_today_outlined,
                value: displayDate,
                onTap: !hasDocument || (draft && canEdit)
                  ? chooseDate : null)),
              const SizedBox(width: 7),
              Expanded(child: BpReferenceCompactField(
                label: 'Warehouse *', icon: Icons.warehouse_outlined,
                value: field(objectOf(document?['warehouse'])['name'],
                  widget.app.warehouseName))),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: BpReferenceCompactField(
                label: 'Supplier Invoice Ref.',
                icon: Icons.description_outlined,
                controller: supplierInvoice, hint: 'Supplier reference',
                readOnly: hasDocument && (!draft || !canEdit))),
              const SizedBox(width: 7),
              Expanded(child: BpReferenceCompactField(
                label: 'Due Date', icon: Icons.event_outlined,
                value: dueDate == null ? '' : isoLocalDate(dueDate!),
                hint: 'Select date',
                onTap: hasDocument && (!draft || !canEdit)
                  ? null : chooseDueDate)),
            ]),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: BpReferenceCompactField(
                label: 'Payment Terms', icon: Icons.credit_card_outlined,
                controller: paymentTerms, hint: 'Optional terms',
                readOnly: hasDocument && (!draft || !canEdit))),
              const SizedBox(width: 7),
              Expanded(child: BpReferenceCompactField(
                label: 'Freight Amount', icon: Icons.local_shipping_outlined,
                controller: freight, hint: '0.0000',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
                readOnly: hasDocument && (!draft || !canEdit))),
            ]),
            const SizedBox(height: 7),
            BpReferenceCompactField(
              label: 'Other Discount', icon: Icons.discount_outlined,
              controller: otherDiscount, hint: '0.0000',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
              readOnly: hasDocument && (!draft || !canEdit)),
            const SizedBox(height: 7),
          BpReferenceFormField(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Notes', hint: 'Enter remarks (optional)',
            controller: notes, maxLength: 5000, maxLines: 2,
            readOnly: hasDocument && (!draft || !canEdit)),
          ],
          if (hasDocument) ...[
            const SizedBox(height: 13),
            Surface(child: Row(children: [
              Icon(draft ? Icons.edit_note_rounded : Icons.inventory_2_outlined,
                color: colors.primary),
              const SizedBox(width: 9),
              Expanded(child: Text(draft ? 'Draft — not posted' :
                'Server status: ${field(document?['status'])}',
                style: const TextStyle(fontWeight: FontWeight.w800))),
            ])),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: SectionHeading('Products (${serverLines.length})')),
              if (draft && canEdit && !saving)
                OutlinedButton.icon(
                  key: const ValueKey('purchase-add-product'),
                  onPressed: () => lineEditor(),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Product',
                    style: TextStyle(fontSize: 11))),
            ]),
            if (serverLines.isEmpty) const EmptyState(
              title: 'No draft lines',
              subtitle: 'Add products before posting.')
            else if (!draft)
              Container(
                padding: const EdgeInsets.all(9),
                decoration: style.card(radius: 13),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 9),
                    decoration: BoxDecoration(
                      color: style.surfaceEnd,
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Expanded(flex: 5, child: Text('Product',
                        style: TextStyle(color: style.ink,
                          fontSize: 10, fontWeight: FontWeight.w900))),
                      Expanded(flex: 2, child: Text('Qty',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: style.ink,
                          fontSize: 10, fontWeight: FontWeight.w900))),
                      Expanded(flex: 2, child: Text('Rate',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: style.ink,
                          fontSize: 10, fontWeight: FontWeight.w900))),
                      Expanded(flex: 3, child: Text('Amount',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: style.ink,
                          fontSize: 10, fontWeight: FontWeight.w900))),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  for (final line in serverLines) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(flex: 5, child: Row(children: [
                          Container(width: 27, height: 28,
                            decoration: BoxDecoration(
                              color: style.scheme.primary.withValues(
                                alpha: .12),
                              borderRadius: BorderRadius.circular(7)),
                            child: Icon(Icons.inventory_2_outlined,
                              size: 16, color: style.scheme.primary)),
                          const SizedBox(width: 5),
                          Expanded(child: Text(
                            field(objectOf(line['product'])['name'],
                              'Product'),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10,
                              color: style.ink,
                              fontWeight: FontWeight.w800))),
                        ])),
                        Expanded(flex: 2, child: Text(
                          bpReferenceDecimalLabel(line['quantity']),
                          maxLines: 1, textAlign: TextAlign.end,
                          style: TextStyle(color: style.ink, fontSize: 10))),
                        Expanded(flex: 2, child: Text(
                          bpReferenceDecimalLabel(line['unit_cost']),
                          maxLines: 1, textAlign: TextAlign.end,
                          style: TextStyle(color: style.ink, fontSize: 10))),
                        Expanded(flex: 3, child: Text(
                          bpReferenceDecimalLabel(line['line_total']),
                          maxLines: 1, textAlign: TextAlign.end,
                          style: TextStyle(color: style.ink,
                            fontWeight: FontWeight.w900, fontSize: 10))),
                      ]),
                    ),
                    const Divider(height: 1),
                  ],
                ]),
              )
            else for (final line in serverLines)
              Padding(padding: const EdgeInsets.only(bottom: 7),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: style.card(radius: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEFFD),
                            borderRadius: BorderRadius.circular(9)),
                          child: const Icon(Icons.inventory_2_outlined,
                            color: Color(0xFF078DF3), size: 21)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          field(objectOf(line['product'])['name'], 'Product'),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w900, color: style.ink))),
                        if (draft && canEdit) ...[
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 31, minHeight: 31),
                            visualDensity: VisualDensity.compact,
                            onPressed: saving ? null : () => lineEditor(line),
                            icon: const Icon(Icons.edit_outlined, size: 18)),
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 31, minHeight: 31),
                            visualDensity: VisualDensity.compact,
                            onPressed: saving ? null : () => deleteLine(line),
                            icon: Icon(Icons.delete_outline, size: 18,
                              color: colors.error)),
                        ],
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: Text(
                          'Qty: ${field(line['quantity'])}',
                          style: TextStyle(fontSize: 10, color: style.muted))),
                        Expanded(child: Text(
                          'Rate: ${field(line['unit_cost'])}',
                          style: TextStyle(fontSize: 10, color: style.muted))),
                        Text(money(line['line_total'], widget.app.currency),
                          style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w900, color: style.ink)),
                      ]),
                      if (field(line['batch_number']).isNotEmpty)
                        Text('Batch: ${field(line['batch_number'])}',
                          style: TextStyle(fontSize: 10, color: style.muted)),
                    ]),
                )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: style.card(radius: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (document?['subtotal'] != null)
                    BpReferenceDetailLine(
                      label: 'Subtotal',
                      value: money(document?['subtotal'], widget.app.currency),
                      icon: Icons.calculate_outlined),
                  if (document?['discount_amount'] != null)
                    BpReferenceDetailLine(
                      label: 'Discount',
                      value: money(document?['discount_amount'],
                        widget.app.currency),
                      icon: Icons.discount_outlined),
                  if (document?['loading_amount'] != null)
                    BpReferenceDetailLine(
                      label: 'Loading',
                      value: money(document?['loading_amount'],
                        widget.app.currency),
                      icon: Icons.local_shipping_rounded),
                  if (document?['other_charges'] != null)
                    BpReferenceDetailLine(
                      label: 'Other Charges',
                      value: money(document?['other_charges'],
                        widget.app.currency),
                      icon: Icons.add_circle_outline),
                  if (document?['other_discount'] != null)
                    BpReferenceDetailLine(
                      label: 'Other Discount',
                      value: money(document?['other_discount'],
                        widget.app.currency),
                      icon: Icons.discount_rounded),
                  if (document?['freight_amount'] != null)
                    BpReferenceDetailLine(
                      label: 'Freight',
                      value: money(document?['freight_amount'],
                        widget.app.currency),
                      icon: Icons.local_shipping_outlined),
                  if (document?['tax_amount'] != null)
                    BpReferenceDetailLine(
                      label: 'Tax',
                      value: money(document?['tax_amount'],
                        widget.app.currency),
                      icon: Icons.percent_outlined),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7F8CF),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Expanded(child: Text('Grand Total',
                        style: TextStyle(fontWeight: FontWeight.w900))),
                      Text(money(document?['grand_total'],
                        widget.app.currency),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    ])),
                  if (field(document?['status']) == 'posted') ...[
                    BpReferenceDetailLine(
                      label: 'Paid', icon: Icons.payments_outlined,
                      value: money(document?['paid_amount'],
                        widget.app.currency)),
                    BpReferenceDetailLine(
                      label: 'Balance', icon: Icons.account_balance_wallet_outlined,
                      value: money(document?['balance_payable'],
                        widget.app.currency)),
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

          ],
        ],
        if (uncertainCreate) const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Draft request status uncertain. Use invoice history to reconcile.')),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 9),
          child: Text(error!, style: TextStyle(color: colors.error))),
        const SizedBox(height: 36),
          ],
        ),
      ]),
    );
  }
}
