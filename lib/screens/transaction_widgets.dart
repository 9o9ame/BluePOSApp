import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';

/// Strict ULID boundaries for API identifiers. BIGINT database keys are never
/// transported from, or chosen by, a mobile form.
final RegExp publicUlidPattern = RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$');
bool validPublicUlid(String value) => publicUlidPattern.hasMatch(value);

String isoLocalDate(DateTime value) =>
  '${value.year.toString().padLeft(4, '0')}-'
  '${value.month.toString().padLeft(2, '0')}-'
  '${value.day.toString().padLeft(2, '0')}';

bool validPositiveDecimal(String input, int scale) {
  final regex = RegExp('^(?:0|[1-9]\\d*)(?:\\.\\d{1,$scale})?\$');
  final value = Decimal.tryParse(input);
  return regex.hasMatch(input) && value != null && value > Decimal.zero;
}

bool validNonNegativeDecimal(String input, int scale) {
  final regex = RegExp('^(?:0|[1-9]\\d*)(?:\\.\\d{1,$scale})?\$');
  final value = Decimal.tryParse(input);
  return regex.hasMatch(input) && value != null && value >= Decimal.zero;
}

Map<String, dynamic> resourceOf(dynamic response) {
  final object = objectOf(response);
  return object.containsKey('ulid') ? object : objectOf(object['data']);
}

Future<bool> confirmMutation(
  BuildContext context, {
  required String title,
  required String warning,
  required String actionLabel,
}) async {
  return await showDialog<bool>(
    context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(warning),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true),
          child: Text(actionLabel)),
      ],
    ),
  ) ?? false;
}

Future<Map<String, dynamic>?> pickApiRecord(
  BuildContext context, {
  required AppController app,
  required String title,
  required String path,
  String nameKey = 'name',
  String subtitleKey = 'code',
  String searchParam = 'q',
}) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context, showDragHandle: true, useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _ApiRecordPicker(
      app: app, title: title, path: path,
      nameKey: nameKey, subtitleKey: subtitleKey,
      searchParam: searchParam,
    ),
  );
}

/// Shared searchable, server-scoped entity lookup for supplier, customer,
/// account and product selectors. No client-controlled tenant parameters.
class _ApiRecordPicker extends StatefulWidget {
  const _ApiRecordPicker({
    required this.app, required this.title, required this.path,
    required this.nameKey, required this.subtitleKey,
    required this.searchParam,
  });

  final AppController app;
  final String title, path, nameKey, subtitleKey, searchParam;

  @override
  State<_ApiRecordPicker> createState() => _ApiRecordPickerState();
}

class _ApiRecordPickerState extends State<_ApiRecordPicker> {
  final search = TextEditingController();
  Timer? debounce;
  List<Map<String, dynamic>> entries = const [];
  bool loading = true;
  String? error;
  int sequence = 0;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    search.dispose();
    debounce?.cancel();
    super.dispose();
  }

  Future<void> fetch() async {
    final current = ++sequence;
    setState(() { loading = true; error = null; });
    try {
      final uri = Uri.parse(widget.path);
      final parameters = <String, String>{
        ...uri.queryParameters,
        if (search.text.trim().isNotEmpty)
          widget.searchParam: search.text.trim(),
      };
      final next = uri.replace(queryParameters: parameters);
      final result = await widget.app.api.get(next.toString());
      if (!mounted || current != sequence) return;
      setState(() => entries = recordsOf(result).where(
        (row) => validPublicUlid(field(row['ulid']))).toList());
    } catch (ex) {
      if (mounted && current == sequence) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && current == sequence) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 6, 16, MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: search,
            autofocus: true,
            onChanged: (_) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 300), fetch);
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search by name or code',
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: loading ? pageLoading()
            : error != null ? FailureState(message: error!, retry: fetch)
            : entries.isEmpty ? const EmptyState(
              title: 'No available records', subtitle: 'Try another search.')
            : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final row = entries[i];
                return ListTile(
                  title: Text(field(row[widget.nameKey], 'Unnamed')),
                  subtitle: Text(field(row[widget.subtitleKey])),
                  leading: CircleAvatar(
                    backgroundColor: palette.primaryContainer,
                    child: Icon(Icons.check_circle_outline_rounded,
                      color: palette.primary)),
                  onTap: () => Navigator.pop(context, row),
                );
              },
            )),
        ]),
      ),
    );
  }
}


