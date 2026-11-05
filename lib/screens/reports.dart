import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'history.dart';
import 'trial_balance.dart';
import 'cash_book.dart';
import 'financial_statements.dart';
import 'stock_status.dart';
import 'product_ledger.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.app});
  final AppController app;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool loading = true;
  String? error;
  String tab = 'sales';
  DateTimeRange period = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now());
  List<Map<String, dynamic>> records = [];
  int totalRecords = 0;
  int version = 0;
  @override
  void initState() { super.initState(); load(); }

  String date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> selectPeriod() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 2)), initialDateRange: period);
    if (range == null || !mounted) return;
    setState(() => period = range);
    await load();
  }

  Future<void> load() async {
    final request = ++version;
    setState(() {loading = true; error = null;});
    try {
      final params = <String, String>{
        'per_page': '100', 'date_from': date(period.start), 'date_to': date(period.end),
      };
      final route = switch (tab) {
        'products' => '/api/sales/product-wise',
        'due' => '/api/sales',
        _ => '/api/sales',
      };
      if (tab == 'due') params['due_only'] = '1';
      final response = await widget.app.api.get(Uri(path: route, queryParameters: params).toString());
      if (!mounted || request != version) return;
      setState(() {
        records = recordsOf(response);
        totalRecords = int.tryParse(field(objectOf(objectOf(response)['meta'])['total'])) ?? records.length;
      });
    } catch (e) { if (mounted && request == version) setState(() => error = e.toString()); }
    finally { if (mounted && request == version) setState(() => loading = false); }
  }

  Decimal sum(String key) {
    var total = Decimal.zero;
    for (final row in records) total += Decimal.tryParse(field(row[key])) ?? Decimal.zero;
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    final sampleCount = records.length;
    final isProduct = tab == 'products';
    final grandTotal = sum(isProduct ? 'amount' : 'net_sale_total');
    final outstanding = sum('balance_due');
    final values = records.take(9).toList().reversed.toList();
    return RefreshIndicator(onRefresh: load, child: ListView(
      padding: const EdgeInsets.all(16), children: [
        const SectionHeading('Reports & Insights'),
        const SectionHeading('Available reports'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (app.hasPermission('reports.accounting')) ...[
            ActionChip(
              avatar: const Icon(Icons.balance_outlined, size: 17),
              label: const Text('Trial Balance'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => TrialBalanceScreen(app: app))),
            ),
            ActionChip(
              avatar: const Icon(Icons.account_balance_wallet_outlined, size: 17),
              label: const Text('Cash Book'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => CashBookReportScreen(app: app))),
            ),
            ActionChip(
              avatar: const Icon(Icons.account_balance_outlined, size: 17),
              label: const Text('Balance Sheet'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => FinancialStatementScreen(
                  app: app, kind: FinancialStatementKind.balanceSheet))),
            ),
            ActionChip(
              avatar: const Icon(Icons.show_chart_rounded, size: 17),
              label: const Text('Income Statement'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => FinancialStatementScreen(
                  app: app, kind: FinancialStatementKind.incomeStatement))),
            ),
          ],
          if (app.hasPermission('reports.inventory')) ...[
            ActionChip(
              avatar: const Icon(Icons.warehouse_outlined, size: 17),
              label: const Text('Stock Status'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => StockStatusReport(app: app))),
            ),
            ActionChip(
              avatar: const Icon(Icons.receipt_long_outlined, size: 17),
              label: const Text('Product Ledger'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProductLedgerScreen(app: app))),
            ),
          ],
        ]),
        const SizedBox(height: 14),
        GradientHero(appearance: app.appearance, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.analytics_outlined, color: Colors.white, size: 32),
              Spacer(), Icon(Icons.auto_graph, color: Colors.white70, size: 30)]),
            const SizedBox(height: 13),
            const Text('Live business reports', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 5),
            Text('$totalRecords ${isProduct ? 'line items' : 'invoices'}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 25)),
            const Text('Current branch · Server-authorized records',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        const SizedBox(height: 13),
        OutlinedButton.icon(onPressed: selectPeriod, icon: const Icon(Icons.date_range_outlined),
          label: Text('${date(period.start)}  —  ${date(period.end)}')),
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final item in [('sales', 'Sales'), ('products', 'Product wise'), ('due', 'Outstanding')])
            Padding(padding: const EdgeInsets.only(right: 9), child: ChoiceChip(
              label: Text(item.$2), selected: tab == item.$1,
              onSelected: (_) { setState(() => tab = item.$1); load(); })),
        ])),
        const SizedBox(height: 10),
        if (loading) pageLoading()
        else if (error != null) FailureState(message: error!, retry: load)
        else ...[
          Row(children: [
            Expanded(child: BpStatCard(icon: Icons.receipt_long_outlined,
              caption: 'Fetched records', value: '$sampleCount', hint: 'of $totalRecords matching')),
            const SizedBox(width: 10),
            Expanded(child: BpStatCard(icon: Icons.payments_outlined,
              caption: isProduct ? 'Line net sum' : 'Invoice net sum',
              value: money(grandTotal, app.currency),
              hint: 'Fetched records only')),
          ]),
          if (!isProduct) ...[
            const SizedBox(height: 10),
            BpStatCard(icon: Icons.pending_actions_outlined, caption: 'Unpaid on fetched invoices',
              value: money(outstanding, app.currency), hint: 'Not a full-period total when more pages exist'),
          ],
          const SizedBox(height: 18),
          const SectionHeading('Recent invoice amounts'),
          Surface(child: records.isEmpty ? const EmptyState(title: 'No records for selected period')
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(height: 148, width: double.infinity,
                child: CustomPaint(painter: _ReportLinePainter(
                  values: values.map((row) => (Decimal.tryParse(field(row[isProduct ? 'amount' : 'grand_total']))
                    ?? Decimal.zero).toDouble()).toList(), color: scheme.primary))),
              const SizedBox(height: 14),
              ...records.take(5).map((row) => Padding(padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Icon(Icons.receipt_outlined, color: scheme.primary, size: 17),
                  const SizedBox(width: 9),
                  Expanded(child: Text(field(row[isProduct ? 'sale_number' : 'document_number']),
                    style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text(money(row[isProduct ? 'amount' : 'grand_total'], app.currency),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ]))),
            ])),
          const SizedBox(height: 10),
          Text('Summary and chart use at most the first 100 matching API records. No invented profit, growth or full-period turnover figures.',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
            DataListScreen(app: app, title: 'Sales invoices', path: '/api/sales?per_page=25',
              nameKey: 'document_number', subtitleKey: 'sale_date', amountKey: 'grand_total',
              detailPrefix: '/api/sales'))),
            icon: const Icon(Icons.open_in_new), label: const Text('View invoice records')),
        ],
        const SizedBox(height: 20),
      ]));
  }
}

class _ReportLinePainter extends CustomPainter {
  _ReportLinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = color.withValues(alpha: .12)..strokeWidth = 1;
    for (var line = 1; line < 5; line++) {
      final y = size.height * line / 5;
      canvas.drawLine(Offset.zero.translate(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    var maxValue = values.reduce((a,b) => a > b ? a : b);
    if (maxValue <= 0) maxValue = 1;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width * .5 : size.width * i / (values.length - 1);
      final y = size.height - (values[i].clamp(0, maxValue) / maxValue) * size.height * .85 - 6;
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 2.6
      ..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant _ReportLinePainter oldDelegate) =>
    oldDelegate.values != values || oldDelegate.color != color;
}
