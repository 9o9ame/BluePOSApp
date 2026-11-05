import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key, required this.app});
  final AppController app;
  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  DateTime asOf = DateTime.now();
  String grouping = 'main_account';
  bool loading = true;
  String? error;
  Map<String, dynamic> data = const {};

  @override
  void initState() { super.initState(); reload(); }

  String _date(DateTime date) =>
    date.year.toString().padLeft(4, '0') + '-' +
    date.month.toString().padLeft(2, '0') + '-' +
    date.day.toString().padLeft(2, '0');

  Future<void> reload() async {
    setState(() { loading = true; error = null; });
    try {
      final route = Uri(path: '/api/reports/accounting/trial-balance',
        queryParameters: {
          'as_of_date': _date(asOf),
          'group_by': grouping,
          'arrange_by': 'code_asc',
        });
      final response = objectOf(await widget.app.api.get(route.toString()));
      if (mounted) setState(() => data = response);
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: asOf, firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
    );
    if (picked != null && mounted) {
      setState(() => asOf = picked);
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = objectOf(data['totals']);
    final groups = recordsOf(data['groups']);
    return Scaffold(
      appBar: AppBar(title: const Text('Trial Balance'),
        actions: [IconButton(onPressed: reload,
          icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh')]),
      body: RefreshIndicator(onRefresh: reload, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Accounting • Trial Balance'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: selectDate,
            icon: const Icon(Icons.event_rounded),
            label: Text('As of ' + _date(asOf)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: grouping,
            decoration: const InputDecoration(labelText: 'Group by'),
            items: const [
              DropdownMenuItem(value: 'main_account',
                child: Text('Main Account')),
              DropdownMenuItem(value: 'account_type',
                child: Text('Account Type')),
              DropdownMenuItem(value: 'account_type_head',
                child: Text('Account Type Head')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => grouping = value);
                reload();
              }
            },
          ),
          const SizedBox(height: 14),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: reload)
          else ...[
            Row(children: [
              Expanded(child: BpStatCard(
                icon: Icons.south_west_rounded,
                caption: 'Total debit',
                value: money(totals['debit'], widget.app.currency),
                hint: 'Server calculated')),
              const SizedBox(width: 9),
              Expanded(child: BpStatCard(
                icon: Icons.north_east_rounded,
                caption: 'Total credit',
                value: money(totals['credit'], widget.app.currency),
                hint: 'Server calculated')),
            ]),
            const SizedBox(height: 9),
            Surface(child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Difference',
                    style: TextStyle(fontSize: 11)),
                  Text(money(totals['difference'], widget.app.currency),
                    style: const TextStyle(fontWeight: FontWeight.w900,
                      fontSize: 18)),
                ])),
              Text(field(totals['difference_side'], '—'),
                style: TextStyle(fontSize: 18,
                  color: scheme.primary, fontWeight: FontWeight.w900)),
            ])),
            const SizedBox(height: 16),
            if (groups.isEmpty) const EmptyState(title: 'No ledger entries')
            else ...groups.map((group) {
              final rows = recordsOf(group['rows']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Surface(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(field(group['label'], 'Accounts'),
                      style: const TextStyle(fontWeight: FontWeight.w900,
                        fontSize: 14)),
                    const Divider(height: 20),
                    Row(children: const [
                      Expanded(child: Text('Account',
                        style: TextStyle(fontSize: 10))),
                      Text('Debit             Credit',
                        style: TextStyle(fontSize: 10)),
                    ]),
                    const SizedBox(height: 10),
                    for (final row in rows) Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field(objectOf(row['account'])['name']),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 11)),
                            Text(field(objectOf(row['account'])['code']),
                              style: TextStyle(fontSize: 10,
                                color: scheme.onSurfaceVariant)),
                          ]),
                        )),
                        SizedBox(width: 89,
                          child: Text(field(row['debit'], '0.0000'),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 10))),
                        const SizedBox(width: 10),
                        SizedBox(width: 89,
                          child: Text(field(row['credit'], '0.0000'),
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 10))),
                      ]),
                    ),
                  ],
                )),
              );
            }),
          ],
          const SizedBox(height: 24),
        ],
      )),
    );
  }
}
