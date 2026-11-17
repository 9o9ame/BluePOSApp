import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import 'reference_surface.dart';

/// Uses the existing tenant/branch-authorized posted party ledger API.
/// No financial values are calculated from the mobile client's party form.
class BpPartyLedgerSummary extends StatefulWidget {
  const BpPartyLedgerSummary({
    super.key, required this.app, required this.partyType,
    required this.partyUlid,
  });

  final AppController app;
  final String partyType;
  final String partyUlid;

  @override
  State<BpPartyLedgerSummary> createState() => _BpPartyLedgerSummaryState();
}

class _BpPartyLedgerSummaryState extends State<BpPartyLedgerSummary> {
  bool loading = true;
  String? error;
  Map<String, dynamic> totals = {};
  List<Map<String, dynamic>> recent = const [];
  int totalRows = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(widget.partyUlid) ||
        !const {'customer', 'vendor'}.contains(widget.partyType)) {
      if (mounted) setState(() {
        loading = false;
        error = 'Invalid party reference.';
      });
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final base = '/api/parties/${widget.partyUlid}/ledger'
          '?type=${widget.partyType}&per_page=100';
      var response = objectOf(await widget.app.api.get('$base&page=1'));
      final pagination = objectOf(response['pagination']);
      final lastPage = int.tryParse(field(pagination['last_page'])) ?? 1;
      if (lastPage > 1) {
        response = objectOf(await widget.app.api.get('$base&page=$lastPage'));
      }
      if (!mounted) return;
      final rows = (response['rows'] is List)
          ? (response['rows'] as List).map(objectOf).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        totals = objectOf(response['totals']);
        totalRows = int.tryParse(field(pagination['total'])) ?? rows.length;
        recent = rows.reversed.take(5).toList();
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    final title = widget.partyType == 'vendor'
        ? 'Recent Purchases / Ledger' : 'Recent Transactions';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: style.card(radius: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 16, color: style.ink))),
          if (!loading && error == null)
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BpPartyLedgerScreen(
                  app: widget.app, partyType: widget.partyType,
                  partyUlid: widget.partyUlid))),
              child: const Text('View Ledger')),
        ]),
        if (loading) const Center(child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator()))
        else if (error != null)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ledger unavailable: $error',
              style: TextStyle(fontSize: 11, color: style.muted)),
            TextButton(onPressed: load, child: const Text('Retry')),
          ])
        else ...[
          BpReferenceDetailLine(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Posted closing balance',
            value: field(totals['closing_balance'], 'Not available')),
          if (recent.isEmpty)
            Text('No posted ledger entries for this party.',
              style: TextStyle(fontSize: 11, color: style.muted)),
          for (final entry in recent)
            _BpLedgerEntryRow(entry: entry),
          if (totalRows > recent.length)
            Text('$totalRows posted ledger lines',
              style: TextStyle(fontSize: 10, color: style.muted)),
        ],
      ]),
    );
  }
}

/// Read-only view of actual posted ledger entries. Writes remain server-owned.
class BpPartyLedgerScreen extends StatefulWidget {
  const BpPartyLedgerScreen({
    super.key, required this.app, required this.partyType,
    required this.partyUlid,
  });
  final AppController app;
  final String partyType;
  final String partyUlid;

  @override
  State<BpPartyLedgerScreen> createState() => _BpPartyLedgerScreenState();
}

class _BpPartyLedgerScreenState extends State<BpPartyLedgerScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = const [];
  int page = 1;
  int lastPage = 1;
  Map<String, dynamic> totals = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final result = objectOf(await widget.app.api.get(
        '/api/parties/${widget.partyUlid}/ledger'
        '?type=${widget.partyType}&page=$page&per_page=50'));
      if (!mounted) return;
      final pagination = objectOf(result['pagination']);
      setState(() {
        rows = (result['rows'] is List)
            ? (result['rows'] as List).map(objectOf).toList()
            : <Map<String, dynamic>>[];
        totals = objectOf(result['totals']);
        lastPage = int.tryParse(field(pagination['last_page'])) ?? 1;
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Scaffold(
      backgroundColor: style.page,
      appBar: const BpReferenceSubpageAppBar(title: 'Party Ledger'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: BpReferenceDetailLine(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Posted closing balance',
            value: field(totals['closing_balance'], 'Not available'))),
        Expanded(child: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
            ? Center(child: TextButton(onPressed: load,
                child: Text('Retry: $error')))
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) =>
                  _BpLedgerEntryRow(entry: rows[index]))),
        if (lastPage > 1)
          SafeArea(top: false, child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(onPressed: page <= 1 ? null : () {
                page--; load();
              }, child: const Text('Previous')),
              Text('Page $page / $lastPage'),
              TextButton(onPressed: page >= lastPage ? null : () {
                page++; load();
              }, child: const Text('Next')),
            ])),
      ]),
    );
  }
}

class _BpLedgerEntryRow extends StatelessWidget {
  const _BpLedgerEntryRow({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: style.card(radius: 10),
      child: Row(children: [
        const Icon(Icons.receipt_long_outlined, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field(entry['trans_no'], field(entry['doc'], 'Entry')),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                color: style.ink)),
            Text(field(entry['date']), style: TextStyle(
              fontSize: 10, color: style.muted)),
          ])),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Dr ${field(entry['debit'], '0.0000')}',
            style: TextStyle(fontSize: 10, color: style.ink)),
          Text('Cr ${field(entry['credit'], '0.0000')}',
            style: TextStyle(fontSize: 10, color: style.ink)),
        ]),
      ]),
    );
  }
}
