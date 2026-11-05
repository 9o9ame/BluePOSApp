import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/sale_attempt.dart';
import 'receipt.dart';
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
  Map<String, dynamic>? selectedBankAccount;
  bool paymentDue = false;
  bool saving = false;
  bool attempted = false;
  String? attemptKey;
  Map<String, dynamic>? attemptPayload;
  String? error;
  final pendingStore = const SaleAttemptStore();

  @override
  void initState() { super.initState(); restorePending(); }

  Future<void> restorePending() async {
    final data = await pendingStore.read(
      userUlid: widget.app.currentUserUlid,
      tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
      branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
    );
    if (data != null && mounted) setState(() {
      attemptKey = data['key'] as String;
      attemptPayload = objectOf(data['payload']);
      attempted = true;
      error = 'An earlier invoice save is not confirmed. Retry safely before creating a new sale.';
    });
  }

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

  Future<void> pickBankAccount() async {
    if (attempted) return;
    try {
      final response = await widget.app.api.get('/api/sales/payment-accounts');
      final accounts = (response is List ? response : recordsOf(response))
          .map(objectOf)
          .where((account) => account['is_bank'] == true && field(account['ulid']).length == 26)
          .toList();
      if (!mounted) return;
      if (accounts.isEmpty) {
        await showApiError(context, 'No active bank account is available for card or bank payment.');
        return;
      }
      final chosen = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Text('Receiving bank account',
              style: Theme.of(ctx).textTheme.titleLarge)),
          ...accounts.map((account) => ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: Text(field(account['name'], 'Bank account')),
            subtitle: Text(field(account['code'])),
            onTap: () => Navigator.of(ctx).pop(account),
          )),
          const SizedBox(height: 12),
        ]),
      );
      if (mounted && chosen != null) setState(() => selectedBankAccount = chosen);
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
    if (saving || (lines.isEmpty && !attempted)) return;
    if (!attempted) {
      if (lines.any((l) => l.priceFor(priceMode) == '0')) {
        await showApiError(context, 'A product has no available price for the selected mode.'); return;
      }
      if (paymentDue && selectedCustomer == null) {
        await showApiError(context, 'Select a customer before marking Payment Due.'); return;
      }
      if (!paymentDue && paymentMethod != 'cash' && selectedBankAccount == null) {
        await showApiError(context, 'Select a receiving bank account for card or bank payment.');
        return;
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
          if (paymentMethod != 'cash') 'account_ulid': selectedBankAccount!['ulid'],
        },
      };
      attemptKey = AppController.newIdempotencyKey();
      attempted = true;
      try {
        await pendingStore.write(
          userUlid: widget.app.currentUserUlid,
          tenantUlid: field(objectOf(widget.app.session?['tenant'])['ulid']),
          branchUlid: field(objectOf(widget.app.session?['branch'])['ulid']),
          attemptKey: attemptKey!, payload: attemptPayload!,
        );
      } catch (e) {
        attempted = false; attemptPayload = null; attemptKey = null;
        if (mounted) await showApiError(context, 'Cannot securely save pending attempt: $e');
        return;
      }
    }
    setState(() { saving = true; error = null; });
    try {
      final raw = await widget.app.api.post('/api/sales', attemptPayload!, idempotencyKey: attemptKey);
      final obj = objectOf(raw);
      final sale = obj.containsKey('ulid') ? obj : objectOf(obj['data']);
      if (!mounted) return;
      await pendingStore.clear();
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
        actions: [
          OutlinedButton.icon(onPressed: field(sale['ulid']).length != 26 ? null : () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
              ReceiptScreen(app: widget.app, saleUlid: field(sale['ulid']))));
          }, icon: const Icon(Icons.receipt_long_outlined), label: const Text('Receipt')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('New sale')),
        ],
      ));
      if (mounted) setState(() {
        lines.clear(); payment.clear(); selectedCustomer = null;
        selectedBankAccount = null; paymentMethod = 'cash';
        paymentDue = false; attempted = false; attemptKey = null;
        attemptPayload = null; error = null;
      });
    } on ApiFailure catch (e) {
      if (!mounted) return;
      // A definitive authorization/validation rejection did not create the invoice.
      if (e.status == 422 || e.status == 403) await pendingStore.clear();
      if (!mounted) return;
      setState(() {
        error = e.message;
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
    final app = widget.app;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        const Expanded(child: SectionHeading('Sales Invoice')),
        IconButton(onPressed: attempted ? null : scan, tooltip: 'Scan barcode',
          icon: Icon(Icons.qr_code_scanner_rounded, color: scheme.primary)),
      ]),
      Surface(child: Column(children: [
        SegmentedButton<String>(segments: const [
          ButtonSegment(value:'default', label:Text('Default')),
          ButtonSegment(value:'retail', label:Text('Retail')),
          ButtonSegment(value:'wholesale', label:Text('Wholesale')),
        ], selected: {priceMode}, onSelectionChanged: attempted ? null :
          (mode) => setState(() => priceMode = mode.first)),
        const SizedBox(height: 11),
        ListTile(contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.person_outline, color: scheme.primary),
          title: Text(selectedCustomer == null ? 'Walk-in customer' : field(selectedCustomer!['name']),
            style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Customer · Tap to change'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: attempted ? null : pickCustomer),
        OutlinedButton.icon(onPressed: attempted ? null : pickProducts,
          icon: const Icon(Icons.search),
          label: const SizedBox(width: double.infinity, child: Text('Search product name or barcode'))),
      ])),
      const SizedBox(height: 18),
      SectionHeading('Cart (${lines.length})', trailing:
        TextButton.icon(onPressed: attempted ? null : pickProducts,
          icon: const Icon(Icons.add_circle_outline), label: const Text('Add'))),
      if (attempted && lines.isEmpty) Surface(child: Column(children: [
        const Icon(Icons.sync_problem, size: 35), const SizedBox(height: 10),
        const Text('Unconfirmed sale', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('The app recovered an interrupted save. Retry the same request before starting a new invoice.',
          textAlign: TextAlign.center),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: saving ? null : submit, icon: const Icon(Icons.sync),
          label: const Text('Retry original save')),
      ])),
      if (lines.isEmpty && !attempted) Surface(child: Column(children: [
        const SizedBox(height: 9),
        Icon(Icons.shopping_bag_outlined, color: scheme.primary, size: 45),
        const SizedBox(height: 8),
        const Text('Your cart is empty', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Scan barcode or search products', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: pickProducts, icon: const Icon(Icons.add),
          label: const Text('Find products')),
      ])),
      ...lines.map((line) => Padding(padding: const EdgeInsets.only(bottom: 10),
        child: Surface(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 43, height: 43, decoration: BoxDecoration(
                color: scheme.primaryContainer, borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.inventory_2_outlined, color: scheme.primary)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(line.name, style: const TextStyle(fontWeight: FontWeight.w800), maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                Text('${money(line.priceFor(priceMode), app.currency)} / ${line.unitLabel}',
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              ])),
              IconButton(onPressed: attempted ? null : () => setState(() => lines.remove(line)),
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error)),
            ]),
            const SizedBox(height: 11),
            Row(children: [
              IconButton.filledTonal(onPressed: attempted ? null : () {
                final quantity = Decimal.tryParse(line.qty) ?? Decimal.one;
                if (quantity > Decimal.one) setState(() => line.qty = (quantity - Decimal.one).toString());
              }, icon: const Icon(Icons.remove, size: 18)),
              const SizedBox(width: 8),
              SizedBox(width: 37, child: Text(line.qty,
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900))),
              const SizedBox(width: 8),
              IconButton.filledTonal(onPressed: attempted ? null : () {
                final quantity = Decimal.tryParse(line.qty) ?? Decimal.one;
                setState(() => line.qty = (quantity + Decimal.one).toString());
              }, icon: const Icon(Icons.add, size: 18)),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(money(line.estimate(priceMode), app.currency),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(line.discount == '0' ? 'Before tax' : 'Disc ${line.discount}% · Before tax',
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
              ]),
              IconButton(onPressed: attempted ? null : () => editLine(line),
                icon: Icon(Icons.edit_outlined, color: scheme.primary), tooltip: 'Edit quantity / discount'),
            ]),
          ])))),
      const SizedBox(height: 14),
      Surface(child: Column(children: [
        Row(children: [const Expanded(child: Text('Estimated item net',
          style: TextStyle(fontWeight: FontWeight.bold))),
          Text(money(estimatedSubtotal, app.currency),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 5),
        Text('Final tax, promotions, stock, invoice amounts and credit rules are calculated by BluePOS server.',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: lines.isEmpty || saving || attempted ? null : () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentScreen(sale: this))),
          icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Proceed to Payment')),
      ])),
      const SizedBox(height: 24),
    ]);
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.sale});
  final SaleScreenState sale;
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool complete = false;
  Future<void> submit() async {
    await widget.sale.submit();
    if (mounted) setState(() => complete = widget.sale.lines.isEmpty && !widget.sale.attempted);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sale;
    final scheme = Theme.of(context).colorScheme;
    final currency = s.widget.app.currency;
    return Scaffold(appBar: AppBar(title: const Text('Payment')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (complete) ...[
          Surface(child: Column(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 65),
            const SizedBox(height: 14),
            const Text('Invoice saved successfully', style: TextStyle(fontSize: 20,
              fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add), label: const Text('New sale')),
          ])),
        ] else ...[
          GradientHero(appearance: s.widget.app.appearance, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ESTIMATED ITEM NET', style: TextStyle(color: Colors.white70,
                fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 8),
              Text(money(s.estimatedSubtotal, currency), style: const TextStyle(color: Colors.white,
                fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('Server recalculates final tax and total on save.',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
          const SizedBox(height: 16),
          Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero,
              value: s.paymentDue, onChanged: s.attempted ? null :
                (v) => setState(() { s.paymentDue = v; }),
              title: const Text('Payment due / credit'),
              subtitle: const Text('Requires a customer with receivable account')),
            if (s.paymentDue) ListTile(contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(s.selectedCustomer == null ? 'Select customer' : field(s.selectedCustomer!['name'])),
              subtitle: const Text('Required for credit sale'),
              trailing: const Icon(Icons.chevron_right),
              onTap: s.attempted ? null : () async {
                await s.pickCustomer(); if (mounted) setState(() {});
              }),
            if (!s.paymentDue) ...[
              const SizedBox(height: 14),
              const Text('PAYMENT METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final choice in [('cash', Icons.payments_outlined, 'Cash'),
                  ('card', Icons.credit_card_outlined, 'Card'),
                  ('bank', Icons.account_balance_outlined, 'Bank')])
                  ChoiceChip(label: Text(choice.$3), avatar: Icon(choice.$2, size: 16),
                    selected: s.paymentMethod == choice.$1,
                    onSelected: s.attempted ? null : (_) => setState(() {
                      s.paymentMethod = choice.$1;
                      s.selectedBankAccount = null;
                    })),
              ]),
              if (s.paymentMethod != 'cash') ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.account_balance_rounded, color: scheme.primary),
                title: Text(s.selectedBankAccount == null ? 'Receiving bank account'
                  : field(s.selectedBankAccount!['name'])),
                subtitle: const Text('Select an authorized bank account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: s.attempted ? null : () async {
                  await s.pickBankAccount(); if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: s.payment, enabled: !s.attempted,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount received',
                  prefixIcon: Icon(Icons.payments_outlined))),
            ],
          ])),
          if (s.error != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(s.error!, style: TextStyle(color: scheme.error))),
          const SizedBox(height: 19),
          FilledButton.icon(onPressed: s.saving ? null : submit,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(s.saving ? 'Saving…' : s.attempted ? 'Retry original save safely' : 'Save Invoice')),
          const SizedBox(height: 10),
          Text('This action posts a real transaction and stock movement. Use an authorized test tenant for initial testing.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ]),
    );
  }
}
