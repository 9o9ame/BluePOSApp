import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key, required this.app});
  final AppController app;
  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  final search = TextEditingController();
  Timer? debounce;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> orders = const [];
  int serial = 0;

  @override
  void initState() { super.initState(); refresh(); }
  @override
  void dispose() { search.dispose(); debounce?.cancel(); super.dispose(); }

  Future<void> refresh() async {
    final current = ++serial;
    setState(() { loading = true; error = null; });
    try {
      final path = Uri(path: '/api/purchase-orders', queryParameters: {
        'per_page': '100',
        if (search.text.trim().isNotEmpty) 'q': search.text.trim(),
      }).toString();
      final raw = await widget.app.api.get(path);
      if (mounted && current == serial) setState(() => orders = recordsOf(raw));
    } catch (ex) {
      if (mounted && current == serial) setState(() => error = ex.toString());
    } finally {
      if (mounted && current == serial) setState(() => loading = false);
    }
  }

  Future<void> open([Map<String, dynamic>? row]) async {
    Map<String, dynamic>? full;
    if (row != null) {
      try {
        final ulid = field(row['ulid']);
        if (!validPublicUlid(ulid)) return;
        full = resourceOf(await widget.app.api.get('/api/purchase-orders/$ulid'));
      } catch (ex) {
        if (mounted) await showApiError(context, ex);
        return;
      }
    }
    if (!mounted) return;
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => PurchaseOrderEditor(app: widget.app, existing: full)));
    if (mounted && saved == true) await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canCreate = widget.app.hasPermission('purchases.create');
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders')),
      floatingActionButton: canCreate ? FloatingActionButton.extended(
        onPressed: () => open(), icon: const Icon(Icons.add_rounded),
        label: const Text('New Order')) : null,
      body: RefreshIndicator(onRefresh: refresh, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Supplier purchase orders'),
          TextField(controller: search,
            onChanged: (_) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 280), refresh);
            },
            decoration: const InputDecoration(
              hintText: 'Search order or supplier',
              prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 12),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: refresh)
          else if (orders.isEmpty) const EmptyState(
            title: 'No purchase orders',
            subtitle: 'Try another search or create an order.')
          else ...orders.map((order) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(onTap: () => open(order),
              child: Surface(padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Icon(Icons.assignment_outlined, color: colors.primary),
                  const SizedBox(width: 11),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(order['document_number']),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(field(objectOf(order['supplier'])['name']),
                      style: TextStyle(color: colors.onSurfaceVariant,
                        fontSize: 12)),
                    Text(field(order['order_date']),
                      style: const TextStyle(fontSize: 11)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(money(order['grand_total'], widget.app.currency),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(field(order['status']),
                      style: TextStyle(color: colors.primary, fontSize: 11)),
                  ]),
                ])),
            ),
          )),
          const SizedBox(height: 70),
        ],
      )),
    );
  }
}

class PurchaseOrderLineDraft {
  PurchaseOrderLineDraft({
    required this.product,
    required this.unit,
    this.quantity = '1',
    this.unitPrice = '0',
    this.discount = '0',
  });
  final Map<String, dynamic> product, unit;
  String quantity, unitPrice, discount;

  Map<String, dynamic> payload() => {
    'product_ulid': field(product['ulid']),
    'unit_ulid': field(unit['ulid']),
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount_percent': discount,
  };
}

class PurchaseOrderEditor extends StatefulWidget {
  const PurchaseOrderEditor({
    super.key, required this.app, this.existing,
  });
  final AppController app;
  final Map<String, dynamic>? existing;
  @override
  State<PurchaseOrderEditor> createState() => _PurchaseOrderEditorState();
}

class _PurchaseOrderEditorState extends State<PurchaseOrderEditor> {
  final notes = TextEditingController();
  final lines = <PurchaseOrderLineDraft>[];
  Map<String, dynamic>? supplier;
  bool busy = false, submissionUncertain = false;
  String? error;
  DateTime date = DateTime.now();
  bool get editing => widget.existing != null;
  bool get canEdit => widget.app.hasPermission(
    editing ? 'purchase_orders.edit' : 'purchases.create');
  String get ulid => field(widget.existing?['ulid']);

