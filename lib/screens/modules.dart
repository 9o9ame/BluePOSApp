import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'catalog_master.dart';
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
import 'purchase_orders.dart';
import 'purchase_invoices.dart';
import 'inventory_documents.dart';
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
  const ModulesScreen({super.key, required this.app, required this.navigate});
  final AppController app;
  final ValueChanged<int> navigate;

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _open(Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

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
      ModuleAction('Sale Schemes', 'Existing pricing schemes',
        Icons.local_offer_outlined, () => _data('Sale Schemes',
          '/api/sale-schemes', subtitleKey: 'code'),
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
      ModuleAction('Sales Returns', 'Return document history',
        Icons.assignment_return_outlined, () => _data('Sales Returns',
          '/api/sales-returns?per_page=25', nameKey: 'document_number',
          subtitleKey: 'return_date', amountKey: 'grand_total',
          detailPrefix: '/api/sales-returns'),
        permissions: const ['sales.return'], entitlement: 'sales'),
      ModuleAction('Purchases', 'Purchase drafts, lines and server posting',
        Icons.shopping_bag_outlined,
        () => _open(PurchaseInvoicesScreen(app: widget.app)),
        permissions: const ['purchases.view'], entitlement: 'purchases'),
      ModuleAction('Purchase Orders', 'Create, edit and cancel supplier orders',
        Icons.assignment_outlined,
        () => _open(PurchaseOrdersScreen(app: widget.app)),
        permissions: const ['purchases.view'], entitlement: 'purchases'),
      ModuleAction('Purchase Returns', 'Return history',
        Icons.assignment_return_rounded, () => _data('Purchase Returns',
          '/api/purchase-returns?per_page=25', nameKey: 'document_number',
          subtitleKey: 'return_date', detailPrefix: '/api/purchase-returns'),
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
      ModuleAction('Vouchers', 'Journal and payment entries',
        Icons.account_balance_wallet_outlined, () => _data('Vouchers',
          '/api/vouchers?per_page=25', nameKey: 'document_number',
          subtitleKey: 'voucher_type', detailPrefix: '/api/vouchers'),
        permissions: const ['accounting.journal.view']),
      ModuleAction('Daily Cash Position', 'Cash, credit and account balances',
        Icons.payments_outlined,
        () => _open(CashPositionScreen(app: widget.app)),
        permissions: const ['accounting.journal.view']),
      ModuleAction('Expenses', 'Recorded expenses',
        Icons.credit_card_outlined, () => _data('Expenses',
          '/api/sales/expenses?per_page=25', nameKey: 'description',
          subtitleKey: 'expense_date', amountKey: 'amount'),
        permissions: const ['sales.view'], entitlement: 'sales'),
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
      ModuleAction('Users', 'Authorized team members',
        Icons.people_alt_outlined, () => _data('Users', '/api/memberships',
          nameKey: 'username', subtitleKey: 'name',
          detailPrefix: '/api/memberships'),
        permissions: const ['users.view']),
      ModuleAction('Roles & Groups', 'Access groups and permissions',
        Icons.admin_panel_settings_outlined, () => _data('Roles', '/api/roles',
          nameKey: 'name', subtitleKey: 'description',
          detailPrefix: '/api/roles'),
        permissions: const ['roles.view']),
      ModuleAction('Devices', 'Registered and trusted devices',
        Icons.devices_outlined, () => _data('Devices', '/api/devices',
          nameKey: 'name', subtitleKey: 'status'),
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
      ModuleAction('Security Sessions', 'Server-approved sessions',
        Icons.verified_user_outlined, () => _data('Sessions',
          '/api/security/sessions', nameKey: 'device_name',
          subtitleKey: 'last_active_at'),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = search.text.trim().toLowerCase();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Business modules',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text('Your BluePOS workspace', style: TextStyle(
        color: scheme.onSurfaceVariant)),
      const SizedBox(height: 15),
      TextField(controller: search, onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search modules',
          prefixIcon: Icon(Icons.search_rounded))),
      ...groups.entries.map((entry) => _group(entry.key, entry.value, query)),
      const SizedBox(height: 28),
    ]);
  }
}
