import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api.dart';
import '../core/sale_attempt.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
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
    dateKey: 'return_date', referenceStyle: true,
    createPermission: kind.createPermission,
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
  final supplierReference = TextEditingController();
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
    reason.dispose(); notes.dispose(); supplierReference.dispose();
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
        supplierReference.text = field(fetched['supplier_reference']);
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
    if (!validPublicUlid(sourceUlid)) { return; }
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
        !widget.app.hasPermission(widget.kind.createPermission)) { return; }
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
        if (widget.kind == ReturnDocumentKind.purchase)
          'supplier_reference': supplierReference.text.trim(),
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
          if (mounted) { setState(() => error =
            'Cannot securely store this return request. No request was sent.'); }
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
      if (mounted) { setState(() => error = createUncertain
        ? widget.kind == ReturnDocumentKind.sale
          ? 'Return draft status unknown. Retry the saved request with the same idempotency key.'
          : 'Purchase Return creation status unknown. Search history before another create.'
        : ex.message); }
    } catch (_) {
      if (mounted) { setState(() => error =
        'Return draft status unknown. Check documents before another attempt.'); }
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
        if (widget.kind == ReturnDocumentKind.purchase)
          'supplier_reference': supplierReference.text.trim(),
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
        !validPublicUlid(sourceUlid)) { return; }
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
                    if (sheet.mounted) { change(() {
                      ambiguous = ex.status == 0 || ex.status >= 500;
                      formError = ambiguous
                        ? 'Line save unconfirmed. Close and refresh before retrying.'
                        : ex.message;
                    }); }
                  } catch (_) {
                    if (sheet.mounted) { change(() {
                      ambiguous = true;
                      formError = 'Line save unconfirmed. Reload before retrying.';
                    }); }
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
      actionLabel: 'Remove')) { return; }
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
        recordsOf(document?['lines']).isEmpty) { return; }
    if (!await confirmMutation(context,
      title: 'Post ${widget.kind.title}?',
      warning: 'The server will validate returnable quantities and update '
        'stock using its existing append-only inventory flow.',
      actionLabel: 'Post Return')) { return; }
    setState(() => saving = true);
    try {
      await widget.app.api.post('${widget.kind.path}/$id/post', {});
      await refresh();
    } catch (ex) {
      if (mounted) {
        await refresh();
        if (mounted) { setState(() => error =
          'Return posting status uncertain. Check current status first. $ex'); }
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> printPostedReturn() async {
    if (!created || draft || saving) return;
    setState(() => saving = true);
    try {
      // Server response remains the source of truth for all figures.
      final data = objectOf(document);
      final pdf = pw.Document(title: 'BluePOS Purchase Return');
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Header(level: 0, child: pw.Text('BluePOS — Purchase Return')),
          pw.Text('Document: ${field(data['document_number'])}'),
          pw.Text('Date: ${field(data['return_date'])}'),
          pw.Text('Supplier: ${field(objectOf(data['supplier'])['name'])}'),
          pw.Text('Status: ${field(data['status'])}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Product', 'Return qty', 'Rate', 'Amount'],
            data: recordsOf(data['lines']).map((line) => [
              field(objectOf(line['product'])['name']),
              field(line['quantity']), field(line['unit_cost']),
              field(line['line_total']),
            ]).toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Server total: ${field(data['grand_total'])}'),
          if (field(data['notes']).isNotEmpty)
            pw.Text('Notes: ${field(data['notes'])}'),
        ],
      ));
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'Purchase Return ${field(data['document_number'])}');
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
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
    final style = BpReferenceStyle.of(context);
    final isSale = widget.kind == ReturnDocumentKind.sale;
    final canCreate = widget.app.hasPermission(widget.kind.createPermission);
    final detailData = objectOf(document);
    final sourceData = objectOf(source);
    final partyKey = isSale ? 'customer' : 'supplier';
    final partyNameKey = isSale ? 'customer_name' : 'supplier_name';
    final partyName = field(objectOf(detailData[partyKey])['name'],
      field(objectOf(sourceData[partyKey])['name'],
        field(sourceData[partyNameKey], 'From posted invoice')));
    return Scaffold(
      backgroundColor: style.page,
      appBar: BpReferenceSubpageAppBar(title: created
        ? isSale ? 'Sales Return Detail' : 'Purchase Return Detail'
        : isSale ? 'Create Sales Return' : 'Create Purchase Return'),
      bottomNavigationBar: !loading &&
          ((!created && canCreate) ||
           (created && draft && (editable || canPost)))
        ? BpReferenceWorkflowActions(
          leftKey: const ValueKey('return-save-draft'),
          rightKey: const ValueKey('return-post'),
          leftLabel: created ? 'Save Draft'
            : createUncertain ? 'Retry Saved Draft' : 'Create Draft',
          rightLabel: 'Post Return',
          rightIcon: Icons.assignment_return_rounded,
          onLeft: saving ||
              (createUncertain && !isSale) ? null
              : !created ? createDraft
              : draft && editable ? saveHeader : null,
          onRight: saving || !created || !draft ||
              !canPost || lines.isEmpty ? null : post)
        : created && !draft &&
            widget.kind == ReturnDocumentKind.purchase
          ? BpReferenceWorkflowActions(
              leftLabel: 'Print', rightLabel: 'Posted',
              leftIcon: Icons.print_outlined,
              rightIcon: Icons.verified_rounded,
              onLeft: saving ? null : printPostedReturn,
              onRight: null,
            )
          : null,
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        ListView(
          key: const ValueKey('reference-return-editor'),
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 40),
          children: [
        if (loading) pageLoading()
        else ...[
          Row(children: [
            Expanded(child: BpReferenceCompactField(
              label: 'Return No.', icon: Icons.description_outlined,
              value: field(document?['document_number'], 'Assigned by server'))),
            const SizedBox(width: 7),
            Expanded(child: BpReferenceCompactField(
              label: isSale ? 'Customer' : 'Supplier',
              icon: Icons.person_rounded,
              value: partyName)),
          ]),
          const SizedBox(height: 7),
          Row(children: [
            Expanded(child: BpReferenceCompactField(
              label: 'Reference Invoice',
              icon: Icons.receipt_long_outlined,
              value: field(source?['document_number'],
                field(objectOf(document?[widget.kind.sourceField])
                  ['document_number'])),
              hint: 'Choose posted invoice',
              onTap: !created && !createUncertain ? chooseSource : null)),
            const SizedBox(width: 7),
            Expanded(child: BpReferenceCompactField(
              label: 'Return Date', icon: Icons.calendar_month_outlined,
              value: isoLocalDate(date),
              onTap: canEditNow ? chooseDate : null)),
          ]),
          const SizedBox(height: 7),
          BpReferenceFormField(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Reason (optional)', hint: 'Enter return reason',
            controller: reason, maxLength: 255, readOnly: !canEditNow),
          BpReferenceFormField(
            icon: Icons.notes_outlined,
            label: 'Notes (optional)', hint: 'Enter remarks',
            controller: notes, maxLength: 5000, maxLines: 2,
            readOnly: !canEditNow),
          if (!isSale)
            BpReferenceFormField(
              icon: Icons.tag_outlined,
              label: 'Supplier Reference (optional)',
              hint: 'Supplier return reference',
              controller: supplierReference, maxLength: 100,
              readOnly: !canEditNow),
          if (!created && available.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text(
                'Returnable Items (${available.length})',
                style: TextStyle(fontWeight: FontWeight.w900,
                  color: style.ink, fontSize: 13))),
              Text('Server quantities', style: TextStyle(
                color: style.muted, fontSize: 10)),
            ]),
            const SizedBox(height: 6),
            for (final item in available)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  decoration: style.card(radius: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 9),
                  child: Row(children: [
                    Container(width: 31, height: 33,
                      decoration: BoxDecoration(
                        color: style.scheme.primary.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.inventory_2_outlined,
                        color: style.scheme.primary, size: 18)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      field(objectOf(item['product'])['name'], 'Product'),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800,
                        color: style.ink, fontSize: 11))),
                    const SizedBox(width: 8),
                    Text('Max: ${field(item[
                      isSale ? 'remaining_returnable_quantity'
                        : 'remaining_returnable_base_quantity'], '0')}',
                      style: TextStyle(color: style.muted,
                        fontWeight: FontWeight.w800, fontSize: 10)),
                  ]),
                )),
            const SizedBox(height: 7),
            Text('Create the draft to choose return quantities; posting stays on the server.',
              style: TextStyle(color: style.muted, fontSize: 10)),
          ],
          if (created && !isSale && !draft) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: style.card(radius: 13),
              child: Row(children: [
                Icon(Icons.inventory_2_outlined, color: style.green),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Posted purchase return — stock processed by BluePOS',
                  style: TextStyle(color: style.ink,
                    fontWeight: FontWeight.w800, fontSize: 11))),
                Icon(Icons.check_circle_rounded, color: style.green),
              ]),
            ),
            const SizedBox(height: 8),
          ],
          if (created) ...[
            if (widget.kind == ReturnDocumentKind.purchase) ...[
              Surface(child: Row(children: [
                Icon(Icons.assignment_return_outlined,
                  color: palette.primary),
                const SizedBox(width: 11),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(document?['document_number'], 'Purchase Return'),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('Status: ${field(document?['status'], 'Unknown')}',
                      style: TextStyle(color: palette.onSurfaceVariant)),
                    Text('Original: ${field(source?['document_number'], 'Not available')}',
                      style: TextStyle(color: palette.onSurfaceVariant)),
                  ])),
              ])),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: SectionHeading('Returned Items (${lines.length})')),
              if (canEditNow)
                OutlinedButton.icon(
                  key: const ValueKey('return-add-item'),
                  onPressed: () => editLine(),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Add Item',
                    style: TextStyle(fontSize: 11))),
            ]),
            if (lines.isEmpty) const EmptyState(
              title: 'No return lines',
              subtitle: 'Choose a remaining line from the original document.')
            else for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: style.card(radius: 13),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EAFF),
                          borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.inventory_2_rounded,
                          color: Color(0xFF067DDF), size: 20)),
                      const SizedBox(width: 9),
                      Expanded(child: Text(
                        field(objectOf(line['product'])['name'], 'Product'),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5,
                          fontWeight: FontWeight.w900, color: style.ink))),
                      if (canEditNow) ...[
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 31, minHeight: 31),
                          onPressed: () => editLine(line),
                          icon: const Icon(Icons.edit_outlined, size: 18)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 31, minHeight: 31),
                          onPressed: () => deleteLine(line),
                          icon: Icon(Icons.delete_outline, size: 18,
                            color: palette.error)),
                      ],
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      Expanded(child: Text('Qty: ${field(line['quantity'])}',
                        style: TextStyle(fontSize: 10, color: style.muted))),
                      if (line['unit_cost'] != null)
                        Expanded(child: Text(
                          'Rate: ${field(line['unit_cost'])}',
                          style: TextStyle(fontSize: 10, color: style.muted))),
                      Text(money(line['line_total'], widget.app.currency),
                        style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w900, color: style.ink)),
                    ]),
                  ]),
                )),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: style.card(radius: 13),
              child: Column(children: [
                if (document?['subtotal'] != null)
                  BpReferenceDetailLine(
                    label: 'Subtotal',
                    icon: Icons.calculate_outlined,
                    value: money(document?['subtotal'], widget.app.currency)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF6CF),
                    borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Expanded(child: Text('Return Total',
                      style: TextStyle(fontWeight: FontWeight.w900))),
                    Text(money(document?['grand_total'],
                      widget.app.currency),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  ])),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Server status: ${field(document?['status'])}',
                    style: TextStyle(color: style.muted, fontSize: 11))),
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

          ],
        ],
        if (createUncertain) const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text('Unconfirmed draft: do not generate another request.')),
        if (error != null) Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(error!, style: TextStyle(color: palette.error))),
        const SizedBox(height: 35),
          ],
        ),
      ]),
    );
  }
}
