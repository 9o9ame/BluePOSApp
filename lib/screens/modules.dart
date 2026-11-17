import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'catalog_master.dart';
import 'auth_reference_chrome.dart';
import 'sale_schemes.dart';
import 'sales_invoice_entry.dart';
import 'price_lists.dart';
import 'parties.dart';
import 'stock_status.dart';
import 'cash_book.dart';
import 'financial_statements.dart';
import 'general_journal.dart';
import 'next_reports.dart';
import 'daily_reports.dart';
import 'report_headings.dart';
import 'calculator.dart';
import 'workplace_directory.dart';
import 'quotations.dart';
import 'cash_position.dart';
import 'money_actions.dart';
import 'roles_admin.dart';
import 'users_admin.dart';
import 'device_admin.dart';
import 'security_sessions.dart';
import 'purchase_orders.dart';
import 'purchase_invoices.dart';
import 'inventory_documents.dart';
import 'vouchers.dart';
import 'returns.dart';
import 'trial_balance.dart';
import 'product_ledger.dart';
import 'history.dart';
import 'settings.dart';

/// Permission-aware mobile directory that mirrors the live web module groups.
/// Read-only modules remain read-only until their write workflow is verified.
class ModuleAction {
  const ModuleAction(this.title, this.description, this.icon,
    this.open, {this.permissions = const [], this.allPermissions = const [],
    this.entitlement});

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback open;
  final List<String> permissions;
  final List<String> allPermissions;
  final String? entitlement;