/// Common paginated document directory. Every row opens the authentic
/// backend document, and any save/post on the detail screen triggers a reload.
class TransactionDirectory extends StatefulWidget {
  const TransactionDirectory({
    super.key,
    required this.app,
    required this.title,
    required this.endpoint,
    required this.onOpen,
    this.onCreate,
    this.createPermission,
    this.numberKey = 'document_number',
    this.dateKey = 'document_date',
    this.amountKey = 'grand_total',
    this.referenceStyle = false,
  });

  final AppController app;
  final String title, endpoint, numberKey, dateKey, amountKey;
  /// Approved mobile list card composition; only API data is rendered.
  final bool referenceStyle;
  final String? createPermission;
  final Future<bool> Function(BuildContext context, Map<String, dynamic> row) onOpen;
  final Future<bool> Function(BuildContext context)? onCreate;

  @override
  State<TransactionDirectory> createState() => _TransactionDirectoryState();
}

class _TransactionDirectoryState extends State<TransactionDirectory> {
  final search = TextEditingController();
  Timer? delay;
  List<Map<String, dynamic>> rows = const [];
  bool loading = true, moreLoading = false;
  String? error;
  int page = 1, total = 0, version = 0;
  String statusFilter = 'all';

  @override
  void initState() { super.initState(); load(); }

  @override
  void dispose() {
    delay?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    if (more && (loading || moreLoading || rows.length >= total)) return;
    final request = more ? version : ++version;
    setState(() {
      if (more) { moreLoading = true; }
      else { loading = true; error = null; }
    });
    try {
      final uri = Uri.parse(widget.endpoint);
      final targetPage = more ? page + 1 : 1;
      final path = uri.replace(queryParameters: {
        ...uri.queryParameters,
        'per_page': '25', 'page': '$targetPage',
        if (search.text.trim().isNotEmpty) 'q': search.text.trim(),
        if (statusFilter != 'all') 'status': statusFilter,
      }).toString();
      final result = objectOf(await widget.app.api.get(path));
      if (!mounted || request != version) return;
      final next = recordsOf(result);
      setState(() {
        rows = more ? [...rows, ...next] : next;
        page = targetPage;
        total = int.tryParse(field(objectOf(result['meta'])['total']))
          ?? rows.length;
      });
    } catch (ex) {
      if (mounted && request == version) setState(() => error = ex.toString());
    } finally {
      if (mounted && request == version) {
        setState(() { loading = false; moreLoading = false; });
      }
    }
  }

