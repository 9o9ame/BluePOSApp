import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'receipt.dart';

class DataListScreen extends StatefulWidget {
  const DataListScreen({super.key, required this.app, required this.title, required this.path,
    this.nameKey = 'name', this.subtitleKey = 'code', this.amountKey, this.detailPrefix});
  final AppController app;
  final String title;
  final String path;
  final String nameKey;
  final String subtitleKey;
  final String? amountKey;
  final String? detailPrefix;

  @override
  State<DataListScreen> createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = [];
  int count = 0;
  int page = 1;
  bool loadingMore = false;
  final search = TextEditingController();
  @override
  void dispose() { search.dispose(); super.dispose(); }
  @override
  void initState() { super.initState(); reload(); }
  Future<void> reload({bool more = false}) async {
    if (more && (loadingMore || loading || rows.length >= count)) return;
    setState(() { if (more) { loadingMore = true; } else { loading = true; error = null; page = 1; } });
    try {
      final next = more ? page + 1 : 1;
      final uri = Uri.parse(widget.path);
      final params = Map<String, String>.from(uri.queryParameters);
      if (params.containsKey('per_page')) params['page'] = '$next';
      final path = uri.replace(queryParameters: params.isEmpty ? null : params).toString();
      final response = await widget.app.api.get(path);
      if (!mounted) return;
      final list = recordsOf(response);
      setState(() {
        rows = more ? [...rows, ...list] : list;
        count = int.tryParse(field(objectOf(objectOf(response)['meta'])['total'])) ?? rows.length;
        page = next;
      });
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() { loading = false; loadingMore = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(onPressed: reload, icon: const Icon(Icons.refresh), tooltip:'Refresh'),
      ]),
      body: RefreshIndicator(onRefresh: reload, child: ListView(padding: const EdgeInsets.all(16), children: [
        SectionHeading('$count records'),
        TextField(controller: search, onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search),
            hintText: 'Search loaded records')),
        const SizedBox(height: 14),
        if (loading) pageLoading()
        else if (error != null) FailureState(message: error!, retry: reload)
        else if (rows.isEmpty) EmptyState(title: 'No ${widget.title.toLowerCase()} yet')
        else ...rows.where((r) => search.text.trim().isEmpty ||
          '${field(r[widget.nameKey])} ${field(r[widget.subtitleKey])}'.toLowerCase()
            .contains(search.text.trim().toLowerCase())).map((r) => Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Surface(child: Row(children: [
            CircleAvatar(backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.receipt_long_outlined, color: scheme.onPrimaryContainer)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(field(r[widget.nameKey], '—'), style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(field(r[widget.subtitleKey]), style: TextStyle(fontSize: 12,
                color: scheme.onSurfaceVariant)),
            ])),
            if (widget.amountKey != null) Text(r[widget.amountKey] == null ? '—' : money(r[widget.amountKey]),
              style: const TextStyle(fontWeight: FontWeight.w700)),
            if (widget.detailPrefix != null) IconButton(icon: const Icon(Icons.chevron_right),
              onPressed: () => showDetail(r)),
          ])))),
        if (rows.length < count && !loading) Padding(padding: const EdgeInsets.all(12),
          child: OutlinedButton(onPressed: loadingMore ? null : () => reload(more: true),
            child: Text(loadingMore ? 'Loading…' : 'Load more records'))),
      ])),
    );
  }

  Future<void> showDetail(Map<String, dynamic> row) async {
    final ulid = field(row['ulid']);
    if (ulid.length != 26) return;
    try {
      final result = await widget.app.api.get('${widget.detailPrefix}/$ulid');
      if (!mounted) return;
      final source = objectOf(result);
      final details = source.containsKey('ulid') ? source : objectOf(source['data']);
      await showModalBottomSheet<void>(context: context, showDragHandle: true,
        isScrollControlled: true, builder: (ctx) => SafeArea(child: Padding(
          padding: const EdgeInsets.all(20), child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field(details[widget.nameKey], widget.title),
                style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final key in ['sale_date', 'status', 'customer_name', 'grand_total',
                'paid_amount', 'balance_due', 'net_sale_total'])
                if (details[key] != null) Padding(padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [Expanded(child: Text(key.replaceAll('_', ' '))),
                    Flexible(child: Text(field(details[key]), textAlign: TextAlign.right))])),
              const SizedBox(height: 20),
              if (widget.detailPrefix == '/api/sales') FilledButton.icon(
                onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReceiptScreen(app: widget.app, saleUlid: ulid))); },
                icon: const Icon(Icons.receipt_long_outlined), label: const Text('View / Print Receipt')),
            ],
          )),
        )));
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }
}
