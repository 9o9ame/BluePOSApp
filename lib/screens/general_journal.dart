import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Server-authorized posted General Journal report. The preview POST is
/// read-only and is not a financial posting operation.
class GeneralJournalReportScreen extends StatefulWidget {
  const GeneralJournalReportScreen({super.key, required this.app});
  final AppController app;
  @override
  State<GeneralJournalReportScreen> createState() =>
      _GeneralJournalReportScreenState();
}

class _GeneralJournalReportScreenState extends State<GeneralJournalReportScreen> {
  DateTimeRange period = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );
  bool loading = true;
  bool onlyProblematic = false;
  bool narration = true;
  String? error;
  int serial = 0;
  Map<String, dynamic> report = const {};

  @override
  void initState() {
    super.initState();
    load();
  }

  String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> chooseRange() async {
    final choice = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
      initialDateRange: period,
    );
    if (!mounted || choice == null) return;
    setState(() => period = choice);
    await load();
  }

  Future<void> load() async {
    final request = ++serial;
    setState(() { loading = true; error = null; });
    try {
      final result = objectOf(await widget.app.api.post(
        '/api/reports/accounting/general-journal/preview', {
          'from': _iso(period.start),
          'to': _iso(period.end),
          'only_problematic': onlyProblematic,
          'narration': narration,
          'print_format': 'transaction_wise',
        }));
      if (mounted && request == serial) setState(() => report = result);
    } catch (ex) {
      if (mounted && request == serial) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && request == serial) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entries = recordsOf(report['entries']);
    final totals = objectOf(report['totals']);
    return Scaffold(
      appBar: AppBar(title: const Text('General Journal'), actions: [
        IconButton(onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
      ]),
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Posted journal entries'),
          OutlinedButton.icon(
            onPressed: chooseRange,
            icon: const Icon(Icons.date_range_rounded),
            label: Text('${_iso(period.start)} — ${_iso(period.end)}'),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: onlyProblematic,
            contentPadding: EdgeInsets.zero,
            title: const Text('Show unbalanced vouchers only'),
            onChanged: (value) {
              setState(() => onlyProblematic = value);
              load();
            },
          ),
          SwitchListTile.adaptive(
            value: narration,
            contentPadding: EdgeInsets.zero,
            title: const Text('Show narration'),
            onChanged: (value) {
              setState(() => narration = value);
              load();
            },
          ),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else ...[
            Row(children: [
              Expanded(child: BpStatCard(
                icon: Icons.south_west_rounded,
                caption: 'Debit',
                value: money(totals['debit'], widget.app.currency),
                hint: 'Fetched report entries')),
              const SizedBox(width: 9),
              Expanded(child: BpStatCard(
                icon: Icons.north_east_rounded,
                caption: 'Credit',
                value: money(totals['credit'], widget.app.currency),
                hint: 'Fetched report entries')),
            ]),
            const SizedBox(height: 12),
            SectionHeading('Vouchers',
              trailing: Text('${entries.length} shown',
                style: TextStyle(fontSize: 11,
                  color: colors.onSurfaceVariant))),
            if (report['has_more'] == true)
              Text(field(report['note'], 'Report has more matching entries. Narrow the date range.'),
                style: TextStyle(color: colors.error, fontSize: 11)),
            if (entries.isEmpty)
              const EmptyState(title: 'No posted journal entries',
                subtitle: 'Try another period or filter.')
            else ...entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Surface(padding: const EdgeInsets.all(13),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(
                        field(entry['voucher_number'], 'Journal entry'),
                        style: const TextStyle(fontWeight: FontWeight.w900))),
                      Text(field(entry['entry_date']),
                        style: TextStyle(fontSize: 11,
                          color: colors.onSurfaceVariant)),
                    ]),
                    Text(field(entry['document_type']),
                      style: TextStyle(fontSize: 11,
                        color: colors.onSurfaceVariant)),
                    if (narration && field(entry['narration']).isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 5),
                        child: Text(field(entry['narration']),
                          style: const TextStyle(fontSize: 11))),
                    const Divider(height: 20),
                    for (final line in recordsOf(entry['lines']))
                      Padding(padding: const EdgeInsets.only(bottom: 9),
                        child: Row(children: [
                          Expanded(child: Text(
                            field(objectOf(line['account'])['name'], 'Account'),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11))),
                          const SizedBox(width: 8),
                          Text(field(line['debit'], '0.0000'),
                            style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 8),
                          Text(field(line['credit'], '0.0000'),
                            style: const TextStyle(fontSize: 10)),
                        ])),
                    const Divider(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Dr ${money(objectOf(entry['totals'])['debit'], widget.app.currency)}',
                          style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700)),
                        const SizedBox(width: 12),
                        Text('Cr ${money(objectOf(entry['totals'])['credit'], widget.app.currency)}',
                          style: const TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w700)),
                      ]),
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
