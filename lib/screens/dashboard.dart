import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'history.dart';
import 'auth_reference_chrome.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key, required this.app, required this.navigate,
  });
  final AppController app;
  final ValueChanged<int> navigate;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool busy = true;
  String? error;
  int? todayInvoices;
  int? branchInvoices;
  int? productsCount;
  String? todaySalesGross;
  String? yesterdaySalesGross;
  String? itemsSold;
  List<Map<String, dynamic>> recent = const [];

  @override
  void initState() { super.initState(); reload(); }

  String _greeting(int hour) => hour < 12
      ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

  String _date(DateTime date) =>
    date.year.toString().padLeft(4, '0') + '-' +
    date.month.toString().padLeft(2, '0') + '-' +
    date.day.toString().padLeft(2, '0');

  Future<void> reload() async {
    setState(() { busy = true; error = null; });
    try {
      final today = _date(DateTime.now());
      final yesterday = _date(DateTime.now().subtract(const Duration(days: 1)));
      final canViewSales = widget.app.hasPermission('sales.view');
      final canViewProducts = widget.app.hasPermission('products.view') ||
          widget.app.hasPermission('products.manage');
      final features = objectOf(widget.app.session?['entitlements'])['features'];
      final salesEnabled = canViewSales &&
          (features is! List || features.contains('sales'));
      final productsEnabled = canViewProducts &&
          (features is! List || features.contains('catalog'));
      // Only request module data when the server session allows that module.
      final result = await Future.wait<dynamic>([
        if (salesEnabled) widget.app.api.get('/api/sales?per_page=5')
          else Future.value(<String, dynamic>{}),
        if (productsEnabled) widget.app.api.get('/api/products?per_page=1')
          else Future.value(<String, dynamic>{}),
        if (salesEnabled) widget.app.api.get('/api/sales?per_page=1&date_from=' +
          today + '&date_to=' + today)
          else Future.value(<String, dynamic>{}),
      ]);
      String? gross;
      String? priorGross;
      String? soldQuantity;
      final allowedReport = salesEnabled &&
          widget.app.hasPermission('reports.accounting') &&
          widget.app.hasPermission('reports.inventory') &&
          (features is! List || features.contains('inventory'));
      if (allowedReport) {
        try {
          final daily = objectOf(await widget.app.api.get(
            '/api/reports/daily/activity-summary?from=$today&to=$today'));
          final previous = objectOf(await widget.app.api.get(
            '/api/reports/daily/activity-summary?from=$yesterday&to=$yesterday'));
          gross = field(objectOf(daily['totals'])['sale']);
          priorGross = field(objectOf(previous['totals'])['sale']);
          Decimal quantity = Decimal.zero;
          for (final document in recordsOf(daily['documents'])) {
            if (field(document['type']) != 'sale') continue;
            for (final line in recordsOf(document['lines'])) {
              final value = Decimal.tryParse(field(line['quantity']));
              if (value != null) quantity += value;
            }
          }
          soldQuantity = quantity.toString();
        } catch (_) {
          // Permission-restricted or unavailable report; never invent totals.
        }
      }
      if (!mounted) return;
      setState(() {
        recent = salesEnabled ? recordsOf(result[0]) : const [];
        branchInvoices = salesEnabled ? int.tryParse(field(
          objectOf(objectOf(result[0])['meta'])['total'])) : null;
        productsCount = productsEnabled ? int.tryParse(field(
          objectOf(objectOf(result[1])['meta'])['total'])) : null;
        todayInvoices = salesEnabled ? int.tryParse(field(
          objectOf(objectOf(result[2])['meta'])['total'])) : null;
        // No invoices on the requested date proves zero sale invoices;
        // otherwise never infer money or quantities from paginated listings.
        todaySalesGross = gross?.isNotEmpty == true
          ? gross : (todayInvoices == 0 ? '0.0000' : null);
        yesterdaySalesGross = priorGross?.isNotEmpty == true
          ? priorGross : null;
        itemsSold = soldQuantity ?? (todayInvoices == 0 ? '0' : null);
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _sales() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => DataListScreen(
      app: widget.app, title: 'Sales invoices',
      path: '/api/sales?per_page=25',
      nameKey: 'document_number', subtitleKey: 'sale_date',
      amountKey: 'grand_total', detailPrefix: '/api/sales',
    ),
  ));

  String _formatAmount(String raw) {
    final value = Decimal.tryParse(raw);
    if (value == null) return raw;
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts.first;
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '$buf.${parts.last}';
  }

  String _comparisonLabel() {
    final today = Decimal.tryParse(todaySalesGross ?? '');
    final yesterday = Decimal.tryParse(yesterdaySalesGross ?? '');
    if (today == null || yesterday == null || yesterday == Decimal.zero) {
      return '—';
    }
    final percent = (((today - yesterday) * Decimal.fromInt(100)) / yesterday)
        .toDecimal(scaleOnInfinitePrecision: 2);
    final sign = percent >= Decimal.zero ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }

  Widget _statTile(String caption, String value, IconData icon,
      Color tint, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Colors.white, Color(0xFFF1F5FF)]),
        border: Border.all(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x205F7BB3), blurRadius: 11,
          offset: Offset(0, 5))]),
      child: Row(children: [
        Container(width: 44, height: 47,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 26, color: tint)),
        const SizedBox(width: 9),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(caption, maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(value, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface)),
          ])),
      ])),
  );

  Widget _action(IconData icon, String caption, VoidCallback onPressed) {
    final tone = switch (caption) {
      'New Sale' => const Color(0xFF087FF4),
      'Products' => const Color(0xFFF2930D),
      'Invoices' => const Color(0xFF8150EE),
      _ => const Color(0xFF08AF79),
    };
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 5, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            tone.withValues(alpha: .095),
            Colors.white,
          ]),
          border: Border.all(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [BoxShadow(
            color: Color(0x1D5777B1),
            blurRadius: 10, offset: Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: tone),
            const SizedBox(height: 11),
            Text(caption, textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13.5,
                fontWeight: FontWeight.w900)),
          ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final scheme = Theme.of(context).colorScheme;
    final features = objectOf(app.session?['entitlements'])['features'];
    bool enabled(String key) => features is! List || features.contains(key);
    final canViewSales = enabled('sales') && app.hasPermission('sales.view');
    final canCreateSale = enabled('sales') && app.hasPermission('sales.create');
    final canViewProducts = enabled('catalog') &&
        (app.hasPermission('products.view') || app.hasPermission('products.manage'));
    return Stack(children: [
      RefreshIndicator(onRefresh: reload, child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 100), children: [
        const SizedBox(height: 9),
        Row(children: [
          Container(width: 55, height: 55,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF5E6), Color(0xFFFFE6C5)]),
              borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.storefront_rounded,
              color: Color(0xFFFF9813), size: 29)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(DateTime.now().hour), style: TextStyle(
                color: scheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 2),
              Text(app.tenantName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 21,
                  color: scheme.onSurface, fontWeight: FontWeight.w900)),
              Text('${app.branchName} • ${app.warehouseName}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11,
                  color: scheme.onSurfaceVariant)),
            ],
          )),
        ]),
        if (canViewSales) ...[
          const SizedBox(height: 18),
          Container(width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0BBD88), Color(0xFF00A86D),
                  Color(0xFF008B69)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: const [BoxShadow(
                color: Color(0x3300A47B),
                blurRadius: 14, offset: Offset(0, 7))],
              borderRadius: BorderRadius.circular(app.appearance.corner + 8)),
            child: Stack(children: [
              Positioned(right: 0, top: 0, bottom: 0,
                child: Opacity(opacity: .4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final h in [22.0, 32.0, 45.0, 60.0])
                        Container(
                          width: 11, height: h,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFE4FFF7), Color(0xFF3CE7B1)]),
                            borderRadius: BorderRadius.circular(5))),
                    ]))),
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Sales",
                    style: TextStyle(
                      color: Colors.white, fontSize: 19,
                      fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(todaySalesGross == null
                      ? 'Rs —'
                      : 'Rs ${_formatAmount(todaySalesGross!)}',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 31,
                      fontWeight: FontWeight.w900)),
                  const SizedBox(height: 9),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF19C64F),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(_comparisonLabel(),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w800))),
                    const SizedBox(width: 8),
                    const Text('vs yesterday',
                      style: TextStyle(
                        color: Colors.white, fontSize: 12)),
                  ]),
                ]),
            ]),
          ),
        ],
        if (canViewSales) ...[
          const SizedBox(height: 15),
          if (busy) pageLoading()
          else if (error != null) FailureState(message: error!, retry: reload)
          else Column(children: [
            Row(children: [
              Expanded(child: _statTile('Invoices',
                branchInvoices?.toString() ?? '—',
                Icons.description_rounded,
                const Color(0xFF087EF5), _sales)),
              const SizedBox(width: 10),
              Expanded(child: _statTile('Items Sold',
                itemsSold ?? '—',
                Icons.inventory_2_rounded,
                const Color(0xFFFF9813), _sales)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _statTile('Collections',
                '—', Icons.verified_rounded,
                const Color(0xFF0DBB64), _sales)),
              const SizedBox(width: 10),
              Expanded(child: _statTile('Expenses',
                '—', Icons.receipt_long_rounded,
                const Color(0xFFEA3864), _sales)),
            ]),
          ]),
        ],
        if (canCreateSale || canViewProducts || canViewSales) ...[
        const SizedBox(height: 17),
        Text('Quick Actions', style: TextStyle(
          color: scheme.onSurface, fontSize: 19,
          fontWeight: FontWeight.w900)),
        GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1.06,
          mainAxisSpacing: 8, crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (canCreateSale)
              _action(Icons.point_of_sale_outlined, 'New Sale',
                () => widget.navigate(1)),
            if (canViewProducts)
              _action(Icons.inventory_2_outlined, 'Products',
                () => widget.navigate(2)),
            if (canViewSales) ...[
              _action(Icons.receipt_long_outlined, 'Invoices', _sales),
            ],
          ],
        ),
        ],
        if (canViewSales && recent.isNotEmpty) const SizedBox(height: 17),
        if (canViewSales && recent.isNotEmpty) SectionHeading('Recent invoices',
          trailing: TextButton(onPressed: _sales,
            child: const Text('View all'))),
        if (canViewSales && !busy && error == null && recent.isNotEmpty)
          ...recent.take(5).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(padding: const EdgeInsets.symmetric(
              horizontal: 13, vertical: 12),
              child: Row(children: [
                CircleAvatar(backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.receipt_long_rounded,
                    color: scheme.primary, size: 20)),
                const SizedBox(width: 11),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(item['document_number'], 'Invoice'),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(field(item['sale_date']),
                      style: TextStyle(fontSize: 11,
                        color: scheme.onSurfaceVariant)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(money(item['grand_total'], app.currency),
                    style: const TextStyle(fontWeight: FontWeight.w900,
                      fontSize: 12)),
                  Text(field(item['status']),
                    style: TextStyle(fontSize: 10,
                      color: scheme.onSurfaceVariant)),
                ]),
              ]),
            )),
          ),
        const SizedBox(height: 16),
      ],
    )),
      const Positioned(left: 0, right: 0, bottom: 0,
        child: IgnorePointer(
          child: AuthReferenceWaves(height: 55))),
    ]);
  }
}