  bool visible(AppController app) {
    if (allPermissions.any((permission) => !app.hasPermission(permission))) {
      return false;
    }
    if (permissions.isNotEmpty &&
        !permissions.any((permission) => app.hasPermission(permission))) {
      return false;
    }
    final features = objectOf(app.session?['entitlements'])['features'];
    if (entitlement != null && features is List &&
        !features.contains(entitlement)) {
      return false;
    }
    return true;
  }
}

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key, required this.app, required this.navigate,
    this.menuMode, this.drawerMode = false, this.onDrawerAction});
  final AppController app;
  final ValueChanged<int> navigate;
  final ValueNotifier<bool>? menuMode;
  final bool drawerMode;
  final VoidCallback? onDrawerAction;

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final search = TextEditingController();
  // Approved references 08 (Main Menu) and 09 (More) share the existing
  // permission-checked module directory; no new backend actions.
  late final ValueNotifier<bool> _menuMode =
      widget.menuMode ?? ValueNotifier<bool>(false);
  bool showMainMenu = false;
  bool showDirectory = false;
  bool drawerSearch = false;
  String? expandedDrawerGroup;

  @override
  void initState() {
    super.initState();
    showMainMenu = _menuMode.value;
    _menuMode.addListener(_syncMenuMode);
  }

  void _syncMenuMode() {
    if (!mounted) return;
    setState(() {
      showMainMenu = _menuMode.value;
      showDirectory = false;
      activeGroup = null;
    });
  }

  String? activeGroup;

  @override
  void dispose() {
    _menuMode.removeListener(_syncMenuMode);
    if (widget.menuMode == null) _menuMode.dispose();
    search.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    final duration = widget.app.appearance.animations
        ? const Duration(milliseconds: 290) : Duration.zero;
    Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.055, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ));
  }

  void _catalog(CatalogMasterConfig config) =>
    _open(CatalogMasterScreen(app: widget.app, config: config));

  void _data(String title, String path, {
    String nameKey = 'name',
    String subtitleKey = 'code',
    String? amountKey,
    String? detailPrefix,
  }) => _open(DataListScreen(
    app: widget.app,
    title: title,
    path: path,
    nameKey: nameKey,
    subtitleKey: subtitleKey,
    amountKey: amountKey,
    detailPrefix: detailPrefix,
  ));

  void _settings() => _open(Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: SettingsScreen(app: widget.app),
  ));

  Map<String, List<ModuleAction>> get groups => {
    'Definition': [
      ModuleAction('Products', 'Catalog and stock lookup',
        Icons.inventory_2_outlined, () => widget.navigate(2),
        permissions: const ['products.view', 'products.manage'], entitlement: 'catalog'),
      ModuleAction('Categories', 'Create and edit categories',
        Icons.category_outlined, () => _catalog(CatalogMasterConfig.categories),
        permissions: const ['categories.view', 'categories.manage'], entitlement: 'catalog'),
      ModuleAction('Subcategories', 'Manage product subcategories',
        Icons.layers_outlined, () => _catalog(CatalogMasterConfig.subcategories),
        permissions: const ['categories.view', 'categories.manage'], entitlement: 'catalog'),
      ModuleAction('Brands', 'Create and edit brands',
        Icons.sell_outlined, () => _catalog(CatalogMasterConfig.brands),
        permissions: const ['brands.view', 'brands.manage'], entitlement: 'catalog'),
      ModuleAction('Units', 'Units and decimal quantities',
        Icons.straighten_outlined, () => _catalog(CatalogMasterConfig.units),
        permissions: const ['units.view', 'units.manage'], entitlement: 'catalog'),
      // Read-only UI reference until a real Price Lists API/permission exists.
      ModuleAction('Price Lists', 'Design reference — API not available',
        Icons.sell_outlined, () => _open(const PriceListsScreen()),
        permissions: const ['products.view', 'products.manage'],
        entitlement: 'catalog'),
      ModuleAction('Sale Schemes', 'Existing pricing schemes',
        Icons.local_offer_outlined, () => _open(SaleSchemesScreen(app: widget.app)),
        permissions: const ['sale_schemes.view', 'sale_schemes.manage'],
        entitlement: 'catalog'),
      ModuleAction('Customers', 'Manage customer records',
        Icons.people_outline_rounded, () => _open(PartyDirectory(
          app: widget.app, type: 'customer')),
        permissions: const ['customers.view', 'customers.manage']),
      ModuleAction('Suppliers', 'Manage vendor records',
        Icons.local_shipping_outlined, () => _open(PartyDirectory(
          app: widget.app, type: 'vendor')),
        permissions: const ['suppliers.view', 'suppliers.manage']),
      ModuleAction('Accounts', 'Manage account entries',
        Icons.account_balance_outlined, () => _open(PartyDirectory(
          app: widget.app, type: 'account')),
        permissions: const ['accounts.view', 'accounts.manage']),
    ],
    'Daily Entries': [
      ModuleAction('New Sale', 'New POS invoice',
        Icons.point_of_sale_outlined, () => widget.navigate(1),
        permissions: const ['sales.view', 'sales.create'], entitlement: 'sales'),
      ModuleAction('Create Sales Invoice', 'Existing POS invoice editor',
        Icons.add_shopping_cart_rounded,
        () => _open(SalesInvoiceEntryScreen(app: widget.app)),
        permissions: const ['sales.create'], entitlement: 'sales'),
      ModuleAction('Sales Invoices', 'Sales history and receipts',
        Icons.receipt_long_outlined, () => _data('Sales Invoices',
          '/api/sales?per_page=25', nameKey: 'document_number',
          subtitleKey: 'sale_date', amountKey: 'grand_total',
          detailPrefix: '/api/sales'),
        permissions: const ['sales.view'], entitlement: 'sales'),
      ModuleAction('Quotations', 'Create and browse sales estimates',
        Icons.request_quote_outlined,
        () => _open(QuotationDirectoryScreen(app: widget.app)),
        permissions: const ['sales.view'], entitlement: 'sales'),
      ModuleAction('Sales Returns', 'Source-linked sales returns and posting',
        Icons.assignment_return_outlined,
        () => _open(ReturnDocumentsScreen(
          app: widget.app, kind: ReturnDocumentKind.sale)),
        permissions: const ['sales.return'], entitlement: 'sales'),
      ModuleAction('Purchases', 'Purchase drafts, lines and server posting',
        Icons.shopping_bag_outlined,
        () => _open(PurchaseInvoicesScreen(app: widget.app)),
        permissions: const ['purchases.view'], entitlement: 'purchases'),
      ModuleAction('Purchase Orders', 'Create, edit and cancel supplier orders',
        Icons.assignment_outlined,
        () => _open(PurchaseOrdersScreen(app: widget.app)),
        permissions: const ['purchases.view'], entitlement: 'purchases'),
      ModuleAction('Purchase Returns', 'Source-linked purchase returns and posting',
        Icons.assignment_return_rounded,
        () => _open(ReturnDocumentsScreen(
          app: widget.app, kind: ReturnDocumentKind.purchase)),
        permissions: const ['purchase_returns.view'], entitlement: 'purchase_returns'),
      ModuleAction('Stock Adjustments', 'Draft, edit and post stock adjustments',
        Icons.tune_outlined,
        () => _open(InventoryDocumentDirectory(app: widget.app,
          kind: InventoryDocumentKind.adjustment)),
        permissions: const ['inventory.view'], entitlement: 'inventory'),
      ModuleAction('Opening Stock', 'Opening stock drafts and posted balances',
        Icons.inventory_outlined,
        () => _open(InventoryDocumentDirectory(app: widget.app,
          kind: InventoryDocumentKind.opening)),
        permissions: const ['inventory.opening_balance.view', 'inventory.view'],
        entitlement: 'inventory'),
      ModuleAction('Stock Taking', 'Count stock and post verified movements',
        Icons.fact_check_outlined,
        () => _open(InventoryDocumentDirectory(app: widget.app,
          kind: InventoryDocumentKind.stockTake)),
        permissions: const ['inventory.view'], entitlement: 'inventory'),
      ModuleAction('Vouchers', 'Opening, Payment, Receiving and Journal entries',
        Icons.account_balance_wallet_outlined,
        () => _open(VoucherDirectoryScreen(app: widget.app)),
        permissions: const ['accounting.journal.view']),
      ModuleAction('Daily Cash Position', 'Cash, credit and account balances',
        Icons.payments_outlined,
        () => _open(CashPositionScreen(app: widget.app)),
        permissions: const ['accounting.journal.view']),
      ModuleAction('Expenses', 'Create and browse posted expenses',
        Icons.credit_card_outlined,
        () => _open(ExpensesScreen(app: widget.app)),
        permissions: const ['expenses.view', 'expenses.create'],
        entitlement: 'sales'),
    ],
    'Reports': [
      ModuleAction('Product Ledger', 'Server-issued stock movements',
        Icons.receipt_long_outlined, () => _open(ProductLedgerScreen(app: widget.app)),
        permissions: const ['reports.inventory'], entitlement: 'inventory'),
      ModuleAction('Trial Balance', 'Server-calculated debit and credit',
        Icons.balance_outlined, () => _open(TrialBalanceScreen(app: widget.app)),
        permissions: const ['reports.accounting']),
      ModuleAction('Cash Book', 'Cash and bank transactions',
        Icons.account_balance_wallet_outlined,
        () => _open(CashBookReportScreen(app: widget.app)),
        permissions: const ['reports.accounting']),
      ModuleAction('Balance Sheet', 'Posted ledger statement',
        Icons.account_balance_outlined,
        () => _open(FinancialStatementScreen(app: widget.app,
          kind: FinancialStatementKind.balanceSheet)),
        permissions: const ['reports.accounting']),
      ModuleAction('Income Statement', 'Posted income and expense entries',
        Icons.show_chart_rounded,
        () => _open(FinancialStatementScreen(app: widget.app,
          kind: FinancialStatementKind.incomeStatement)),
        permissions: const ['reports.accounting']),
      ModuleAction('General Journal', 'Posted journal report and balance checks',
        Icons.menu_book_outlined,
        () => _open(GeneralJournalReportScreen(app: widget.app)),
        permissions: const ['reports.accounting']),
      ModuleAction('Advance Sales View', 'Sold quantities and warehouse stock',
        Icons.trending_up_outlined,
        () => _open(NextReportScreen(app: widget.app,
          kind: NextReportKind.advanceSales)),
        allPermissions: const ['reports.inventory', 'reports.accounting'],
        entitlement: 'inventory'),
      ModuleAction('Day Book', 'Posted business documents and account ledger',
        Icons.calendar_month_outlined,
        () => _open(NextReportScreen(app: widget.app,
          kind: NextReportKind.dayBook)),
        permissions: const ['reports.accounting']),
      ModuleAction('Product Wise Transactions', 'Signed stock movements',
        Icons.inventory_2_outlined,
        () => _open(NextReportScreen(app: widget.app,
          kind: NextReportKind.productTransactions)),
        permissions: const ['reports.inventory'], entitlement: 'inventory'),
      ModuleAction('Detailed Transactions', 'Party summary, daily and detail',
        Icons.view_list_outlined,
        () => _open(NextReportScreen(app: widget.app,
          kind: NextReportKind.detailedTransactions)),
        permissions: const ['reports.accounting']),
      ModuleAction('FBR Sales Register', 'Internal sales tax review',
        Icons.receipt_outlined,
        () => _open(NextReportScreen(app: widget.app,
          kind: NextReportKind.fbrSales)),
        permissions: const ['reports.accounting']),
      ModuleAction('FBR Purchase Register', 'Internal purchase tax review',
        Icons.receipt_long_outlined,
        () => _open(NextReportScreen(app: widget.app,
          kind: NextReportKind.fbrPurchases)),
        permissions: const ['reports.accounting']),
      ModuleAction('Daily Activity Report', 'Posted documents and stock movements',
        Icons.today_outlined,
        () => _open(DailyReportScreen(app: widget.app,
          kind: DailyReportKind.activity)),
        allPermissions: const ['reports.inventory', 'reports.accounting'],
        entitlement: 'inventory'),
      ModuleAction('Detail Sale + Stock + Profit/Loss', 'Actual stock and gross margin',
        Icons.query_stats_outlined,
        () => _open(DailyReportScreen(app: widget.app,
          kind: DailyReportKind.saleStockProfit)),
        permissions: const ['reports.inventory'], entitlement: 'inventory'),
      ModuleAction('Business by Groups', 'Category and brand summaries',
        Icons.account_tree_outlined,
        () => _open(DailyReportScreen(app: widget.app,
          kind: DailyReportKind.businessGroups)),
        allPermissions: const ['reports.inventory', 'reports.accounting'],
        entitlement: 'inventory'),
      ModuleAction('Daily Product Profit/Loss', 'Verified movement-based product cost',
        Icons.trending_up_rounded,
        () => _open(DailyReportScreen(app: widget.app,
          kind: DailyReportKind.productProfit)),
        allPermissions: const ['reports.inventory', 'reports.accounting', 'inventory.view'],
        entitlement: 'inventory'),
      ModuleAction('Stock Status', 'Live warehouse inventory balances',
        Icons.warehouse_outlined, () => _open(StockStatusReport(app: widget.app)),
        permissions: const ['reports.inventory'], entitlement: 'inventory'),
      ModuleAction('Reports & Insights', 'Sales and product summaries',
        Icons.analytics_outlined, () => widget.navigate(3)),
      ModuleAction('Product-wise Sales', 'Product transaction summary',
        Icons.trending_up_outlined, () => _data('Product-wise Sales',
          '/api/sales/product-wise?per_page=25', nameKey: 'sale_number',
          subtitleKey: 'sale_date', amountKey: 'amount'),
        permissions: const ['sales.view'], entitlement: 'sales'),
      ModuleAction('Outstanding Invoices', 'Unpaid sales invoices',
        Icons.pending_actions_outlined, () => _data('Outstanding Invoices',
          '/api/sales?due_only=1&per_page=25', nameKey: 'document_number',
          subtitleKey: 'sale_date', amountKey: 'balance_due',
          detailPrefix: '/api/sales'),
        permissions: const ['sales.view'], entitlement: 'sales'),
    ],
    'Tools': [
      ModuleAction('Calculator', 'Local decimal-safe calculator',
        Icons.calculate_outlined,
        () => _open(const CalculatorScreen())),
      ModuleAction('Users', 'User onboarding and access management',
        Icons.people_alt_outlined,
        () => _open(UsersAdminScreen(app: widget.app)),
        permissions: const ['users.view']),
      ModuleAction('Roles & Groups', 'Role and permission management',
        Icons.admin_panel_settings_outlined,
        () => _open(RolesAdminScreen(app: widget.app)),
        permissions: const ['roles.view']),
      ModuleAction('Devices', 'Device registry and owner access approvals',
        Icons.devices_outlined,
        () => _open(DeviceAdminScreen(app: widget.app)),
        permissions: const ['devices.view']),
      ModuleAction('Report Headings', 'Manage report heading presets',
        Icons.article_outlined,
        () => _open(ReportHeadingsScreen(app: widget.app)),
        permissions: const ['settings.view']),
    ],
    'Administration': [
      ModuleAction('Branches', 'Manage business locations',
        Icons.store_mall_directory_outlined,
        () => _open(WorkplaceDirectoryScreen(
          app: widget.app, kind: WorkplaceKind.branches)),
        permissions: const ['branches.view']),
      ModuleAction('Warehouses', 'Current branch warehouses',
        Icons.warehouse_outlined,
        () => _open(WorkplaceDirectoryScreen(
          app: widget.app, kind: WorkplaceKind.warehouses)),
        permissions: const ['warehouses.manage', 'inventory.view',
          'branches.view', 'products.view']),
      ModuleAction('Security Sessions', 'Revocation and active sessions',
        Icons.verified_user_outlined,
        () => _open(SecuritySessionsScreen(app: widget.app)),
        permissions: const ['security.sessions.view']),
      ModuleAction('Appearance & Security', 'Themes, biometrics and account',
        Icons.settings_outlined, _settings),
    ],
    'Help': [
      ModuleAction('App Settings', 'Account and app information',
        Icons.info_outline_rounded, _settings),
    ],
  };

  Widget _group(String title, List<ModuleAction> actions, String query) {
    final visible = actions.where((action) => action.visible(widget.app) &&
      (query.isEmpty || '${action.title} ${action.description} $title'
        .toLowerCase().contains(query))).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 15),
      Row(children: [
        Expanded(child: SectionHeading(title)),
        Text('${visible.length}', style: TextStyle(color: scheme.onSurfaceVariant)),
      ]),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: visible.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width < 345 ? 1 : 2,
          crossAxisSpacing: 11, mainAxisSpacing: 11, mainAxisExtent: 106,
        ),
        itemBuilder: (_, index) {
          final action = visible[index];
          return InkWell(
            onTap: action.open,
            borderRadius: BorderRadius.circular(widget.app.appearance.corner),
            child: Surface(padding: const EdgeInsets.all(12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(11)),
                    child: Icon(action.icon, color: scheme.primary, size: 19)),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded,
                    color: scheme.onSurfaceVariant, size: 16),
                ]),
                const SizedBox(height: 9),
                Text(action.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                Text(action.description,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
              ],
            )),
          );
        },
      ),
    ]);
  }


  bool _hasVisibleActions(String group) =>
      groups[group]?.any((action) => action.visible(widget.app)) ?? false;

  Widget _menuRow({
    required String title,
    required IconData icon,
    required Color tone,
    required VoidCallback onTap,
    Key? key,
    bool compact = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF4F6FF)]),
          border: Border.all(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Color(0x205D78AE),
            blurRadius: 9, offset: Offset(0, 4))]),
        child: Material(color: Colors.transparent,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(15),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 11, vertical: compact ? 3 : 4),
              child: Row(children: [
                Container(
                  height: compact ? 34 : 38, width: compact ? 34 : 38,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: tone, size: compact ? 21 : 23)),
                const SizedBox(width: 12),
                Expanded(child: Text(title,
                  style: TextStyle(fontSize: compact ? 14 : 15,
                    color: const Color(0xFF091C46),
                    fontWeight: FontWeight.w900))),
                Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _showGroup(String group) => setState(() {
    activeGroup = group;
    showDirectory = false;
  });

  Widget _approvedMenu() {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    final main = showMainMenu;
    final entries = <({String group, String label, IconData icon, Color color})>[
      (group: 'Definition', label: 'Definition',
        icon: Icons.layers_rounded, color: const Color(0xFF0EB65F)),
      (group: 'Daily Entries', label: 'Daily Entries',
        icon: Icons.calendar_month_rounded, color: const Color(0xFF04B9C5)),
      (group: 'Reports', label: 'Reports',
        icon: Icons.bar_chart_rounded, color: const Color(0xFF7B45EE)),
      (group: 'Tools', label: 'Tools',
        icon: Icons.handyman_rounded, color: const Color(0xFFF49808)),
      (group: 'Administration', label: 'Administration',
        icon: Icons.settings_suggest_rounded, color: const Color(0xFF0486F8)),
    ];
    return Stack(children: [
    ListView(
      key: ValueKey(main ? 'approved-main-menu' : 'approved-more-menu'),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 96),
      children: [
        Row(children: [
          Expanded(child: Text(main ? 'Main Menu' : 'More',
            style: const TextStyle(
              color: Color(0xFF071943), fontSize: 23,
              fontWeight: FontWeight.w900))),
          IconButton(
            tooltip: main ? 'Search modules' : 'Settings',
            onPressed: main
              ? () => setState(() {
                  showDirectory = true;
                  activeGroup = null;
                })
              : _settings,
            icon: Icon(main ? Icons.search_rounded
              : Icons.settings_outlined,
              color: const Color(0xFF0C275B))),
        ]),
        const SizedBox(height: 4),
        if (!main) ...[
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFFFFFFFF), Color(0xFFE7FFF5)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [BoxShadow(
                color: Color(0x1C57BBA4), blurRadius: 10, offset: Offset(0, 5))]),
            child: Padding(
            padding: const EdgeInsets.all(11), child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.storefront_rounded,
                  color: scheme.primary, size: 26)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.tenantName, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w900)),
                  Text('Branch: ${app.branchName}', maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                ])),
            ]),
          )),
          const SizedBox(height: 9),
        ],
        for (final item in entries)
          if (_hasVisibleActions(item.group))
            _menuRow(title: item.label, icon: item.icon,
              tone: item.color, onTap: () => _showGroup(item.group),
              key: ValueKey('menu-${item.group}'), compact: !main),
        if (main) ...[
          if (_hasVisibleActions('Definition'))
            _menuRow(title: 'Products', icon: Icons.inventory_2_rounded,
              tone: const Color(0xFF9155EC), onTap: () => widget.navigate(2), compact: false),
          if (groups['Definition']!.any((action) =>
              action.title == 'Customers' && action.visible(app)))
            _menuRow(title: 'Customers', icon: Icons.people_rounded,
              tone: const Color(0xFFEA4A72), onTap: () =>
                groups['Definition']!.firstWhere((a) =>
                  a.title == 'Customers').open(), compact: false),
          if (groups['Daily Entries']!.any((action) =>
              action.title == 'Purchases' && action.visible(app)))
            _menuRow(title: 'Purchases', icon: Icons.shopping_bag_rounded,
              tone: const Color(0xFFF49B00), onTap: () =>
                groups['Daily Entries']!.firstWhere((a) =>
                  a.title == 'Purchases').open(), compact: false),
          if (groups['Daily Entries']!.any((action) =>
              action.title == 'New Sale' && action.visible(app)))
            _menuRow(title: 'Sales', icon: Icons.shopping_cart_rounded,
              tone: const Color(0xFF08C665), onTap: () => widget.navigate(1), compact: false),
        ] else ...[
          const SizedBox(height: 2),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 2),
          if (groups['Administration']!.any((action) =>
              action.title == 'Security Sessions' && action.visible(app)))
            _menuRow(title: 'Device & Security',
              icon: Icons.verified_user_rounded,
              tone: scheme.tertiary, onTap: () =>
                groups['Administration']!.firstWhere((a) =>
                  a.title == 'Security Sessions').open(), compact: true),
          _menuRow(title: 'Settings', icon: Icons.settings_rounded,
            tone: const Color(0xFF087CF7), onTap: _settings, compact: true),
          _menuRow(title: 'Help & Support', icon: Icons.support_agent_rounded,
            tone: const Color(0xFF7B4DE8),
            onTap: () => setState(() {
              showDirectory = true;
              activeGroup = 'Help';
            }), compact: true),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Material(
              color: const Color(0xFFFFEDF0),
              borderRadius: BorderRadius.circular(15),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                key: const ValueKey('more-logout'),
                leading: const Icon(Icons.logout_rounded,
                  color: Color(0xFFE62845)),
                title: const Text('Logout',
                  style: TextStyle(
                    color: Color(0xFFCC183A),
                    fontWeight: FontWeight.w800)),
                trailing: const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFE62845)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      title: const Text('Log out?'),
                      content: const Text(
                        'You will need to sign in again to access BluePOS.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog, false),
                          child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialog, true),
                          child: const Text('Log out')),
                      ]));
                  if (confirm == true && mounted) {
                    await widget.app.logout();
                  }
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    ),
    const Positioned(left: 0, right: 0, bottom: 0,
      child: IgnorePointer(child: AuthReferenceWaves(height: 60))),
    ]);
  }

  /// Newer approved reference 11: Definition uses ordered navigation rows,
  /// not the generic two-column directory. No authorization is inferred from
  /// the screenshot; only existing permission/entitlement-checked actions show.
  /// Approved image 32: ordered Daily Entries launcher. Every target comes
  /// from the existing RBAC/entitlement-gated action registry.
  Widget _dailyEntriesHome() {
    final scheme = Theme.of(context).colorScheme;
    final items = <({String title, String label, IconData icon})>[
      (title: 'Sales Invoices', label: 'Sales Invoices',
        icon: Icons.receipt_long_outlined),
      (title: 'Purchases', label: 'Purchase Invoices',
        icon: Icons.shopping_bag_outlined),
      (title: 'Sales Returns', label: 'Sales Return',
        icon: Icons.assignment_return_outlined),
      (title: 'Purchase Returns', label: 'Purchase Return',
        icon: Icons.assignment_return_rounded),
      (title: 'Vouchers', label: 'Receipts, Payments & Journal Vouchers',
        icon: Icons.account_balance_wallet_outlined),
      (title: 'Expenses', label: 'Expense Vouchers',
        icon: Icons.payments_outlined),
      (title: 'Create Sales Invoice', label: 'Create Sales Invoice',
        icon: Icons.add_shopping_cart_rounded),
    ];
    final actions = groups['Daily Entries'] ?? const <ModuleAction>[];
    return ListView(
      key: const ValueKey('approved-daily-entries-home'),
      padding: EdgeInsets.all(widget.app.appearance.spacing),
      children: [
        Row(children: [
          IconButton(tooltip: 'Back to More',
            onPressed: () => setState(() => activeGroup = null),
            icon: const Icon(Icons.arrow_back_rounded)),
          Expanded(child: Text('Daily Entries', style:
            Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 10),
        for (final item in items)
          for (final action in actions)
            if (action.title == item.title && action.visible(widget.app))
              _menuRow(
                key: ValueKey('daily-entry-${item.title}'),
                title: item.label, icon: item.icon,
                tone: scheme.primary, onTap: action.open),
        const SizedBox(height: 10),
        TextButton.icon(
          icon: const Icon(Icons.grid_view_outlined),
          onPressed: () => setState(() {
            activeGroup = 'Daily Entries';
            showDirectory = true;
          }),
          label: const Text('Browse all Daily Entries')),
      ],
    );
  }

  Widget _definitionHome() {
    // Screen 11: ordered reference navigation; actions remain RBAC-gated.
    final style = BpReferenceStyle.of(context);
    final specs = <({String group, String title, IconData icon, Color tone})>[
      (group: 'Definition', title: 'Products',
        icon: Icons.local_offer_rounded, tone: const Color(0xFF8147FF)),
      (group: 'Definition', title: 'Customers',
        icon: Icons.people_alt_rounded, tone: const Color(0xFF00A1F6)),
      (group: 'Definition', title: 'Suppliers',
        icon: Icons.local_shipping_rounded, tone: const Color(0xFFFF9515)),
      (group: 'Definition', title: 'Categories',
        icon: Icons.layers_rounded, tone: const Color(0xFF05C96B)),
      (group: 'Definition', title: 'Subcategories',
        icon: Icons.account_tree_rounded, tone: const Color(0xFF8A38F8)),
      (group: 'Definition', title: 'Brands',
        icon: Icons.sell_rounded, tone: const Color(0xFFF63876)),
      (group: 'Definition', title: 'Units',
        icon: Icons.inventory_2_rounded, tone: const Color(0xFF077EF6)),
      (group: 'Definition', title: 'Price Lists',
        icon: Icons.price_change_rounded, tone: const Color(0xFF04B966)),
      (group: 'Definition', title: 'Sale Schemes',
        icon: Icons.campaign_rounded, tone: const Color(0xFFFF9E00)),
      (group: 'Daily Entries', title: 'Opening Stock',
        icon: Icons.file_upload_outlined, tone: const Color(0xFF06BAEB)),
      (group: 'Daily Entries', title: 'Stock Taking',
        icon: Icons.assignment_turned_in_rounded,
        tone: const Color(0xFFE62E68)),
    ];
    return Stack(children: [
      const Positioned(top: 0, right: 0,
        child: BpReferenceTopAccent()),
      ListView(
        key: const ValueKey('approved-definition-home'),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 2, 0, 11),
            child: Text('Definition', style: TextStyle(
              color: style.ink, fontSize: 23,
              fontWeight: FontWeight.w900))),
          for (final item in specs)
            for (final action in groups[item.group] ?? const <ModuleAction>[])
              if (action.title == item.title && action.visible(widget.app))
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('definition-${item.title}'),
                      borderRadius: BorderRadius.circular(13),
                      onTap: action.open,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: style.card(radius: 13),
                        child: Row(children: [
                          Container(
                            width: 36, height: 34,
                            decoration: BoxDecoration(
                              color: item.tone.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(9)),
                            child: Icon(item.icon, size: 21, color: item.tone)),
                          const SizedBox(width: 10),
                          Container(height: 25, width: 1,
                            color: style.line),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item.title,
                            style: TextStyle(
                              color: style.ink, fontSize: 13.5,
                              fontWeight: FontWeight.w800))),
                          Icon(Icons.chevron_right_rounded,
                            color: style.ink, size: 20),
                        ]),
                      ),
                    ),
                  ),
                ),
        ],
      ),
      const Positioned(left: 0, right: 0, bottom: 0,
        child: IgnorePointer(child: AuthReferenceWaves(height: 56))),
    ]);
  }

  Widget _directory() {
    final query = search.text.trim().toLowerCase();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        IconButton(
          tooltip: 'Back to menu',
          onPressed: () => setState(() {
            activeGroup = null;
            showDirectory = false;
          }),
          icon: const Icon(Icons.arrow_back_rounded)),
        Expanded(child: Text(activeGroup ?? 'Business modules',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 12),
      TextField(controller: search, onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search modules',
          prefixIcon: Icon(Icons.search_rounded))),
      if (activeGroup != null)
        _group(activeGroup!, groups[activeGroup!] ?? const [], query)
      else
        ...groups.entries.map((entry) =>
          _group(entry.key, entry.value, query)),
      const SizedBox(height: 28),
    ]);
  }

  Widget _floatingDrawer() {
    final motion = widget.app.appearance.animations
        ? const Duration(milliseconds: 260) : Duration.zero;
    final query = search.text.trim().toLowerCase();
    final categories = <({String name, IconData icon, Color color})>[
      (name: 'Definition', icon: Icons.layers_rounded,
        color: const Color(0xFF14B75B)),
      (name: 'Daily Entries', icon: Icons.calendar_month_rounded,
        color: const Color(0xFF02BAC1)),
      (name: 'Reports', icon: Icons.bar_chart_rounded,
        color: const Color(0xFF8A50ED)),
      (name: 'Tools', icon: Icons.handyman_rounded,
        color: const Color(0xFFF69A14)),
      (name: 'Administration', icon: Icons.settings_suggest_rounded,
        color: const Color(0xFF087DF6)),
    ];
    return Material(
      color: const Color(0xFFF7F9FF),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 17, 10, 7),
          child: Row(children: [
            Container(
              height: 40, width: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE2F7EC),
                borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.apps_rounded,
                color: Color(0xFF079960))),
            const SizedBox(width: 10),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Main Menu', style: TextStyle(
                  color: Color(0xFF0B2049), fontSize: 19,
                  fontWeight: FontWeight.w900)),
                Text('Explore your business modules',
                  style: TextStyle(
                    color: Color(0xFF647393), fontSize: 10.5)),
              ])),
            IconButton(
              key: const ValueKey('drawer-search'),
              tooltip: 'Search menu',
              icon: Icon(drawerSearch ? Icons.close_rounded
                  : Icons.search_rounded,
                color: const Color(0xFF102852)),
              onPressed: () => setState(() {
                drawerSearch = !drawerSearch;
                if (!drawerSearch) search.clear();
              })),
          ]),
        ),
        AnimatedSize(
          duration: motion,
          curve: Curves.easeInOutCubic,
          child: drawerSearch
            ? Padding(
                padding: const EdgeInsets.fromLTRB(13, 3, 13, 8),
                child: TextField(
                  key: const ValueKey('drawer-search-input'),
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search submenus…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                ))
            : const SizedBox.shrink(),
        ),
        Expanded(child: ListView(
          key: const ValueKey('floating-main-menu-list'),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 22),
          children: [
            for (final category in categories)
              Builder(builder: (context) {
                final actions = (groups[category.name] ?? const <ModuleAction>[])
                  .where((action) => action.visible(widget.app))
                  .where((action) => query.isEmpty ||
                    '${category.name} ${action.title} ${action.description}'
                      .toLowerCase().contains(query))
                  .toList();
                if (actions.isEmpty) return const SizedBox.shrink();
                final expanded = expandedDrawerGroup == category.name ||
                    query.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: expanded
                          ? category.color.withValues(alpha: .28)
                          : const Color(0xFFE6EBF8)),
                      boxShadow: const [BoxShadow(
                        color: Color(0x17557CAC),
                        blurRadius: 7, offset: Offset(0, 3))]),
                    child: Column(children: [
                      InkWell(
                        key: ValueKey('drawer-group-${category.name}'),
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => setState(() {
                          expandedDrawerGroup = expandedDrawerGroup ==
                            category.name ? null : category.name;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 9),
                          child: Row(children: [
                            Container(
                              width: 35, height: 35,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(10)),
                              child: Icon(category.icon,
                                size: 22, color: category.color)),
                            const SizedBox(width: 9),
                            Expanded(child: Text(category.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF0B1D43),
                                fontWeight: FontWeight.w800))),
                            AnimatedRotation(
                              turns: expanded ? .25 : 0,
                              duration: motion,
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF344C72))),
                          ]),
                        ),
                      ),
                      AnimatedSize(
                        duration: motion,
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: expanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(7, 0, 7, 8),
                              child: Column(children: [
                                const Divider(
                                  color: Color(0xFFEAF0FB), height: 8),
                                for (final action in actions)
                                  InkWell(
                                    key: ValueKey(
                                      'drawer-action-${action.title}'),
                                    onTap: () {
                                      // Permission gates are checked above.
                                      // Close the overlay, then use the existing
                                      // live module navigation callback.
                                      widget.onDrawerAction?.call();
                                      action.open();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                      child: Row(children: [
                                        Icon(action.icon, size: 18,
                                          color: category.color),
                                        const SizedBox(width: 9),
                                        Expanded(child: Text(action.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF263456),
                                            fontWeight: FontWeight.w700))),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12, color: Color(0xFF7485A2)),
                                      ]),
                                    ),
                                  ),
                              ]))
                          : const SizedBox.shrink(),
                      ),
                    ]),
                  ),
                );
              }),
          ],
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drawerMode) return _floatingDrawer();
    if (activeGroup == 'Daily Entries' && !showDirectory) {
      return _dailyEntriesHome();
    }
    if (activeGroup == 'Definition' && !showDirectory) {
      return _definitionHome();
    }
    if (showDirectory || activeGroup != null) return _directory();
    return _approvedMenu();
  }
}