  Widget referenceDocumentCard(Map<String, dynamic> item,
      {required bool isReturn}) {
    final style = BpReferenceStyle.of(context);
    final status = field(item['status'], 'Unknown').toLowerCase();
    final statusColor = switch (status) {
      'posted' || 'paid' => const Color(0xFF0A9D50),
      'draft' => const Color(0xFFEE861E),
      'refunded' => const Color(0xFF087AE8),
      'adjusted' => const Color(0xFF8C51D7),
      _ => style.scheme.primary,
    };
    final isVoucher = widget.endpoint.startsWith('/api/vouchers');
    final party = isVoucher
      ? field(item['description'],
          field(item['book_number'], 'Journal voucher'))
      : field(objectOf(item['supplier'])['name'],
          field(objectOf(item['customer'])['name'],
            field(item['supplier_name'],
              field(item['customer_name'], 'Party not assigned'))));
    final source = field(
      objectOf(item['original_sale'])['document_number'],
      field(objectOf(item['original_purchase'])['document_number']));
    final amount = item[widget.amountKey];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: style.card(radius: 15),
      child: Row(children: [
        Container(
          width: 42, height: 44,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(11)),
          child: Icon(isVoucher ? Icons.menu_book_outlined
            : isReturn ? Icons.assignment_return_rounded
            : Icons.receipt_long_rounded, size: 23, color: statusColor)),
        const SizedBox(width: 9),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field(item[widget.numberKey], 'Document'),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: style.ink, fontSize: 12,
                fontWeight: FontWeight.w900)),
            Text(party, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: style.muted, fontSize: 10)),
            if (isReturn && source.isNotEmpty)
              Text('Inv: $source', maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: style.muted, fontSize: 9.5)),
          ],
        )),
        const SizedBox(width: 5),
        Container(width: 1, height: 47, color: style.line),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11)),
              child: Text(field(item['status'], 'Unknown'),
                style: TextStyle(fontSize: 9.5,
                  color: statusColor, fontWeight: FontWeight.w800))),
            const SizedBox(height: 3),
            Text(field(item[widget.dateKey]),
              style: TextStyle(fontSize: 9.5, color: style.muted)),
            if (amount != null)
              Text(money(amount, widget.app.currency),
                style: TextStyle(color: style.ink, fontSize: 10.5,
                  fontWeight: FontWeight.w900)),
          ]),
        const SizedBox(width: 3),
        Icon(Icons.chevron_right_rounded, size: 18, color: style.muted),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = BpReferenceStyle.of(context);
    final isReturns = widget.endpoint == '/api/sales-returns' ||
      widget.endpoint == '/api/purchase-returns';
    final visibleRows = rows; // Backend already applies tenant-safe status filters.
    final allowCreate = widget.onCreate != null &&
      (widget.createPermission == null ||
        widget.app.hasPermission(widget.createPermission!));
    return Scaffold(
      backgroundColor: widget.referenceStyle ? style.page : null,
      appBar: widget.referenceStyle
        ? BpReferenceSubpageAppBar(title: widget.title)
        : AppBar(title: Text(widget.title),
            actions: [IconButton(onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh')]),
      floatingActionButton: allowCreate ? FloatingActionButton.extended(
        backgroundColor: widget.referenceStyle
          ? const Color(0xFF0BB85C) : null,
        foregroundColor: widget.referenceStyle ? Colors.white : null,
        onPressed: () async {
          if (await widget.onCreate!(context) && mounted) await load();
        }, icon: const Icon(Icons.add_rounded),
        label: Text(isReturns ? 'Add Return'
          : widget.endpoint == '/api/sales' ? 'New Invoice'
          : widget.referenceStyle ? 'Add Purchase' : 'New'))
        : null,
      body: RefreshIndicator(onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 100),
          children: [
          if (!widget.referenceStyle) SectionHeading(widget.title),
          Row(children: [
            Expanded(child: TextField(
              key: const ValueKey('transaction-search'),
              controller: search,
            onChanged: (_) {
              delay?.cancel();
              delay = Timer(const Duration(milliseconds: 300), load);
            },
            decoration: widget.referenceStyle
              ? style.search(isReturns
                  ? 'Search return, party, invoice...'
                  : widget.endpoint == '/api/sales'
                    ? 'Search invoice or customer...'
                    : widget.endpoint.startsWith('/api/vouchers')
                      ? 'Search voucher, narration, account...'
                      : 'Search invoice or supplier...',
                  prefixIcon: const Icon(Icons.search_rounded))
                  .copyWith(isDense: true)
              : const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search document number'))),
            if (widget.referenceStyle) ...[
              const SizedBox(width: 7),
              Container(
                decoration: style.card(radius: 12),
                child: PopupMenuButton<String>(
                  key: const ValueKey('transaction-status-filter'),
                  tooltip: 'Filter server documents by status',
                  icon: Icon(statusFilter == 'all'
                    ? Icons.filter_alt_outlined : Icons.filter_alt,
                    color: style.scheme.primary),
                  onSelected: (value) {
                    setState(() => statusFilter = value);
                    load();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'all',
                      child: Text('All statuses')),
                    if (widget.endpoint != '/api/sales')
                      const PopupMenuItem(value: 'draft',
                        child: Text('Draft')),
                    const PopupMenuItem(value: 'posted',
                      child: Text('Posted')),
                    if (widget.endpoint == '/api/purchases')
                      const PopupMenuItem(value: 'cancelled',
                        child: Text('Cancelled')),
                    if (widget.endpoint == '/api/sales')
                      const PopupMenuItem(value: 'void',
                        child: Text('Void')),
                  ]),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else if (visibleRows.isEmpty) const EmptyState(
            title: 'No matching documents',
            subtitle: 'No records were returned for this search or status.')
          else ...visibleRows.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              key: ValueKey('transaction-${field(item['ulid'])}'),
              onTap: () async {
                if (await widget.onOpen(context, item) && mounted) {
                  await load();
                }
              },
              child: widget.referenceStyle
                ? referenceDocumentCard(item, isReturn: isReturns)
                : Container(
                    padding: const EdgeInsets.all(11),
                    decoration: style.card(radius: 12),
                    child: Row(children: [
                      Icon(Icons.description_outlined, color: colors.primary),
                      const SizedBox(width: 11),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(field(item[widget.numberKey], 'Document'),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(field(item[widget.dateKey]),
                            style: TextStyle(fontSize: 11,
                              color: colors.onSurfaceVariant)),
                        ])),
                      if (item[widget.amountKey] != null)
                        Text(money(item[widget.amountKey],
                            widget.app.currency)),
                      const Icon(Icons.chevron_right_rounded),
                    ])),
            ),
          )),
          if (!loading && rows.length < total)
            OutlinedButton(
              onPressed: moreLoading ? null : () => load(more: true),
              child: Text(moreLoading ? 'Loading…' : 'Load more')),
          const SizedBox(height: 76),
        ])),
    );
  }
}