  @override
  void initState() {
    super.initState();
    supplier = objectOf(widget.existing?['supplier']);
    notes.text = field(widget.existing?['notes']);
    date = DateTime.tryParse(field(widget.existing?['order_date']))
      ?? DateTime.now();
    for (final item in recordsOf(widget.existing?['items'])) {
      final product = objectOf(item['product']);
      final unit = objectOf(item['unit']);
      if (validPublicUlid(field(product['ulid'])) &&
          validPublicUlid(field(unit['ulid']))) {
        lines.add(PurchaseOrderLineDraft(
          product: product, unit: unit,
          quantity: field(item['quantity'], '1'),
          unitPrice: field(item['unit_price'], '0'),
          discount: field(item['discount_percent'], '0'),
        ));
      }
    }
  }

  @override
  void dispose() { notes.dispose(); super.dispose(); }

  Future<void> chooseSupplier() async {
    final selection = await pickApiRecord(context, app: widget.app,
      title: 'Choose supplier', path: '/api/parties?type=vendor');
    if (!mounted || selection == null) return;
    setState(() => supplier = selection);
  }

  Future<void> addProduct() async {
    final chosen = await pickApiRecord(context, app: widget.app,
      title: 'Select product', path: '/api/products?per_page=100&active_only=1',
      subtitleKey: 'product_number');
    if (!mounted || chosen == null) return;
    final unit = objectOf(chosen['base_unit']);
    if (!validPublicUlid(field(unit['ulid']))) {
      await showApiError(context,
        'This product has no supported base unit.');
      return;
    }
    setState(() => lines.add(PurchaseOrderLineDraft(
      product: chosen, unit: unit)));
  }

