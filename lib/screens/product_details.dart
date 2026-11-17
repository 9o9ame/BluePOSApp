import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import '../widgets/product_thumb.dart';
import 'product_editor.dart';
import 'notifications.dart';
import 'auth_reference_chrome.dart';

/// Screen 13: read-only product details from the server-authorized ULID route.
/// Financial and stock fields are displayed only when returned by the API.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key, required this.app, required this.productUlid,
  });

  final AppController app;
  final String productUlid;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? product;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(widget.productUlid)) {
        throw const ApiFailure('INVALID_PRODUCT', 'Invalid product reference.', 422);
      }
      final response = objectOf(
        await widget.app.api.get('/api/products/${widget.productUlid}'));
      final data = objectOf(response['data']);
      if (mounted) setState(() => product = data.isNotEmpty ? data : response);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit() async {
    final current = product;
    if (current == null || !widget.app.hasPermission('products.edit')) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) =>
        ProductEditor(app: widget.app, product: current)));
    if (updated == true && mounted) await load();
  }

  Future<void> printBarcode() async {
    final current = product;
    final code = field(current?['primary_barcode']);
    if (current == null || code.isEmpty) return;
    try {
      final document = pw.Document();
      document.addPage(pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(field(current['name']),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 15),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: code, width: 210, height: 72),
              pw.SizedBox(height: 8),
              pw.Text(code, style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ));
      await Printing.layoutPdf(onLayout: (_) async => document.save());
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BpReferenceStyle.of(context).page,
    appBar: BpReferenceSubpageAppBar(
      title: 'Product Detail',
      onNotifications: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) =>
          NotificationsScreen(app: widget.app))),
    ),
    body: loading
      ? const Center(child: CircularProgressIndicator())
      : error != null
        ? FailureState(message: error!, retry: load)
        : Stack(children: [
            const Positioned(top: 0, right: 0,
              child: BpReferenceTopAccent()),
            const Positioned(left: 0, right: 0, bottom: 0,
              child: AuthReferenceWaves(height: 75)),
            RefreshIndicator(
              onRefresh: load,
              child: ProductDetailsView(
                product: product ?? const {},
                api: widget.app.api,
                currency: widget.app.currency,
                canEdit: widget.app.hasPermission('products.edit'),
                canViewPurchaseRate: widget.app.hasPermission('products.edit'),
                onEdit: edit,
                onPrintBarcode: printBarcode,
              ),
            ),
          ]),
  );
}


class ProductDetailsView extends StatelessWidget {
  const ProductDetailsView({
    super.key,
    required this.product,
    required this.api,
    required this.currency,
    this.canEdit = false,
    this.canViewPurchaseRate = false,
    this.onEdit,
    this.onPrintBarcode,
  });

  final Map<String, dynamic> product;
  final BlueposApi api;
  final String currency;
  final bool canEdit;
  final bool canViewPurchaseRate;
  final VoidCallback? onEdit;
  final VoidCallback? onPrintBarcode;

  String _display(dynamic value) {
    final result = field(value);
    return result.isEmpty ? 'Not available' : result;
  }

  dynamic get _retail {
    for (final p in recordsOf(product['prices'])) {
      if (p['price_type'] == 'retail' && p['is_active'] != false) {
        return p['amount'];
      }
    }
    return null;
  }

