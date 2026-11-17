import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_navigation.dart';
import 'history.dart';
import 'dashboard.dart';
import 'modules.dart';
import 'products.dart';
import 'reports.dart';
import 'sale.dart';
import 'notifications.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.app});
  final AppController app;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with TickerProviderStateMixin {
  int selected = 0;
  bool drawerOpen = false;
  late final AnimationController pageMotion = AnimationController(
    vsync: this, value: 1, duration: const Duration(milliseconds: 250));
  late final AnimationController drawerMotion = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 420));
  late final CurvedAnimation drawerCurve = CurvedAnimation(
    parent: drawerMotion, curve: Curves.easeInOutCubic);
  final menuMode = ValueNotifier<bool>(false);
  final saleKey = GlobalKey<SaleScreenState>();
  late final List<Widget> pages = [
    DashboardScreen(app: widget.app, navigate: navigate),
    SaleScreen(key: saleKey, app: widget.app),
    ProductsScreen(app: widget.app, catalogHome: true,
      onBack: () => navigate(4), onAdd: (product) {
      saleKey.currentState?.addProduct(product);
      navigate(1);
    }),
    ReportsScreen(app: widget.app),
    MoreScreen(app: widget.app, navigate: navigate, menuMode: menuMode),
  ];
  void navigate(int i) {
    if (drawerOpen) _setDrawer(false);
    if (i == selected) return;
    setState(() => selected = i);
    if (widget.app.appearance.animations) {
      pageMotion.forward(from: 0);
    } else {
      pageMotion.value = 1;
    }
  }

  void _setDrawer(bool open) {
    if (drawerOpen == open) return;
    setState(() => drawerOpen = open);
    if (widget.app.appearance.animations) {
      if (open) {
        drawerMotion.forward();
      } else {
        drawerMotion.reverse();
      }
    } else {
      drawerMotion.value = open ? 1 : 0;
    }
  }

  void _toggleDrawer() => _setDrawer(!drawerOpen);

  @override
  void dispose() {
    pageMotion.dispose();
    drawerCurve.dispose();
    drawerMotion.dispose();
    menuMode.dispose();
    super.dispose();
  }

  void openScanner() {
    navigate(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) saleKey.currentState?.scan();
    });
  }

  void openMainMenu() => _toggleDrawer();

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final base = Theme.of(context);
    final reference = selected == 0 || selected == 1 || selected == 4;
    final refTheme = base;
    final ink = base.colorScheme.onSurface;
    final muted = base.colorScheme.onSurfaceVariant;
    return PopScope(
      canPop: !drawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && drawerOpen) _setDrawer(false);
      },
      child: Theme(
      data: reference ? refTheme : base,
      child: Builder(builder: (ctx) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: reference ? base.scaffoldBackgroundColor : null,
            leadingWidth: 47,
            leading: IconButton(
              key: const ValueKey('main-menu-toggle'),
              tooltip: drawerOpen ? 'Close Main Menu' : 'Open Main Menu',
              onPressed: _toggleDrawer,
              icon: RotationTransition(
                turns: Tween<double>(begin: 0, end: 13 / 12)
                    .animate(drawerCurve),
                child: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: drawerMotion,
                  size: 26)),
            ),
            centerTitle: true,
            titleSpacing: 0,
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              const BlueposBrandMark(size: 36),
              const SizedBox(width: 7),
              Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(const TextSpan(children: [
                    TextSpan(text: 'Blue',
                      style: TextStyle(color: ink)),
                    TextSpan(text: 'POS',
                      style: TextStyle(color: base.colorScheme.primary)),
                  ]), style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w900)),
                  if (selected == 0 || selected == 4)
                    const Text('P O S  &  E R P',
                      style: TextStyle(fontSize: 7,
                        color: muted,
                        fontWeight: FontWeight.w700)),
                ]),
            ]),
            actions: [
              IconButton(
                key: const ValueKey('open-notifications'),
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(builder: (_) =>
                    NotificationsScreen(app: app, onScan: () {
                      Navigator.of(ctx).pop();
                      openScanner();
                    }, onNavigate: (index) {
                      Navigator.of(ctx).pop();
                      if (index == 4) menuMode.value = false;
                      navigate(index);
                    }))),
              ),
              if (selected == 1)
                IconButton(
                  tooltip: 'Open product catalog',
                  icon: const Icon(Icons.filter_list_rounded),
                  onPressed: () => navigate(2)),
              const SizedBox(width: 3),
            ],
          ),
          body: LayoutBuilder(builder: (context, bounds) {
            final width = (bounds.maxWidth * .83).clamp(250.0, 380.0);
            final content = IndexedStack(
              sizing: StackFit.expand,
              index: selected,
              children: pages,
            );
            return Stack(children: [
              Positioned.fill(child: AnimatedBuilder(
                animation: pageMotion,
                child: content,
                builder: (context, child) {
                  final progress = Curves.easeOutCubic.transform(
                    pageMotion.value);
                  return Opacity(
                    opacity: .87 + progress * .13,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - progress)),
                      child: child));
                },
              )),
              Positioned.fill(child: AnimatedBuilder(
                animation: drawerMotion,
                builder: (context, _) {
                  if (drawerMotion.value == 0 && !drawerOpen) {
                    return const SizedBox.shrink();
                  }
                  return Stack(children: [
                    Positioned.fill(child: GestureDetector(
                      key: const ValueKey('drawer-scrim'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _setDrawer(false),
                      child: ColoredBox(
                        color: const Color(0xFF0D1E3E).withValues(
                          alpha: .36 * drawerMotion.value)))),
                    Positioned(
                      top: 0, bottom: 0,
                      left: -width + width * drawerMotion.value,
                      width: width,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(23)),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            boxShadow: [BoxShadow(
                              blurRadius: 20, color: Color(0x33081938))]),
                          child: Theme(
                            data: refTheme,
                            child: ModulesScreen(
                              key: const ValueKey('floating-main-menu'),
                              app: app,
                              navigate: navigate,
                              drawerMode: true,
                              onDrawerAction: () => _setDrawer(false)),
                          ),
                        ),
                      ),
                    ),
                  ]);
                },
              )),
            ]);
          }),
          bottomNavigationBar: BlueposReferenceNav(
            selectedIndex: selected,
            onSelect: (index) {
              if (index == 4) menuMode.value = false;
              navigate(index);
            },
            onScan: openScanner,
          ),
        );
      }),
    ));
  }
}

void openSales(BuildContext context, AppController app) => Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => DataListScreen(app: app,
    title: 'Sales invoices', path: '/api/sales?per_page=25',
    nameKey: 'document_number', subtitleKey: 'sale_date',
    amountKey: 'grand_total', detailPrefix: '/api/sales')));

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.app, required this.navigate,
    this.menuMode});
  final AppController app;
  final ValueChanged<int> navigate;
  final ValueNotifier<bool>? menuMode;

  @override
  Widget build(BuildContext context) =>
      ModulesScreen(app: app, navigate: navigate, menuMode: menuMode);
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
