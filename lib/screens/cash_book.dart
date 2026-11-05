import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Read-only cash book backed by the accounting report endpoint.
/// Totals are returned by the server, never calculated from visible rows.
class CashBookReportScreen extends StatefulWidget {
  const CashBookReportScreen({super.key, required this.app});
  final AppController app;

  @override
  State<CashBookReportScreen> createState() => _CashBookReportScreenState();
}

class _CashBookReportScreenState extends State<CashBookReportScreen> {
  DateTimeRange period = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );
  bool loading = true;
  bool includeBank = false;
  String? error;
  String? accountUlid;
  int sequence = 0;
  Map<String, dynamic> report = const {};
  List<Map<String, dynamic>> accounts = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  String _iso(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    final requestId = ++sequence;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // Only the server may decide the set of authorized cash/bank accounts.
      final accountsResponse = objectOf(await widget.app.api.get(
        '/api/reports/accounting/cash-book/accounts',
      ));
      if (!mounted || requestId != sequence) return;
      final available = recordsOf(accountsResponse['accounts'])
          .where((row) => row['is_cash'] == true ||
              (includeBank && row['is_bank'] == true))
          .toList();
      final selected = available.any(
        (account) => field(account['ulid']) == accountUlid,
      ) ? accountUlid : null;
      final parameters = <String, String>{
        'start_date': _iso(period.start),
        'end_date': _iso(period.end),
        'include_bank': includeBank ? '1' : '0',
        'group_by': 'none',
      };
      if (selected != null) parameters['account_ulids[0]'] = selected;
      final response = objectOf(await widget.app.api.get(
        Uri(path: '/api/reports/accounting/cash-book',
          queryParameters: parameters).toString(),
      ));
      if (!mounted || requestId != sequence) return;
      setState(() {
        accounts = available;
        accountUlid = selected;
        report = response;
      });
    } catch (ex) {
      if (mounted && requestId == sequence) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && requestId == sequence) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> selectPeriod() async {
    final choice = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
      initialDateRange: period,
    );
    if (choice == null || !mounted) return;
    setState(() => period = choice);
    await load();
  }

  Widget _figure(IconData icon, String label, dynamic amount) => Expanded(
    child: BpStatCard(icon: icon, caption: label,
      value: money(amount, widget.app.currency),
      hint: 'Server calculated'),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totals = objectOf(report['totals']);
    final rows = recordsOf(report['rows']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Book'),
        actions: [IconButton(
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh report',
        )],
      ),
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeading('Cash & bank transactions'),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: selectPeriod,
            icon: const Icon(Icons.date_range_rounded),
            label: Text('${_iso(period.start)} — ${_iso(period.end)}'),
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            value: includeBank,
            contentPadding: EdgeInsets.zero,
            title: const Text('Include bank accounts'),
            subtitle: const Text('Show authorized bank transactions'),
            onChanged: (value) {
              setState(() => includeBank = value);
              load();
            },
          ),
          if (accounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: accounts.any(
                (account) => field(account['ulid']) == accountUlid,
              ) ? accountUlid : null,
              decoration: const InputDecoration(labelText: 'Account'),
              items: [
                const DropdownMenuItem<String>(
                  value: null, child: Text('All available accounts'),
                ),
                ...accounts.map((account) => DropdownMenuItem<String>(
                  value: field(account['ulid']),
                  child: Text(field(account['name'], 'Account'),
                    overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (value) {
                setState(() => accountUlid = value);
                load();
              },
            ),
          ],
          const SizedBox(height: 15),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else ...[
            Row(children: [
              _figure(Icons.account_balance_wallet_outlined,
                'Opening', totals['opening']),
              const SizedBox(width: 9),
              _figure(Icons.savings_outlined,
                'Closing', totals['closing']),
            ]),
            const SizedBox(height: 9),
            Row(children: [
              _figure(Icons.south_west_rounded,
                'Received', totals['received']),
              const SizedBox(width: 9),
              _figure(Icons.north_east_rounded,
                'Paid', totals['paid']),
            ]),
            const SizedBox(height: 18),
            SectionHeading('Transactions', trailing: Text(
              '${rows.length} records',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            )),
            if (rows.isEmpty) const EmptyState(
              title: 'No cash book entries',
              subtitle: 'Try another period or account.',
            )
            else ...rows.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Surface(padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(field(entry['doc'], 'Entry'),
                        style: const TextStyle(fontWeight: FontWeight.w900,
                          fontSize: 13))),
                      Text(field(entry['date'], ''),
                        style: TextStyle(color: colors.onSurfaceVariant,
                          fontSize: 11)),
                    ]),
                    const SizedBox(height: 4),
                    Text(field(entry['trans_no'], '—'),
                      style: const TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600)),
                    if (field(entry['description']).isNotEmpty)
                      Text(field(entry['description']),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant,
                          fontSize: 11)),
                    const SizedBox(height: 9),
                    Row(children: [
                      Expanded(child: Text('Received  ${money(entry['debit'], widget.app.currency)}',
                        style: const TextStyle(fontSize: 11))),
                      Expanded(child: Text('Paid  ${money(entry['credit'], widget.app.currency)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 11))),
                    ]),
                    const SizedBox(height: 5),
                    Text('Running balance  ${money(entry['balance'], widget.app.currency)}',
                      style: TextStyle(color: colors.primary,
                        fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                )),
            )),
          ],
          const SizedBox(height: 20),
        ],
      )),
    );
  }
}
