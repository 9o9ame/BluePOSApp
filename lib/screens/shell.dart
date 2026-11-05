import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'history.dart';
import 'dashboard.dart';
import 'modules.dart';
import 'products.dart';
import 'reports.dart';
import 'sale.dart';
import 'settings.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.app});
  final AppController app;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;
  final saleKey = GlobalKey<SaleScreenState>();
  late final List<Widget> pages = [
    DashboardScreen(app: widget.app, navigate: navigate),
    SaleScreen(key: saleKey, app: widget.app),
    ProductsScreen(app: widget.app, onAdd: (product) {
      saleKey.currentState?.addProduct(product);
      navigate(1);
    }),
    ReportsScreen(app: widget.app),
    MoreScreen(app: widget.app, navigate: navigate),
  ];
  static const titles = ['Home', 'POS Sale', 'Products', 'Reports', 'Modules'];
  void navigate(int i) => setState(() => selected = i);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 55,
        leading: Padding(padding: const EdgeInsets.only(left: 15, top: 6, bottom: 6),
          child: const BlueposBrandMark(size: 40)),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BluePOS', style: TextStyle(color: scheme.onSurface,
            fontWeight: FontWeight.w900, fontSize: 17)),
          Text('${app.branchName} • ${titles[selected]}', maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        ]),
        actions: [
          IconButton(tooltip: 'Refresh page', icon: const Icon(Icons.refresh_outlined),
            onPressed: () => setState(() {
              pages[selected] = switch (selected) {
                0 => DashboardScreen(app: app, navigate: navigate),
                2 => ProductsScreen(app: app, onAdd: (p) { saleKey.currentState?.addProduct(p); navigate(1); }),
                3 => ReportsScreen(app: app),
                _ => pages[selected],
              };
            })),
          IconButton(tooltip: 'Settings', icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
              Scaffold(appBar: AppBar(title: const Text('Settings')),
                body: SettingsScreen(app: app))))),
          const SizedBox(width: 7),
        ],
      ),
      body: IndexedStack(index: selected, children: pages),
      bottomNavigationBar: SafeArea(top: false, child: Container(
        decoration: BoxDecoration(color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .045),
            offset: const Offset(0, -6), blurRadius: 14)]),
        child: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: navigate,
          backgroundColor: Colors.transparent,
          indicatorColor: scheme.primary,
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: app.appearance.density == 'compact' ? 62 : 71,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: Colors.white), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart_rounded, color: Colors.white), label: 'POS'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: Colors.white), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: Colors.white), label: 'Reports'),
            NavigationDestination(icon: Icon(Icons.apps_outlined),
              selectedIcon: Icon(Icons.apps_rounded, color: Colors.white), label: 'Modules'),
          ],
        ),
      )),
    );
  }
}

void openSales(BuildContext context, AppController app) => Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => DataListScreen(app: app,
    title: 'Sales invoices', path: '/api/sales?per_page=25',
    nameKey: 'document_number', subtitleKey: 'sale_date',
    amountKey: 'grand_total', detailPrefix: '/api/sales')));

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.app, required this.navigate});
  final AppController app;
  final ValueChanged<int> navigate;

  @override
  Widget build(BuildContext context) =>
      ModulesScreen(app: app, navigate: navigate);
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.app});
  final AppController app;
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}
class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> rows = [];
  bool busy = true; String? error;
  @override
  void initState() {super.initState(); load();}
  Future<void> load() async {
    setState(() {busy = true; error = null;});
    try {
      final warehouse = field(objectOf(widget.app.session?['warehouse'])['ulid']);
      if (warehouse.length != 26) throw const ApiFailure('WAREHOUSE', 'No active warehouse.', 0);
      final response = await widget.app.api.get(Uri(path: '/api/inventory/stock',
        queryParameters: {'warehouse_ulid':warehouse, 'per_page':'50'}).toString());
      if (mounted) setState(() => rows = recordsOf(response));
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(appBar: AppBar(title: const Text('Warehouse Stock'),
      actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          GradientHero(appearance: widget.app.appearance, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warehouse_outlined, color: Colors.white, size: 30),
              const SizedBox(height: 12),
              Text(widget.app.warehouseName, style: const TextStyle(color: Colors.white,
                fontSize: 23, fontWeight: FontWeight.w900)),
              const Text('Stock quantities are provided by BluePOS API',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            ])),
          const SizedBox(height: 16),
          if (busy) pageLoading() else if (error != null) FailureState(message: error!, retry: load)
          else if (rows.isEmpty) const EmptyState(title: 'No warehouse balances')
          else ...rows.map((balance) {
            final product = objectOf(balance['product']);
            return Padding(padding: const EdgeInsets.only(bottom: 9), child: Surface(
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(
                  color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.inventory_2_outlined, color: scheme.primary)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(field(product['name']), style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(field(product['product_number']), style: TextStyle(fontSize: 11,
                    color: scheme.onSurfaceVariant)),
                ])),
                Text(field(balance['quantity']), style: const TextStyle(fontWeight: FontWeight.w900)),
              ])));
          }),
        ])));
  }
}
