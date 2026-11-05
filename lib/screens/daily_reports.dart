import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Four posted-data Daily Reports from the existing BluePOS web APIs.
/// The backend owns all amounts, stock movement quantities and cost/profit.
enum DailyReportKind {
  activity,
  saleStockProfit,
  businessGroups,
  productProfit,
}

extension DailyReportDefinition on DailyReportKind {
  String get title => switch (this) {
    DailyReportKind.activity => 'Daily Activity Report',
    DailyReportKind.saleStockProfit => 'Detail Sale + Stock + Profit/Loss',
    DailyReportKind.businessGroups => 'Business by Groups',
    DailyReportKind.productProfit => 'Daily Product Profit/Loss',
  };
  String get endpoint => switch (this) {
    DailyReportKind.activity => '/api/reports/daily/activity-summary',
    DailyReportKind.saleStockProfit =>
      '/api/reports/daily/detail-sale-stock-profit',
    DailyReportKind.businessGroups => '/api/reports/daily/business-by-groups',
    DailyReportKind.productProfit => '/api/reports/daily/profit-loss',
  };
  List<String> get permissions => switch (this) {
    DailyReportKind.activity || DailyReportKind.businessGroups =>
      const ['reports.inventory', 'reports.accounting'],
    DailyReportKind.saleStockProfit => const ['reports.inventory'],
    DailyReportKind.productProfit =>
      const ['reports.inventory', 'reports.accounting', 'inventory.view'],
  };
}

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key, required this.app, required this.kind});
  final AppController app;
  final DailyReportKind kind;
  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  DateTimeRange period = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );
  bool loading = true;
  bool stockTab = false;
  int requestSerial = 0;
  String? error, optionsError;
  String categoryUlid = '', brandUlid = '';
  String groupBy = 'category';
  List<Map<String, dynamic>> categories = const [], brands = const [];
  Map<String, dynamic> report = const {};

  @override
  void initState() {
    super.initState();
    _options();
    load();
  }

  String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

  Future<void> _options() async {
    if (widget.kind == DailyReportKind.activity) return;
    try {
      final options = objectOf(
        await widget.app.api.get('/api/reports/daily/product-options'));
      if (mounted) setState(() {
        categories = recordsOf(options['categories']);
        brands = recordsOf(options['brands']);
        optionsError = null;
      });
    } catch (ex) {
      if (mounted) setState(() => optionsError = ex.toString());
    }
  }

  Future<void> _pickPeriod() async {
    final selected = await showDateRangePicker(
      context: context, firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
      initialDateRange: period,
      helpText: 'Choose up to 31 calendar days',
    );
    if (selected == null || !mounted) return;
    if (selected.end.difference(selected.start).inDays >= 31) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select no more than 31 days.')));
      return;
    }
    setState(() => period = selected);
    await load();
  }

  Future<void> load() async {
    final serial = ++requestSerial;
    setState(() { loading = true; error = null; });
    try {
      final query = <String, String>{
        'from': _iso(period.start),
        'to': _iso(period.end),
      };
      if (widget.kind != DailyReportKind.activity) {
        if (categoryUlid.isNotEmpty) query['category_ulid'] = categoryUlid;
        if (brandUlid.isNotEmpty) query['brand_ulid'] = brandUlid;
      }
      if (widget.kind == DailyReportKind.businessGroups) {
        query['group_by'] = groupBy;
      }
      final raw = await widget.app.api.get(Uri(
        path: widget.kind.endpoint, queryParameters: query,
      ).toString());
      if (mounted && serial == requestSerial) {
        setState(() => report = objectOf(raw));
      }
    } catch (ex) {
      if (mounted && serial == requestSerial) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && serial == requestSerial) {
        setState(() => loading = false);
      }
    }
  }

  Widget _metric(IconData icon, String title, dynamic value,
      {bool monetary = true, bool optional = false}) =>
      Expanded(child: BpStatCard(
        icon: icon, caption: title,
        value: optional && value == null
          ? 'Unavailable'
          : monetary ? money(value, widget.app.currency) : field(value, '—'),
        hint: optional && value == null
          ? 'Cost not verified'
          : 'Server calculated',
      ));

  Widget _totals() {
    final totals = objectOf(report['totals']);
    switch (widget.kind) {
      case DailyReportKind.activity:
        return Column(children: [
          Row(children: [
            _metric(Icons.receipt_outlined, 'Posted sales', totals['sale']),
            const SizedBox(width: 9),
            _metric(Icons.shopping_bag_outlined, 'Purchases', totals['purchase']),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            _metric(Icons.assignment_return_outlined,
              'Sales returns', totals['sale_return']),
            const SizedBox(width: 9),
            _metric(Icons.assignment_return_outlined,
              'Purchase returns', totals['purchase_return']),
          ]),
        ]);
      case DailyReportKind.saleStockProfit:
        return BpStatCard(icon: Icons.inventory_2_outlined,
          caption: 'Products in report',
          value: '${recordsOf(report['rows']).length}',
          hint: 'Stock values are warehouse scoped');
      case DailyReportKind.businessGroups:
        return Column(children: [
          Row(children: [
            _metric(Icons.payments_outlined,
              'Sales amount', totals['sale_amount']),
            const SizedBox(width: 9),
            _metric(Icons.shopping_bag_outlined,
              'Purchase amount', totals['purchase_amount']),
          ]),
          const SizedBox(height: 9),
          Row(children: [
            _metric(Icons.inventory_outlined, 'Stock movement',
              totals['stock_change'], monetary: false),
            const SizedBox(width: 9),
            _metric(Icons.receipt_long_outlined, 'Sale quantity',
              totals['sale_quantity'], monetary: false),
          ]),
        ]);
      case DailyReportKind.productProfit:
        return Column(children: [
          Row(children: [
            _metric(Icons.payments_outlined,
              'Sales amount', totals['sale_amount']),
            const SizedBox(width: 9),
            _metric(Icons.sell_outlined, 'Cost of sales',
              totals['cost_amount'], optional: true),
          ]),
          const SizedBox(height: 9),
          BpStatCard(icon: Icons.trending_up_rounded,
            caption: 'Operational gross profit',
            value: totals['gross_profit'] == null
              ? 'Unavailable' : money(totals['gross_profit'],
                widget.app.currency),
            hint: totals['gross_profit'] == null
              ? 'Missing historical cost — no estimate'
              : 'Not accounting net income'),
        ]);
    }
  }

  Widget _selectMaster(String label, List<Map<String, dynamic>> options,
      String value, ValueChanged<String> changed) {
    final selected = options.any((item) =>
      field(item['ulid']) == value) ? value : '';
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-$selected'),
        isExpanded: true,
        initialValue: selected,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem<String>(
            value: '', child: Text('All')),
          ...options.map((item) => DropdownMenuItem<String>(
            value: field(item['ulid']),
            child: Text(field(item['name']),
              maxLines: 1, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: (next) {
          if (next == null) return;
          changed(next);
          load();
        },
      ),
    );
  }

  Widget _pair(String label, dynamic value,
      {bool monetary = false, bool optional = false}) {
    if (value == null && !optional) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 11, color: scheme.onSurfaceVariant))),
        Expanded(child: Text(
          value == null ? 'Unavailable' :
            monetary ? money(value, widget.app.currency) : field(value),
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _row(Map<String, dynamic> row) {
    final activity = widget.kind == DailyReportKind.activity;
    final product = objectOf(row['product']);
    final title = activity && !stockTab
      ? field(row['document_number'], 'Document')
      : widget.kind == DailyReportKind.businessGroups
        ? field(row['name'], 'Group')
        : field(product['name'], 'Product');
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Surface(padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900,
              fontSize: 13)),
          if (activity && !stockTab)
            Text('${field(row['date'])} · ${field(row['type'])}'
              ' · ${field(row['party'])}',
              style: TextStyle(fontSize: 11,
                color: scheme.onSurfaceVariant)),
          if (activity && !stockTab) ...[
            _pair('Gross document amount', row['amount'], monetary: true),
            if (recordsOf(row['lines']).isNotEmpty)
              ExpansionTile(
                title: const Text('Document lines'),
                tilePadding: EdgeInsets.zero,
                children: [
                  for (final line in recordsOf(row['lines']))
                    ListTile(dense: true,
                      title: Text(field(objectOf(line['product'])['name'],
                        'Product line')),
                      subtitle: Text(field(line['quantity'])),
                      trailing: Text(field(line['amount']))),
                ],
              ),
          ] else if (activity && stockTab) ...[
            _pair('Opening quantity', row['opening_quantity']),
            _pair('Period movement', row['period_change']),
            _pair('Closing quantity', row['closing_quantity']),
          ] else if (widget.kind == DailyReportKind.saleStockProfit) ...[
            _pair('Opening quantity', row['opening_quantity']),
            _pair('Period change', row['period_change']),
            _pair('Closing quantity', row['closing_quantity']),
            _pair('Sale quantity', row['sale_quantity']),
            _pair('Sale amount', row['sale_amount'], monetary: true),
            _pair('Cost of sales', row['cost_of_sales'],
              monetary: true, optional: true),
            if (row['sale_amount'] != null)
              _pair('Gross profit', row['gross_profit'],
                monetary: true, optional: true),
          ] else if (widget.kind == DailyReportKind.businessGroups) ...[
            _pair('Products', row['products']),
            _pair('Sales quantity', row['sale_quantity']),
            _pair('Sales amount', row['sale_amount'], monetary: true),
            _pair('Purchase quantity', row['purchase_quantity']),
            _pair('Purchase amount', row['purchase_amount'], monetary: true),
            _pair('Stock change', row['stock_change']),
          ] else ...[
            _pair('Sale quantity', row['sale_quantity']),
            _pair('Sale amount', row['sale_amount'], monetary: true),
            _pair('Verified cost', row['cost_amount'],
              monetary: true, optional: true),
            _pair('Gross profit', row['gross_profit'],
              monetary: true, optional: true),
            _pair('Margin %', row['margin_percent'], optional: true),
          ],
        ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activity = widget.kind == DailyReportKind.activity;
    final rows = activity
      ? recordsOf(report[stockTab ? 'stock' : 'documents'])
      : recordsOf(report['rows']);
    return Scaffold(
      appBar: AppBar(title: Text(widget.kind.title), actions: [
        IconButton(onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
      ]),
      body: RefreshIndicator(onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          SectionHeading(widget.kind.title),
          OutlinedButton.icon(onPressed: _pickPeriod,
            icon: const Icon(Icons.date_range_rounded),
            label: Text('${_iso(period.start)} — ${_iso(period.end)}')),
          if (!activity && categories.isNotEmpty)
            _selectMaster('Category', categories, categoryUlid,
              (v) => setState(() => categoryUlid = v)),
          if (!activity && brands.isNotEmpty)
            _selectMaster('Brand', brands, brandUlid,
              (v) => setState(() => brandUlid = v)),
          if (widget.kind == DailyReportKind.businessGroups)
            Padding(padding: const EdgeInsets.only(top: 10),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'category',
                    label: Text('By Category')),
                  ButtonSegment(value: 'brand',
                    label: Text('By Brand')),
                ],
                selected: {groupBy},
                onSelectionChanged: (selection) {
                  setState(() => groupBy = selection.first);
                  load();
                },
              )),
          if (activity) Padding(padding: const EdgeInsets.only(top: 10),
            child: Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('Documents'),
                selected: !stockTab,
                onSelected: (_) => setState(() => stockTab = false)),
              ChoiceChip(label: const Text('Stock movements'),
                selected: stockTab,
                onSelected: (_) => setState(() => stockTab = true)),
            ]),
          ),
          if (optionsError != null && !activity)
            Padding(padding: const EdgeInsets.only(top: 6),
              child: Text('Filters unavailable: $optionsError',
                style: TextStyle(fontSize: 11,
                  color: scheme.onSurfaceVariant))),
          const SizedBox(height: 13),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else ...[
            _totals(),
            const SizedBox(height: 16),
            SectionHeading(activity && stockTab
              ? 'Stock positions' : 'Report entries',
              trailing: Text('${rows.length} records',
                style: TextStyle(fontSize: 11,
                  color: scheme.onSurfaceVariant))),
            if (rows.isEmpty) const EmptyState(
              title: 'No matching records',
              subtitle: 'Try another date range or filter.')
            else ...rows.map(_row),
            if (report['limitations'] is List)
              for (final note in report['limitations'] as List)
                Padding(padding: const EdgeInsets.only(top: 7),
                  child: Text(note.toString(), style: TextStyle(
                    fontSize: 10.5, color: scheme.onSurfaceVariant))),
          ],
          const SizedBox(height: 22),
        ])),
    );
  }
}