  Widget _detail(BuildContext context, String title, String value,
      IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 27, height: 27,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 17, color: scheme.primary)),
        const SizedBox(width: 9),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(title, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800)))),
        const SizedBox(width: 8),
        Flexible(child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value, textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 11.5),
            maxLines: 3, overflow: TextOverflow.ellipsis))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    final scheme = Theme.of(context).colorScheme;
    final stock = objectOf(product['sales_lookup'])['in_stock'];
    final price = _retail;
    final purchase = product['purchase_rate'];
    final reorder = product['reorder_level'];
    final barcode = field(product['primary_barcode']);
    final status = product['is_active'];
    return ListView(
      key: const ValueKey('product-detail-page'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(11, 12, 11, 95),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: style.card(radius: 18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: style.input,
                  borderRadius: BorderRadius.circular(14)),
                child: ProductThumb(api: api,
                  imageUrl: field(product['image_url']), size: 78)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_display(product['name']),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: style.ink,
                      fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('SKU: ${_display(product['sku'])}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: style.muted, fontSize: 11)),
                  const SizedBox(height: 5),
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: (status == true ? style.green : scheme.error)
                          .withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(9)),
                      child: Text(status == true ? '✓ Active' : 'Inactive',
                        style: TextStyle(fontSize: 10.5,
                          color: status == true ? style.green : scheme.error,
                          fontWeight: FontWeight.w800))),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: style.green.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(9)),
                    child: Text(stock == null
                        ? 'Stock not shown' : 'Stock: ${field(stock)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5,
                        color: style.green, fontWeight: FontWeight.w800))),
                ])),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(price == null ? 'Price unavailable'
                    : money(price, currency).replaceFirst('PKR ', 'Rs '),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: style.ink,
                      fontWeight: FontWeight.w900, fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: style.card(),
          child: Column(children: [
            _detail(context, 'Category',
              _display(objectOf(product['category'])['name']),
              Icons.category_rounded),
            Divider(height: 1, color: style.line),
            _detail(context, 'Brand',
              _display(objectOf(product['brand'])['name']),
              Icons.sell_rounded),
            Divider(height: 1, color: style.line),
            _detail(context, 'Unit',
              _display(objectOf(product['base_unit'])['name']),
              Icons.inventory_2_outlined),
            if (canViewPurchaseRate && purchase != null) ...[
              Divider(height: 1, color: style.line),
              _detail(context, 'Purchase Price', money(purchase, currency),
                Icons.payments_rounded),
            ],
            Divider(height: 1, color: style.line),
            _detail(context, 'Sale Price',
              price == null ? 'Price unavailable' : money(price, currency),
              Icons.sell_rounded),
            Divider(height: 1, color: style.line),
            _detail(context, 'Barcode',
              barcode.isEmpty ? 'Not available' : barcode,
              Icons.qr_code_rounded),
            Divider(height: 1, color: style.line),
            _detail(context, 'Stock in Hand',
              stock == null ? 'Stock not shown' : field(stock),
              Icons.warehouse_rounded),
            if (field(product['description']).isNotEmpty) ...[
              Divider(height: 1, color: style.line),
              _detail(context, 'Description',
                field(product['description']), Icons.description_rounded),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: style.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.bar_chart_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Price & Stock', style: TextStyle(
                  color: style.ink, fontWeight: FontWeight.w900,
                  fontSize: 14)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Stock', style: TextStyle(
                      color: style.muted, fontSize: 11)),
                    const SizedBox(height: 3),
                    Text(stock == null ? 'Not available' : field(stock),
                      style: TextStyle(color: style.green,
                        fontSize: 20, fontWeight: FontWeight.w900)),
                  ])),
                if (reorder != null) ...[
                  Container(height: 43, width: 1, color: style.line),
                  const SizedBox(width: 15),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reorder Level', style: TextStyle(
                        color: style.muted, fontSize: 11)),
                      const SizedBox(height: 3),
                      Text(field(reorder), style: TextStyle(
                        color: style.ink, fontSize: 20,
                        fontWeight: FontWeight.w900)),
                    ])),
                ],
              ]),
            ],
          ),
        ),
        if ((canEdit && onEdit != null) ||
            (onPrintBarcode != null && barcode.isNotEmpty)) ...[
          const SizedBox(height: 22),
          Row(children: [
            if (canEdit && onEdit != null)
              Expanded(child: OutlinedButton.icon(
                key: const ValueKey('product-detail-edit'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              )),
            if (canEdit && onEdit != null &&
                onPrintBarcode != null && barcode.isNotEmpty)
              const SizedBox(width: 9),
            if (onPrintBarcode != null && barcode.isNotEmpty)
              Expanded(child: FilledButton.icon(
                key: const ValueKey('product-detail-print-barcode'),
                onPressed: onPrintBarcode,
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Print Barcode'),
              )),
          ]),
        ],
      ],
    );
  }

}
