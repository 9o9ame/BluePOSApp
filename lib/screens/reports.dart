import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.app});
  final AppController app;
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> recent = [];
  int total = 0;
  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await widget.app.api.get('/api/sales?per_page=25');
      if (!mounted) return;
      setState(() {
        recent = recordsOf(response);
        total = int.tryParse(field(objectOf(objectOf(response)['meta'])['total'])) ?? recent.length;
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
    final count = recent.length;
    var recentNet = Decimal.zero;
    var recentDue = Decimal.zero;
    for (final row in recent) {
      recentNet += Decimal.tryParse(field(row['net_sale_total'])) ?? Decimal.zero;
      recentDue += Decimal.tryParse(field(row['balance_due'])) ?? Decimal.zero;
    }
    return RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(16), children: [
      const SectionHeading('Sales reports'),
      GradientHero(appearance: widget.app.appearance, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.insights_rounded, color: Colors.white, size: 31),
          const SizedBox(height: 10),
          const Text('Business insights', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text('$total sales invoices', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const Text('Current branch · Server records', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      )),
      const SizedBox(height: 14),
      if (loading) pageLoading()
      else if (error != null) FailureState(message: error!, retry: load)
      else ...[
        Row(children: [
          Expanded(child: Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.account_balance_wallet_outlined),
            const SizedBox(height: 8),
            Text(money(recentNet), style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('Net of latest $count invoices', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ]))),
          const SizedBox(width: 10),
          Expanded(child: Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.pending_actions_outlined),
            const SizedBox(height: 8),
            Text(money(recentDue), style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('Due on latest $count invoices', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ]))),
        ]),
        const SizedBox(height: 20),
        const SectionHeading('Latest invoice amounts'),
        Surface(child: recent.isEmpty
          ? const EmptyState(title: 'No invoice data')
          : Column(children: recent.take(7).map((row) {
            final totalValue = Decimal.tryParse(field(row['grand_total'])) ?? Decimal.zero;
            final ratio = recentNet > Decimal.zero
                ? (totalValue / recentNet).toDouble() : 0.0;
            return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(
              children: [
                Row(children: [Expanded(child: Text(field(row['document_number']),
                    style: const TextStyle(fontSize: 12))),
                  Text(money(row['grand_total']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 5),
                LinearProgressIndicator(value: ratio.clamp(0.0, 1.0), minHeight: 7,
                  borderRadius: BorderRadius.circular(12)),
              ],
            ));
          }).toList())),
        const SizedBox(height: 12),
        Text('These values are calculated from fetched invoices only, not a complete-period financial statement.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
      ],
      const SizedBox(height: 22),
    ]));
  }
}
