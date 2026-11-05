import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'products.dart';
import 'scanner.dart';

class CartLine {
  CartLine(this.product, {this.barcode});
  final Map<String, dynamic> product;
  final String? barcode;
  String qty = '1';
  String discount = '0';
  String get ulid => field(product['ulid']);
  String get name => field(product['name'], 'Product');
  String? get baseUnitUlid => field(objectOf(product['base_unit'])['ulid']).isEmpty
      ? null : field(objectOf(product['base_unit'])['ulid']);
  String get unitLabel => field(objectOf(product['base_unit'])['symbol'], 'PCS');

  String priceFor(String mode) {
    final prices = recordsOf(product['prices']);
    final type = mode == 'wholesale' ? 'wholesale' : 'retail';
    for (final p in prices) {
      if (p['price_type'] == type && p['is_active'] != false) {
        return field(p['amount'], '0');
      }
    }
    return '0';
  }

  Decimal estimate(String mode) {
    final q = Decimal.tryParse(qty) ?? Decimal.zero;
    final p = Decimal.tryParse(priceFor(mode)) ?? Decimal.zero;
    final d = Decimal.tryParse(discount) ?? Decimal.zero;
    final gross = p * q;
    final result = gross - (gross * d / Decimal.fromInt(100)).toDecimal(scaleOnInfinitePrecision: 4);
    return result < Decimal.zero ? Decimal.zero : result;
  }

  Map<String, dynamic> payload() => {
    'product_ulid': ulid,
    if (barcode != null) 'barcode': barcode,
    if (barcode == null && baseUnitUlid != null) 'unit_ulid': baseUnitUlid,
    'quantity': Decimal.parse(qty).toStringAsFixed(6),
    if ((Decimal.tryParse(discount) ?? Decimal.zero) > Decimal.zero)
      'discount_percent': Decimal.parse(discount).toStringAsFixed(8),
  };
}

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key, required this.app});
  final AppController app;
  @override
  State<SaleScreen> createState() => SaleScreenState();
}

class SaleScreenState extends State<SaleScreen> {
  final List<CartLine> lines = [];
  final payment = TextEditingController();
  String priceMode = 'default';
  String paymentMethod = 'cash';
  Map<String, dynamic>? selectedCustomer;
  bool paymentDue = false;
  bool saving = false;
  bool attempted = false;
  String? attemptKey;
  Map<String, dynamic>? attemptPayload;
  String? error;

  @override
  void dispose() { payment.dispose(); super.dispose(); }

