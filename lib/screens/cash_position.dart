import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Daily Cash Position from authorized posted journal data. Unsupported
/// accounting categories are explicitly shown as unavailable rather than 0.
class CashPositionScreen extends StatefulWidget {
  const CashPositionScreen({super.key, required this.app});
  final AppController app;
  @override
  State<CashPositionScreen> createState() => _CashPositionScreenState();
}

class _CashPositionScreenState extends State<CashPositionScreen> {
  DateTime selectedDate = DateTime.now();
  bool loading = true;
  String? error;
  Map<String, dynamic> summary = const {}, dashboard = const {};
  int serial = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  String iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() => selectedDate = picked);
    await load();
  }

  Future<void> load() async {
    final request = ++serial;
    setState(() { loading = true; error = null; });
    try {
      final date = iso(selectedDate);
      final cash = objectOf(await widget.app.api.get(
        '/api/cash-position/summary?date=$date'));
      final balances = objectOf(await widget.app.api.get(
        '/api/cash-position/dashboard?date=$date&days=7'));
      if (!mounted || request != serial) return;
      setState(() {
        summary = cash;
        dashboard = balances;
      });
    } catch (ex) {
      if (mounted && request == serial) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && request == serial) {
        setState(() => loading = false);
      }
    }
  }

  Widget metric(String title, dynamic value, IconData icon) =>
    Expanded(child: BpStatCard(
      icon: icon, caption: title,
      value: money(value, widget.app.currency),
      hint: 'Posted journal amounts',
    ));

  Widget account(Map<String, dynamic> row, {bool position = false}) {
    final scheme = Theme.of(context).colorScheme;
    final name = field(objectOf(row['account'])['name'], 'Account');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Surface(padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800)),
          if (position) ...[
            const SizedBox(height: 4),
            Text('Opening  ${money(row['opening'], widget.app.currency)}',
              style: const TextStyle(fontSize: 11)),
            Text('Received  ${money(row['debit'], widget.app.currency)}',
              style: const TextStyle(fontSize: 11)),
            Text('Paid  ${money(row['credit'], widget.app.currency)}',
              style: const TextStyle(fontSize: 11)),
            Text('Closing  ${money(row['closing'], widget.app.currency)}',
              style: TextStyle(fontSize: 12, color: scheme.primary,
                fontWeight: FontWeight.w800)),
          ] else Text(money(row['amount'], widget.app.currency),
            style: TextStyle(color: scheme.primary,
              fontWeight: FontWeight.w800)),
        ])),
    );
  }

  Widget group(String title, List<Map<String, dynamic>> items,
      {bool position = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeading(title, trailing: Text('${items.length} accounts',
        style: TextStyle(fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant))),
      if (items.isEmpty) const EmptyState(title: 'No matching accounts')
      else ...items.map((item) => account(item, position: position)),
      const SizedBox(height: 8),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totals = objectOf(summary['totals']);
    final positions = recordsOf(summary['positions']);
    final dayBalances = objectOf(dashboard['totals']);
    final metrics = objectOf(summary['metrics']);
    final reasons = objectOf(summary['unsupported_reasons']);
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Cash Position'),
        actions: [IconButton(onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh')]),
      body: RefreshIndicator(onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Cash and credit position'),
          OutlinedButton.icon(
            onPressed: chooseDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('Posting date: ${iso(selectedDate)}')),
          const SizedBox(height: 13),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else ...[
            Row(children: [
              metric('Opening', totals['opening'], Icons.wallet_outlined),
              const SizedBox(width: 8),
              metric('Closing', totals['closing'],
                Icons.account_balance_wallet_outlined),
            ]),
            const SizedBox(height: 9),
            Row(children: [
              metric('Received', totals['debit'],
                Icons.south_west_rounded),
              const SizedBox(width: 8),
              metric('Paid', totals['credit'],
                Icons.north_east_rounded),
            ]),
            const SizedBox(height: 12),
            SectionHeading('Activity categories',
              trailing: Text('Supported only',
                style: TextStyle(color: colors.onSurfaceVariant,
                  fontSize: 11))),
            for (final entry in metrics.entries)
              Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Surface(padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                      if (objectOf(entry.value)['supported'] == true)
                        Row(children: [
                          Expanded(child: Text('Cash  ${money(
                            objectOf(entry.value)['cash'],
                            widget.app.currency)}',
                            style: const TextStyle(fontSize: 11))),
                          Expanded(child: Text('Credit  ${money(
                            objectOf(entry.value)['credit'],
                            widget.app.currency)}',
                            style: const TextStyle(fontSize: 11))),
                        ])
                      else Text(field(reasons[entry.key],
                        'Not supported by the posted accounting data.'),
                        style: TextStyle(fontSize: 11,
                          color: colors.onSurfaceVariant)),
                    ],
                  )),
              ),
            group('Cash & bank accounts', positions, position: true),
            const SectionHeading('Posted account balances'),
            Row(children: [
              metric('Debit balances', dayBalances['debit'],
                Icons.trending_up_rounded),
              const SizedBox(width: 8),
              metric('Credit balances', dayBalances['credit'],
                Icons.trending_down_rounded),
            ]),
            const SizedBox(height: 12),
            group('Debit accounts', recordsOf(dashboard['debit_accounts'])),
            group('Credit accounts', recordsOf(dashboard['credit_accounts'])),
          ],
          const SizedBox(height: 24),
        ])),
    );
  }
}
