import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Read-only financial statements from the existing accounting preview APIs.
/// The device never infers missing COGS, stock valuation, or report totals.
enum FinancialStatementKind { balanceSheet, incomeStatement }

class FinancialStatementScreen extends StatefulWidget {
  const FinancialStatementScreen({
    super.key, required this.app, required this.kind,
  });
  final AppController app;
  final FinancialStatementKind kind;

  @override
  State<FinancialStatementScreen> createState() => _FinancialStatementScreenState();
}

class _FinancialStatementScreenState extends State<FinancialStatementScreen> {
  DateTime asOf = DateTime.now();
  bool loading = true;
  bool summarized = true;
  String? error;
  Map<String, dynamic> report = const {};
  int requestSequence = 0;

  bool get balance => widget.kind == FinancialStatementKind.balanceSheet;
  String get title => balance ? 'Balance Sheet' : 'Income Statement';

  @override
  void initState() {
    super.initState();
    load();
  }

  String _date(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

  Future<void> selectDate() async {
    final selection = await showDatePicker(
      context: context, initialDate: asOf,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
    );
    if (selection == null || !mounted) return;
    setState(() => asOf = selection);
    await load();
  }

  Future<void> load() async {
    final requestId = ++requestSequence;
    setState(() { loading = true; error = null; });
    try {
      final endpoint = balance
        ? '/api/reports/accounting/balance-sheet/preview'
        : '/api/reports/accounting/income-statement/preview';
      final response = objectOf(await widget.app.api.post(endpoint, {
        'as_of_date': _date(asOf),
        if (balance) 'summarized': summarized,
      }));
      if (mounted && requestId == requestSequence) {
        setState(() => report = response);
      }
    } catch (ex) {
      if (mounted && requestId == requestSequence) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && requestId == requestSequence) {
        setState(() => loading = false);
      }
    }
  }

  Widget _line(Map<String, dynamic> row, {bool isBalance = false}) {
    final scheme = Theme.of(context).colorScheme;
    final name = field(objectOf(row['account'])['name'], 'Account');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12))),
        const SizedBox(width: 8),
        if (isBalance) ...[
          Text(field(row['debit'], '0.0000'),
            style: TextStyle(color: scheme.primary, fontSize: 11)),
          const SizedBox(width: 11),
          Text(field(row['credit'], '0.0000'),
            style: const TextStyle(fontSize: 11)),
        ] else Text(money(row['amount'], widget.app.currency),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );
  }

  Widget _balanceGroups() {
    final groups = recordsOf(report['groups']);
    if (groups.isEmpty) {
      return const EmptyState(title: 'No posted ledger balances',
        subtitle: 'Try another reporting date.');
    }
    return Column(children: [
      for (final group in groups) Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field(group['name'], 'Account group'),
              style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('Debit ${money(group['debit'], widget.app.currency)}'
              '   •   Credit ${money(group['credit'], widget.app.currency)}',
              style: const TextStyle(fontSize: 11)),
            const Divider(height: 20),
            for (final section in recordsOf(group['sections'])) ...[
              Text(field(section['name'], 'Section'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              for (final row in recordsOf(section['rows']))
                _line(row, isBalance: true),
              const Divider(height: 16),
            ],
          ],
        )),
      ),
    ]);
  }

  Widget _incomeSections() {
    final sections = recordsOf(report['sections']);
    if (sections.isEmpty) {
      return const EmptyState(title: 'No posted income or expense entries',
        subtitle: 'Try another reporting date.');
    }
    return Column(children: [
      for (final section in sections) Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field(section['name'], 'Account group'),
              style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(field(section['class']),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11)),
            for (final row in recordsOf(section['rows'])) _line(row),
            const Divider(height: 16),
            Text('Section amount: ${money(section['amount'], widget.app.currency)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        )),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = objectOf(report['totals']);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        IconButton(onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
      ]),
      body: RefreshIndicator(onRefresh: load, child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeading(title),
          OutlinedButton.icon(onPressed: selectDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text('As of ${_date(asOf)}')),
          if (balance) SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Summarized report'),
            value: summarized,
            onChanged: (enabled) {
              setState(() => summarized = enabled);
              load();
            },
          ),
          const SizedBox(height: 12),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else ...[
            if (balance) ...[
              Row(children: [
                Expanded(child: BpStatCard(
                  icon: Icons.south_west_rounded,
                  caption: 'Debits', value: money(totals['debit'], widget.app.currency),
                  hint: 'Server calculated')),
                const SizedBox(width: 10),
                Expanded(child: BpStatCard(
                  icon: Icons.north_east_rounded,
                  caption: 'Credits', value: money(totals['credit'], widget.app.currency),
                  hint: 'Server calculated')),
              ]),
              const SizedBox(height: 10),
              BpStatCard(icon: Icons.balance_outlined,
                caption: 'Difference',
                value: money(totals['difference'], widget.app.currency),
                hint: field(totals['difference_side'])),
            ] else BpStatCard(
              icon: Icons.account_balance_outlined,
              caption: 'Net income',
              value: money(report['net_income'], widget.app.currency),
              hint: field(report['basis'], 'Posted ledger')),
            const SizedBox(height: 18),
            const SectionHeading('Report details'),
            if (balance) _balanceGroups() else _incomeSections(),
            for (final limitation in (report['limitations'] is List
              ? report['limitations'] as List : const []))
              Padding(padding: const EdgeInsets.only(top: 8),
                child: Text(limitation.toString(), style: TextStyle(
                  color: scheme.onSurfaceVariant, fontSize: 11))),
          ],
          const SizedBox(height: 22),
        ],
      )),
    );
  }
}
