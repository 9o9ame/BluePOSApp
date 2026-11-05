import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'history.dart';
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
                body: SettingsScreen(app: app)))),
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
              selectedIcon: Icon(Icons.apps_rounded, color: Colors.white), label: 'More'),
          ],
        ),
      )),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.app, required this.navigate});
  final AppController app;
  final ValueChanged<int> navigate;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;
  String? error;
  int? salesCount;
  int? productCount;
  List<Map<String, dynamic>> recent = [];
  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait([
        widget.app.api.get('/api/sales?per_page=5'),
        widget.app.api.get('/api/products?per_page=1'),
      ]);
      if (!mounted) return;
      final sales = objectOf(results[0]);
      final products = objectOf(results[1]);
      setState(() {
        salesCount = int.tryParse(field(objectOf(sales['meta'])['total']));
        productCount = int.tryParse(field(objectOf(products['meta'])['total']));
        recent = recordsOf(sales);
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    return RefreshIndicator(onRefresh: refresh, child: ListView(
      padding: EdgeInsets.all(app.appearance.spacing), children: [
        Padding(padding: const EdgeInsets.only(top: 7, bottom: 15), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GOOD TO SEE YOU', style: TextStyle(fontSize: 10,
              letterSpacing: 1.8, fontWeight: FontWeight.bold, color: scheme.primary)),
            const SizedBox(height: 3),
            Text(app.userName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            Text('${app.branchName}  •  ${app.warehouseName}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ])),
          CircleAvatar(backgroundColor: scheme.primaryContainer, radius: 25,
            child: Text(app.userName.isEmpty ? 'BP' : app.userName.substring(0, 1).toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary))),
        ])),
        GradientHero(appearance: app.appearance, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.storefront_rounded, color: Colors.white70),
              const Spacer(), const Icon(Icons.shield_outlined, color: Colors.white70, size: 21)]),
            const SizedBox(height: 12),
            Text(app.tenantName, style: const TextStyle(fontWeight: FontWeight.w900,
              fontSize: 26, color: Colors.white)),
            const Text('Secure, live business workspace', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: () => widget.navigate(1),
                style: FilledButton.styleFrom(backgroundColor: Colors.white,
                  foregroundColor: app.appearance.accent),
                icon: const Icon(Icons.add_shopping_cart_rounded), label: const Text('New Sale'))),
            ]),
          ],
        )),
        const SizedBox(height: 19),
        const SectionHeading('Business at a glance'),
        if (loading) pageLoading()
        else if (error != null) FailureState(message: error!, retry: refresh)
        else Row(children: [
          Expanded(child: BpStatCard(icon: Icons.receipt_long_outlined,
            caption: 'Invoices', value: '${salesCount ?? '—'}', hint: 'Current branch')),
          const SizedBox(width: 10),
          Expanded(child: BpStatCard(icon: Icons.inventory_2_outlined,
            caption: 'Products', value: '${productCount ?? '—'}', hint: 'Authorized catalog')),
        ]),
        const SizedBox(height: 19),
        const SectionHeading('Quick actions'),
        GridView.count(crossAxisCount: 4, childAspectRatio: .75, mainAxisSpacing: 8,
          crossAxisSpacing: 8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            BpModuleTile(icon: Icons.point_of_sale_outlined, name: 'New Sale', onTap: () => widget.navigate(1)),
            BpModuleTile(icon: Icons.inventory_2_outlined, name: 'Products', onTap: () => widget.navigate(2)),
            BpModuleTile(icon: Icons.warehouse_outlined, name: 'Stock', onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen(app: app)))),
            BpModuleTile(icon: Icons.bar_chart_rounded, name: 'Reports', onTap: () => widget.navigate(3)),
          ]),
        const SizedBox(height: 17),
        SectionHeading('Recent invoices', trailing: TextButton(onPressed: () => openSales(context, app),
          child: const Text('View all'))),
        if (!loading && error == null) ...recent.take(4).map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 9), child: Surface(child: Row(children: [
            CircleAvatar(backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.receipt_outlined, color: scheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(field(row['document_number']), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(field(row['sale_date']), style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(money(row['grand_total'], app.currency), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(field(row['status']), style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
            ]),
          ])))),
        const SizedBox(height: 12),
      ],
    ));
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
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    final items = <(String, IconData, VoidCallback)>[
      ('Sales invoices', Icons.receipt_long_outlined, () => openSales(context, app)),
      ('Purchases', Icons.shopping_bag_outlined, () => open(DataListScreen(app: app,
        title:'Purchases', path:'/api/purchases?per_page=25', nameKey:'document_number',
        subtitleKey:'purchase_date', amountKey:'grand_total'))),
      ('Warehouse stock', Icons.warehouse_outlined, () => open(InventoryScreen(app: app))),
      ('Customers', Icons.people_alt_outlined, () => open(DataListScreen(app: app,
        title:'Customers', path:'/api/parties?type=customer', nameKey:'name', subtitleKey:'code'))),
      ('Suppliers', Icons.local_shipping_outlined, () => open(DataListScreen(app: app,
        title:'Suppliers', path:'/api/parties?type=vendor', nameKey:'name', subtitleKey:'code'))),
      ('Sales due', Icons.pending_actions_outlined, () => open(DataListScreen(app: app,
        title:'Outstanding invoices', path:'/api/sales?due_only=1&per_page=25',
        nameKey:'document_number', subtitleKey:'customer_name',
        amountKey:'balance_due', detailPrefix:'/api/sales'))),
      ('Expenses', Icons.wallet_outlined, () => open(DataListScreen(app: app,
        title:'Expenses', path:'/api/sales/expenses?per_page=25',
        nameKey:'document_number', subtitleKey:'expense_date', amountKey:'amount'))),
      ('Product sales', Icons.query_stats_outlined, () => open(DataListScreen(app: app,
        title:'Product-wise sales', path:'/api/sales/product-wise?per_page=25',
        nameKey:'sale_number', subtitleKey:'sale_date', amountKey:'net_amount'))),
      ('Reports', Icons.bar_chart_outlined, () => navigate(3)),
      ('Appearance', Icons.palette_outlined, () => open(Scaffold(
        appBar: AppBar(title: const Text('Settings')), body: SettingsScreen(app: app)))),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SectionHeading('Business modules'),
      Text('Everything in one secure workspace. Features depend on your account permissions.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      const SizedBox(height: 14),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .92),
        itemBuilder: (_, index) { final item = items[index]; return BpModuleTile(
          icon: item.$2, name: item.$1, onTap: item.$3); }),
      const SizedBox(height: 18),
      Surface(child: ListTile(leading: const Icon(Icons.shield_outlined),
        title: const Text('Secure tenancy & device access'),
        subtitle: Text('${app.tenantName} • ${app.branchName}'),
      )),
    ]);
  }
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
