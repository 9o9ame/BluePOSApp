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
    DashboardScreen(app: widget.app, navigate: (index) => setState(() => selected = index)),
    SaleScreen(key: saleKey, app: widget.app),
    ProductsScreen(app: widget.app, onAdd: (product) {
      saleKey.currentState?.addProduct(product);
      setState(() => selected = 1);
    }),
    ReportsScreen(app: widget.app),
    MoreScreen(app: widget.app),
  ];
  static const titles = ['Dashboard', 'New sale', 'Products', 'Reports', 'More'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Row(children: [
        Container(width: 33, height: 33, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: widget.app.appearance.accent),
          child: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 20)),
        const SizedBox(width: 9),
        Text('BluePOS', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Text(titles[selected], style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ]), actions: [
        IconButton(onPressed: () => setState(() => selected = 4),
          tooltip: 'More', icon: const Icon(Icons.account_circle_outlined)),
      ]),
      body: IndexedStack(index: selected, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => setState(() => selected = index),
        height: widget.app.appearance.density == 'compact' ? 69 : 76,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Sale'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.apps), label: 'More'),
        ],
      ),
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
    setState(() {loading = true; error = null;});
    try {
      // Both KPIs are counts returned by the server for the active context.
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
        Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            Text(app.userName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            Text('${app.branchName} • ${app.warehouseName}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ])),
          CircleAvatar(radius: 24, backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.person_rounded, color: scheme.primary)),
        ])),
        GradientHero(appearance: app.appearance, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('YOUR BUSINESS, IN YOUR POCKET',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.1, fontSize: 10,
                color: Colors.white70)),
            const SizedBox(height: 13),
            Text(app.tenantName, style: const TextStyle(fontSize: 24,
              fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Quick sales · Inventory · Live records',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: () => widget.navigate(1),
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: app.appearance.accent),
              icon: const Icon(Icons.add_circle_outline), label: const Text('New sale')),
          ],
        )),
        const SizedBox(height: 20),
        const SectionHeading('Workspace overview'),
        if (loading) pageLoading()
        else if (error != null) Surface(child: Column(children: [
          Text('Some overview data is unavailable: $error', style: TextStyle(color: scheme.error)),
          TextButton(onPressed: refresh, child: const Text('Retry')),
        ]))
        else Row(children: [
          Expanded(child: _KpiCard(icon: Icons.receipt_long_outlined, label: 'Sales invoices', value: '$salesCount')),
          const SizedBox(width: 10),
          Expanded(child: _KpiCard(icon: Icons.inventory_2_outlined, label: 'Products', value: '$productCount')),
        ]),
        const SizedBox(height: 18),
        const SectionHeading('Quick access'),
        GridView.count(crossAxisCount: 3, childAspectRatio: 1.03,
          mainAxisSpacing: 10, crossAxisSpacing: 10, physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true, children: [
            _QuickTile(icon: Icons.point_of_sale_outlined, title: 'New sale', onTap: () => widget.navigate(1)),
            _QuickTile(icon: Icons.inventory_2_outlined, title: 'Products', onTap: () => widget.navigate(2)),
            _QuickTile(icon: Icons.query_stats_outlined, title: 'Reports', onTap: () => widget.navigate(3)),
            _QuickTile(icon: Icons.account_balance_wallet_outlined, title: 'Invoice history', onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => DataListScreen(app: app,
                title:'Sales history', path:'/api/sales?per_page=25', nameKey:'document_number',
                subtitleKey:'sale_date', amountKey:'grand_total', detailPrefix:'/api/sales')))),
            _QuickTile(icon: Icons.warehouse_outlined, title: 'Stock', onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryScreen(app: app)))),
            _QuickTile(icon: Icons.tune, title: 'Appearance', onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Appearance')), body: SettingsScreen(app: app))))),
          ]),
        const SizedBox(height: 20),
        SectionHeading('Recent invoices', trailing: TextButton(onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => DataListScreen(app: app,
            title:'Sales history', path:'/api/sales?per_page=25', nameKey:'document_number',
            subtitleKey:'sale_date', amountKey:'grand_total', detailPrefix:'/api/sales'))), child: const Text('View all'))),
        if (!loading && error == null) ...recent.take(3).map((invoice) => Padding(
          padding: const EdgeInsets.only(bottom: 10), child: Surface(child: Row(children: [
            Icon(Icons.receipt_outlined, color: scheme.primary), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(field(invoice['document_number']), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(field(invoice['sale_date']), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ])),
            Text(money(invoice['grand_total']), style: const TextStyle(fontWeight: FontWeight.w800)),
          ])))),
        const SizedBox(height: 18),
      ],
    ));
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 12),
    Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
    Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]));
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap,
    borderRadius: BorderRadius.circular(14), child: Surface(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
      ],
    )));
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.app});
  final AppController app;

  @override
  Widget build(BuildContext context) {
    void open(Widget child) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => child));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SectionHeading('Business modules'),
      Surface(child: Column(children: [
        ListTile(leading: const Icon(Icons.receipt_long_outlined), title: const Text('Sales history'),
          trailing: const Icon(Icons.chevron_right), onTap: () => open(DataListScreen(app: app,
            title:'Sales history', path:'/api/sales?per_page=25', nameKey:'document_number',
            subtitleKey:'sale_date', amountKey:'grand_total', detailPrefix:'/api/sales'))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.local_shipping_outlined), title: const Text('Purchases'),
          trailing: const Icon(Icons.chevron_right), onTap: () => open(DataListScreen(app: app,
            title:'Purchases', path:'/api/purchases?per_page=25', nameKey:'document_number',
            subtitleKey:'purchase_date', amountKey:'grand_total'))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.warehouse_outlined), title: const Text('Warehouse stock'),
          trailing: const Icon(Icons.chevron_right), onTap: () => open(InventoryScreen(app: app))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.people_alt_outlined), title: const Text('Customers'),
          trailing: const Icon(Icons.chevron_right), onTap: () => open(DataListScreen(app: app,
            title:'Customers', path:'/api/parties?type=customer', nameKey:'name', subtitleKey:'code'))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.handshake_outlined), title: const Text('Suppliers'),
          trailing: const Icon(Icons.chevron_right), onTap: () => open(DataListScreen(app: app,
            title:'Suppliers', path:'/api/parties?type=vendor', nameKey:'name', subtitleKey:'code'))),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.bar_chart_outlined), title: const Text('Product-wise sales'),
          trailing: const Icon(Icons.chevron_right), onTap: () => open(DataListScreen(app: app,
            title:'Product-wise sales', path:'/api/sales/product-wise?per_page=25',
            nameKey:'sale_number', subtitleKey:'sale_date', amountKey:'net_amount'))),
      ])),
      const SizedBox(height: 20),
      const SectionHeading('Personalization'),
      Surface(child: ListTile(leading: const Icon(Icons.palette_outlined),
        title: const Text('Theme & appearance'), subtitle: const Text('Theme, font, accent, density & more'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => open(Scaffold(appBar: AppBar(title: const Text('Settings')),
          body: SettingsScreen(app: app))))),
      const SizedBox(height: 20),
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
  bool busy = true;
  String? error;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() {busy = true; error = null;});
    try {
      final warehouse = field(objectOf(widget.app.session?['warehouse'])['ulid']);
      if (warehouse.length != 26) throw const ApiFailure('MISSING_WAREHOUSE', 'No active warehouse.', 0);
      final path = Uri(path:'/api/inventory/stock', queryParameters:
        {'per_page':'50', 'warehouse_ulid':warehouse}).toString();
      final result = await widget.app.api.get(path);
      if (mounted) setState(() => rows = recordsOf(result));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Warehouse stock')),
    body: RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
      SectionHeading(widget.app.warehouseName),
      if (busy) pageLoading()
      else if (error != null) FailureState(message: error!, retry: load)
      else if (rows.isEmpty) const EmptyState(title:'No stock balances',
        subtitle:'Only server-authorized warehouse stock is shown.')
      else ...rows.map((balance) {
        final product = objectOf(balance['product']);
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Surface(child: Row(children: [
          const Icon(Icons.inventory_2_outlined), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(field(product['name']), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(field(product['product_number']), style: Theme.of(context).textTheme.bodySmall),
          ])),
          Text(field(balance['quantity']), style: const TextStyle(fontWeight: FontWeight.bold)),
        ])));
      }),
    ])),
  );
}