  Future<void> editLine(PurchaseOrderLineDraft line) async {
    final qty = TextEditingController(text: line.quantity);
    final price = TextEditingController(text: line.unitPrice);
    final discount = TextEditingController(text: line.discount);
    try {
      final accepted = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: Text(field(line.product['name'])),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
            Text('Unit: ${field(line.unit['name'], field(line.unit['code']))}'),
            TextField(controller: qty,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity *')),
            TextField(controller: price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Unit price *')),
            TextField(controller: discount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Discount %')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
            FilledButton(onPressed: () {
              if (!validPositiveDecimal(qty.text.trim(), 6) ||
                  !validNonNegativeDecimal(price.text.trim(), 4) ||
                  !validNonNegativeDecimal(discount.text.trim(), 8)) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Enter valid quantity, price and discount.')));
                return;
              }
              Navigator.pop(ctx, true);
            }, child: const Text('Update')),
          ],
        ));
      if (accepted == true && mounted) {
        setState(() {
          line.quantity = qty.text.trim();
          line.unitPrice = price.text.trim();
          line.discount = discount.text.trim();
        });
      }
    } finally {
      qty.dispose(); price.dispose(); discount.dispose();
    }
  }

  Future<void> chooseDate() async {
    final chosen = await showDatePicker(context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
      initialDate: date);
    if (chosen != null && mounted) setState(() => date = chosen);
  }

  Future<void> save() async {
    if (busy || submissionUncertain || !canEdit) return;
    final id = field(supplier?['ulid']);
    if (!validPublicUlid(id) || lines.isEmpty ||
        lines.any((line) =>
          !validPublicUlid(field(line.product['ulid'])) ||
          !validPublicUlid(field(line.unit['ulid'])) ||
          !validPositiveDecimal(line.quantity, 6) ||
          !validNonNegativeDecimal(line.unitPrice, 4) ||
          !validNonNegativeDecimal(line.discount, 8))) {
      setState(() => error = 'Select a supplier and valid order lines.');
      return;
    }
    final payload = <String, dynamic>{
      'supplier_ulid': id,
      'order_date': isoLocalDate(date),
      'notes': notes.text.trim(),
      'items': lines.map((line) => line.payload()).toList(),
    };
    final accepted = await confirmMutation(context,
      title: editing ? 'Save order changes?' : 'Create purchase order?',
      warning: 'All amounts will be recomputed by the BluePOS server.',
      actionLabel: editing ? 'Save' : 'Create');
    if (!accepted || !mounted) return;

    setState(() { busy = true; error = null; });
    try {
      // Purchase Orders currently do not have an idempotent CREATE contract.
      // An ambiguous response must never trigger a blind second POST.
      if (editing) {
        await widget.app.api.patch('/api/purchase-orders/$ulid', payload);
      } else {
        submissionUncertain = true;
        await widget.app.api.post('/api/purchase-orders', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiFailure catch (ex) {
      if (!mounted) return;
      if (ex.status == 422 || ex.status == 403) {
        submissionUncertain = false;
      }
      setState(() => error = submissionUncertain
        ? 'Save status is uncertain. Check Purchase Orders history before trying again. Do not resend this order.'
        : ex.message);
    } catch (_) {
      if (mounted) setState(() => error =
        'Save status is uncertain. Check Purchase Orders history before trying again. Do not resend this order.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> cancel() async {
    if (!editing || busy || !widget.app.hasPermission('purchase_orders.cancel') ||
        field(widget.existing?['status']) != 'open') return;
    if (!await confirmMutation(context, title: 'Cancel purchase order?',
      warning: 'The server will cancel this open order. '
        'This action cannot be undone from the mobile app.',
      actionLabel: 'Cancel Order')) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.app.api.post('/api/purchase-orders/$ulid/cancel', {});
      if (mounted) Navigator.pop(context, true);
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final editable = canEdit && !busy && !submissionUncertain &&
      (!editing || field(widget.existing?['status']) == 'open');
    return Scaffold(
      appBar: AppBar(title: Text(editing
        ? field(widget.existing?['document_number'], 'Purchase Order')
        : 'New Purchase Order')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionHeading(editing ? 'Order details' : 'Purchase Order'),
        OutlinedButton.icon(onPressed: editable ? chooseDate : null,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text('Date: ${isoLocalDate(date)}')),
        const SizedBox(height: 9),
        Surface(child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.local_shipping_outlined, color: colors.primary),
          title: Text(field(supplier?['name'], 'Choose supplier')),
          subtitle: Text(field(supplier?['code'])),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: editable ? chooseSupplier : null)),
        const SizedBox(height: 12),
        SectionHeading('Products (${lines.length})'),
        if (editable) OutlinedButton.icon(onPressed: addProduct,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Add product')),
        if (lines.isEmpty) const EmptyState(
          title: 'No products selected',
          subtitle: 'Add a product and enter its quantity and unit price.'),
        for (final line in lines) Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Surface(padding: const EdgeInsets.all(10),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field(line.product['name']),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${line.quantity} ${field(line.unit['symbol'], field(line.unit['code']))}'
                    ' · Unit price ${line.unitPrice} · Discount ${line.discount}%',
                    style: TextStyle(fontSize: 11,
                      color: colors.onSurfaceVariant)),
                ])),
              if (editable) IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => editLine(line), tooltip: 'Edit line'),
              if (editable) IconButton(
                icon: Icon(Icons.close_rounded, color: colors.error),
                onPressed: () => setState(() => lines.remove(line)),
                tooltip: 'Remove line'),
            ]))),
        const SizedBox(height: 9),
        TextField(controller: notes, maxLines: 3, maxLength: 5000,
          readOnly: !editable,
          decoration: const InputDecoration(labelText: 'Notes')),
        if (editing) Surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Server total: ${money(widget.existing?['grand_total'], widget.app.currency)}',
            style: const TextStyle(fontWeight: FontWeight.w900)),
          Text('Status: ${field(widget.existing?['status'])}'),
        ])),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 10),
          child: Text(error!, style: TextStyle(color: colors.error))),
        if (submissionUncertain) const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Submission pending verification. Search the list before resubmitting.')),
        const SizedBox(height: 15),
        if (editable) FilledButton.icon(
          onPressed: save, icon: const Icon(Icons.save_outlined),
          label: Text(editing ? 'Save Changes' : 'Create Order')),
        if (editing && field(widget.existing?['status']) == 'open' &&
            widget.app.hasPermission('purchase_orders.cancel'))
          OutlinedButton.icon(onPressed: busy ? null : cancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Order')),
        const SizedBox(height: 30),
      ]),
    );
  }
}