  void addProduct(Map<String, dynamic> product, {String? scanned}) {
    if (attempted) return;
    final ulid = field(product['ulid']);
    if (ulid.length != 26) return;
    setState(() {
      final match = lines.where((l) => l.ulid == ulid && l.barcode == scanned);
      if (match.isNotEmpty) {
        final old = Decimal.tryParse(match.first.qty) ?? Decimal.one;
        match.first.qty = (old + Decimal.one).toString();
      } else {
        lines.add(CartLine(product, barcode: scanned));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${field(product['name'])} added to cart'), duration: const Duration(seconds: 1)));
  }

  Future<void> pickProducts() async {
    if (attempted) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      useSafeArea: true, showDragHandle: true,
      builder: (modal) => FractionallySizedBox(heightFactor: 0.91,
        child: ProductsScreen(app: widget.app, onAdd: (product) {
          addProduct(product); Navigator.of(modal).pop();
        })));
  }

  Future<void> scan() async {
    if (attempted) return;
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;
    try {
      final path = Uri(path:'/api/products/lookup-existing', queryParameters: {'barcode': barcode.trim()}).toString();
      final result = await widget.app.api.get(path);
      final p = objectOf(result);
      final product = p.containsKey('ulid') ? p : objectOf(p['data']);
      if (!mounted) return;
      if (field(product['ulid']).length != 26) {
        await showApiError(context, 'No matching product for this barcode.');
      } else {
        addProduct(product, scanned: barcode.trim());
      }
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> pickCustomer() async {
    if (attempted) return;
    try {
      final response = await widget.app.api.get('/api/parties?type=customer');
      final customers = recordsOf(response);
      if (!mounted) return;
      final customer = await showModalBottomSheet<Map<String, dynamic>>(
        context: context, isScrollControlled: true, showDragHandle: true,
        builder: (ctx) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(ctx).height * .7,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('Select customer',
              style: Theme.of(ctx).textTheme.titleLarge)),
            ListTile(title: const Text('Walk-in customer'), leading: const Icon(Icons.person_outline),
              onTap: () => Navigator.of(ctx).pop(<String, dynamic>{})),
            Expanded(child: ListView.builder(itemCount: customers.length, itemBuilder: (ctx, i) {
              final c = customers[i];
              return ListTile(title: Text(field(c['name'], 'Customer')),
                subtitle: Text(field(c['code'])),
                onTap: () => Navigator.of(ctx).pop(c));
            })),
          ]))));
      if (customer != null && mounted) setState(() => selectedCustomer = customer.isEmpty ? null : customer);
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  Future<void> editLine(CartLine line) async {
    if (attempted) return;
    final qty = TextEditingController(text: line.qty);
    final disc = TextEditingController(text: line.discount);
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(line.name),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Base unit: ${line.unitLabel}', style: Theme.of(ctx).textTheme.bodySmall),
        const SizedBox(height: 12),
        TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Sales quantity')),
        const SizedBox(height: 12),
        TextField(controller: disc, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Discount %')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final q = Decimal.tryParse(qty.text.trim());
          final d = Decimal.tryParse(disc.text.trim());
          final allowDecimals = objectOf(line.product['base_unit'])['allows_decimal'] != false;
          final integerQty = RegExp(r'^\d+$').hasMatch(qty.text.trim());
          if (q == null || q <= Decimal.zero || d == null || d < Decimal.zero || d > Decimal.fromInt(100)
              || !RegExp(r'^\d+(\.\d{1,6})?$').hasMatch(qty.text.trim())
              || !RegExp(r'^\d+(\.\d{1,8})?$').hasMatch(disc.text.trim())
              || (!allowDecimals && !integerQty)) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid quantity and discount.')));
            return;
          }
          Navigator.of(ctx).pop(true);
        }, child: const Text('Update'))],
    ));
    if (!mounted) { qty.dispose(); disc.dispose(); return; }
    if (result == true) setState(() { line.qty = qty.text.trim(); line.discount = disc.text.trim(); });
    qty.dispose(); disc.dispose();
  }

  Decimal get estimatedSubtotal {
    var sum = Decimal.zero;
    for (final line in lines) { sum += line.estimate(priceMode); }
    return sum;
  }

  Future<void> submit() async {
    if (saving || lines.isEmpty) return;
    if (!attempted) {
      if (lines.any((l) => l.priceFor(priceMode) == '0')) {
        await showApiError(context, 'A product has no available price for the selected mode.'); return;
      }
      if (paymentDue && selectedCustomer == null) {
        await showApiError(context, 'Select a customer before marking Payment Due.'); return;
      }
      final amt = Decimal.tryParse(payment.text.trim());
      if (!paymentDue && (amt == null || amt <= Decimal.zero ||
          !RegExp(r'^\d+(\.\d{1,4})?$').hasMatch(payment.text.trim()))) {
        await showApiError(context, 'Enter a positive received amount (up to 4 decimals).'); return;
      }
      attemptPayload = {
        'price_type': priceMode,
        'items': lines.map((l) => l.payload()).toList(),
        if (selectedCustomer != null) 'customer_ulid': selectedCustomer!['ulid'],
        'payment_due': paymentDue,
        if (!paymentDue) 'initial_payment': {
          'amount': Decimal.parse(payment.text.trim()).toStringAsFixed(4),
          'method': paymentMethod,
        },
      };
      attemptKey = AppController.newIdempotencyKey();
      attempted = true;
    }
    setState(() { saving = true; error = null; });
    try {
      final raw = await widget.app.api.post('/api/sales', attemptPayload!, idempotencyKey: attemptKey);
      final obj = objectOf(raw);
      final sale = obj.containsKey('ulid') ? obj : objectOf(obj['data']);
      if (!mounted) return;
      await showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10),
          Expanded(child: Text('Sale completed'))]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Invoice: ${field(sale['document_number'], 'Saved')}'),
          const SizedBox(height: 8),
          Text('Net: ${money(sale['grand_total'])}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('Paid: ${money(sale['paid_amount'])}'),
          Text('Balance: ${money(sale['balance_due'])}'),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('New sale'))],
      ));
      if (mounted) setState(() {
        lines.clear(); payment.clear(); selectedCustomer = null;
        paymentDue = false; attempted = false; attemptKey = null;
        attemptPayload = null; error = null;
      });
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.message;
        // A rejected validation request did not post; allow fixing the draft.
        if (e.status == 422 || e.status == 403) {
          attempted = false; attemptPayload = null; attemptKey = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      SectionHeading('Sales invoice', trailing: IconButton(onPressed: attempted ? null : scan,
        tooltip: 'Scan barcode', icon: const Icon(Icons.qr_code_scanner))),
      Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Price mode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 9),
        SegmentedButton<String>(segments: const [
          ButtonSegment(value:'default', label:Text('Default')),
          ButtonSegment(value:'retail', label:Text('Retail')),
          ButtonSegment(value:'wholesale', label:Text('Wholesale')),
        ], selected: {priceMode}, onSelectionChanged: attempted ? null : (s) => setState(() => priceMode = s.first)),
        const SizedBox(height: 10),
        ListTile(contentPadding: EdgeInsets.zero, onTap: attempted ? null : pickCustomer,
          title: Text(selectedCustomer == null ? 'Walk-in customer' : field(selectedCustomer!['name'])),
          subtitle: const Text('Tap to select a customer'),
          leading: const Icon(Icons.person_outline), trailing: const Icon(Icons.chevron_right)),
      ])),
      const SizedBox(height: 16),
      SectionHeading('${lines.length} items', trailing: TextButton.icon(onPressed: attempted ? null : pickProducts,
        icon: const Icon(Icons.add_circle_outline), label: const Text('Add product'))),
      if (lines.isEmpty) Surface(child: Column(children: [
        const SizedBox(height: 12),
        const Icon(Icons.shopping_basket_outlined, size: 44),
        const SizedBox(height: 10),
        const Text('Your cart is empty'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: pickProducts, icon: const Icon(Icons.search), label: const Text('Find products')),
      ])),
      ...lines.map((line) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Surface(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(line.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            IconButton(onPressed: attempted ? null : () => setState(() => lines.remove(line)),
              tooltip: 'Remove', icon: Icon(Icons.delete_outline, color: scheme.error)),
          ]),
          Text('${line.qty} ${line.unitLabel} × ${money(line.priceFor(priceMode))}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 5),
          Row(children: [
            Expanded(child: Text('Disc ${line.discount}% • Est. ${money(line.estimate(priceMode))}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
            TextButton.icon(onPressed: attempted ? null : () => editLine(line),
              icon: const Icon(Icons.edit_outlined, size: 17), label: const Text('Edit')),
          ]),
        ])))),
      const SizedBox(height: 16),
      SectionHeading('Payment'),
      Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Estimated items net'),
          Text(money(estimatedSubtotal), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        const SizedBox(height: 5),
        Text('Illustrative only; tax, schemes, stock and final totals are calculated by the server.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
        const Divider(height: 24),
        SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: paymentDue,
          onChanged: attempted ? null : (v) => setState(() => paymentDue = v),
          title: const Text('Payment due / credit'), subtitle: const Text('Customer required')),
        if (!paymentDue) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(initialValue: paymentMethod,
            decoration: const InputDecoration(labelText: 'Payment method'),
            items: const [
              DropdownMenuItem(value:'cash', child:Text('Cash')),
              DropdownMenuItem(value:'card', child:Text('Card')),
              DropdownMenuItem(value:'bank', child:Text('Bank transfer')),
            ], onChanged: attempted ? null : (value) => setState(() => paymentMethod = value ?? 'cash')),
          const SizedBox(height: 12),
          TextField(controller: payment, enabled: !attempted,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount received', prefixIcon: Icon(Icons.payments_outlined))),
        ],
      ])),
      if (error != null) ...[
        const SizedBox(height: 16),
        Text(error!, style: TextStyle(color: scheme.error)),
        if (attempted) const Text('Save result is unconfirmed. Retry uses the SAME idempotency key and payload. Do not create a new sale.',
            style: TextStyle(fontSize: 12)),
      ],
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: lines.isEmpty || saving ? null : submit,
        icon: const Icon(Icons.check_circle_outline),
        label: Text(saving ? 'Saving securely…' : attempted ? 'Retry save safely' : 'Save sale')),
      const SizedBox(height: 24),
    ]);
  }
}
