import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/appearance.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'history.dart';

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
      if (!mounted) return;
      setState(() {
        recent = salesEnabled ? recordsOf(result[0]) : const [];
        branchInvoices = salesEnabled ? int.tryParse(field(
          objectOf(objectOf(result[0])['meta'])['total'])) : null;
        productsCount = productsEnabled ? int.tryParse(field(
          objectOf(objectOf(result[1])['meta'])['total'])) : null;
        todayInvoices = salesEnabled ? int.tryParse(field(
          objectOf(objectOf(result[2])['meta'])['total'])) : null;
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

  Widget _statTile(String caption, String value, IconData icon,
      Color tint, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Colors.white, Color(0xFFF1F5FF)]),
        border: Border.all(color: Colors.white, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(
          color: Color(0x205F7BB3), blurRadius: 11,
          offset: Offset(0, 5))]),
      child: Row(children: [
        Container(width: 36, height: 38,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 22, color: tint)),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(caption, maxLines: 2,
              style: const TextStyle(fontSize: 11,
                color: Color(0xFF4D5C77))),
            Text(value, style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w900,
              color: Color(0xFF0A1A43))),
          ])),
      ])),
  );

  Widget _action(IconData icon, String caption, VoidCallback onPressed) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed, borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.symmetric(
        horizontal: 4, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [
            Colors.white, Color(0xFFF0F5FF)]),
          border: Border.all(color: Colors.white, width: 1.6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(
            color: Color(0x1E6684B6), blurRadius: 9,
            offset: Offset(0, 4))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 25, color: scheme.primary),
          ),
          const SizedBox(height: 9),
          Text(caption, maxLines: 2, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
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
    return RefreshIndicator(onRefresh: reload, child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18), children: [
        const SizedBox(height: 9),
        Row(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(app.appearance.corner)),
            child: Icon(Icons.storefront_rounded,
              color: scheme.onTertiaryContainer, size: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(DateTime.now().hour), style: TextStyle(
                color: scheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 2),
              Text(app.tenantName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 21,
                  color: Color(0xFF0A1B48), fontWeight: FontWeight.w900)),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.receipt_long_outlined, color: Colors.white),
                SizedBox(width: 9),
                Expanded(child: Text("Today's invoices",
                  style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 14),
              if (busy)
                const CircularProgressIndicator(color: Colors.white)
              else Text(error != null ? '—' : todayInvoices?.toString() ?? '—',
                style: const TextStyle(color: Colors.white, fontSize: 34,
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('Current branch • live invoice count',
                style: TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
        ],
        if (canViewSales || canViewProducts) ...[
          const SizedBox(height: 16),
          const Text('Business at a glance',
            style: TextStyle(fontSize: 17,
              color: Color(0xFF0A1B48), fontWeight: FontWeight.w900)),
          if (busy) pageLoading()
        else if (error != null) FailureState(message: error!, retry: reload)
        else Row(children: [
          if (canViewSales)
            Expanded(child: _statTile('All invoices',
              branchInvoices?.toString() ?? '—',
              Icons.receipt_long_rounded,
              const Color(0xFF087EF5), _sales)),
          if (canViewSales && canViewProducts)
            const SizedBox(width: 9),
          if (canViewProducts)
            Expanded(child: _statTile('Products',
              productsCount?.toString() ?? '—',
              Icons.inventory_2_rounded,
              const Color(0xFFFF9813), () => widget.navigate(2))),
        ]),
        ],
        if (canCreateSale || canViewProducts || canViewSales) ...[
        const SizedBox(height: 16),
        const SectionHeading('Quick actions'),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width < 355 ? 2 : 3,
          childAspectRatio: MediaQuery.sizeOf(context).width < 355 ? 1.12 : 1.07,
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
              _action(Icons.analytics_outlined, 'Reports',
                () => widget.navigate(3)),
            ],
          ],
        ),
        ],
        if (canViewSales) const SizedBox(height: 17),
        if (canViewSales) SectionHeading('Recent invoices',
          trailing: TextButton(onPressed: _sales,
            child: const Text('View all'))),
        if (canViewSales && !busy && error == null)
          if (recent.isEmpty) const EmptyState(title: 'No invoices yet')
          else ...recent.take(5).map((item) => Padding(
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
    ));
  }
}
