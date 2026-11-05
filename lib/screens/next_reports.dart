import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Read-only report families backed by NextReportsController on the BluePOS
/// server. Values, tenant scope, permissions and signed returns are authoritative
/// server output. Never calculate revenue, stock or tax on the device.
enum NextReportKind {
  advanceSales,
  dayBook,
  productTransactions,
  detailedTransactions,
  fbrSales,
  fbrPurchases,
}

extension NextReportDefinition on NextReportKind {
  String get title => switch (this) {
    NextReportKind.advanceSales => 'Advance Sales View',
    NextReportKind.dayBook => 'Day Book',
    NextReportKind.productTransactions => 'Product Wise Transactions',
    NextReportKind.detailedTransactions => 'Detailed Transactions',
    NextReportKind.fbrSales => 'FBR Sales Register',
    NextReportKind.fbrPurchases => 'FBR Purchase Register',
  };

  String get endpoint => switch (this) {
    NextReportKind.advanceSales => '/api/reports/next/advance-sales',
    NextReportKind.dayBook => '/api/reports/next/day-book',
    NextReportKind.productTransactions => '/api/reports/next/product-transactions',
    NextReportKind.detailedTransactions => '/api/reports/next/detailed-transactions',
    NextReportKind.fbrSales => '/api/reports/next/fbr/sales',
    NextReportKind.fbrPurchases => '/api/reports/next/fbr/purchases',
  };

  String get permission => switch (this) {
    NextReportKind.advanceSales || NextReportKind.productTransactions =>
      'reports.inventory',
    _ => 'reports.accounting',
  };

  bool get needsAccountingToo => this == NextReportKind.advanceSales;
  bool get supportsProduct => this == NextReportKind.advanceSales ||
    this == NextReportKind.productTransactions ||
    this == NextReportKind.fbrSales || this == NextReportKind.fbrPurchases;
  bool get supportsTypes => this == NextReportKind.dayBook ||
    this == NextReportKind.productTransactions ||
    this == NextReportKind.detailedTransactions;
  bool get internalTaxReview => this == NextReportKind.fbrSales ||
    this == NextReportKind.fbrPurchases;
  List<String> get formats => switch (this) {
    NextReportKind.dayBook => ['short', 'ledger'],
    NextReportKind.detailedTransactions => ['summary', 'daily', 'detail'],
    NextReportKind.fbrSales || NextReportKind.fbrPurchases => ['short', 'invoice'],
    _ => const [],
  };
}

class NextReportScreen extends StatefulWidget {
  const NextReportScreen({super.key, required this.app, required this.kind});
  final AppController app;
  final NextReportKind kind;
  @override
  State<NextReportScreen> createState() => _NextReportScreenState();
}

class _NextReportScreenState extends State<NextReportScreen> {
  DateTimeRange period = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );
  String format = '';
  String productUlid = '';
  String accountUlid = '';
  Set<String> types = {};
  List<Map<String, dynamic>> products = const [];
  List<Map<String, dynamic>> accounts = const [];
  Map<String, dynamic> report = const {};
  String? error, optionsError;
  bool loading = true;
  int requestId = 0;

  static const documentTypes = <String>[
    'sale', 'purchase', 'sale_return', 'purchase_return', 'voucher',
  ];

  @override
  void initState() {
    super.initState();
    format = widget.kind.formats.isEmpty ? '' : widget.kind.formats.first;
    _loadOptions();
    load();
  }

  String iso(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

  Future<void> _loadOptions() async {
    if (!widget.kind.supportsProduct && widget.kind != NextReportKind.dayBook) {
      return;
    }
    try {
      final response = objectOf(
        await widget.app.api.get('/api/reports/next/options'));
      if (!mounted) return;
      setState(() {
        products = recordsOf(response['products']);
        accounts = recordsOf(response['accounts']);
        optionsError = null;
      });
    } catch (ex) {
      if (mounted) setState(() => optionsError = ex.toString());
    }
  }

  Future<void> pickPeriod() async {
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 2)),
      initialDateRange: period,
      helpText: 'Choose up to 31 calendar days',
    );
    if (!mounted || chosen == null) return;
    if (chosen.end.difference(chosen.start).inDays >= 31) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select no more than 31 days.')));
      return;
    }
    setState(() => period = chosen);
    await load();
  }

  Future<void> load() async {
    final request = ++requestId;
    setState(() { loading = true; error = null; });
    try {
      // All filters are server-validated; tenant/branch/warehouse IDs are never
      // submitted by the mobile app.
      final params = <String, String>{
        'from': iso(period.start),
        'to': iso(period.end),
      };
      if (format.isNotEmpty) params['format'] = format;
      if (widget.kind.supportsProduct && productUlid.isNotEmpty) {
        params['product_ulid'] = productUlid;
      }
      if (widget.kind == NextReportKind.dayBook &&
          format == 'ledger' && accountUlid.isNotEmpty) {
        params['account_ulid'] = accountUlid;
      }
      if (widget.kind.supportsTypes) {
        final selected = types.where((type) =>
          widget.kind == NextReportKind.dayBook ||
          type != 'voucher').toList()..sort();
        for (var i = 0; i < selected.length; i++) {
          params['types[$i]'] = selected[i];
        }
      }
      if (widget.kind == NextReportKind.dayBook &&
          format == 'ledger' && accountUlid.isEmpty) {
        setState(() { loading = false; error = 'Choose a ledger account.'; });
        return;
      }
      final raw = await widget.app.api.get(Uri(
        path: widget.kind.endpoint, queryParameters: params,
      ).toString());
      if (mounted && request == requestId) {
        setState(() => report = objectOf(raw));
      }
    } catch (ex) {
      if (mounted && request == requestId) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && request == requestId) {
        setState(() => loading = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _pick(
    String heading, List<Map<String, dynamic>> candidates,
  ) async {
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        optionsError ?? 'No authorized options are available.')));
      return null;
    }
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) {
        // Sheet-local search; no data from a different tenant is queried.
        return _NextEntityPicker(
          heading: heading, candidates: candidates,
        );
      }),
    );
  }

  Future<void> chooseProduct() async {
    final choice = await _pick('Select product', products);
    if (!mounted || choice == null) return;
    setState(() => productUlid = field(choice['ulid']));
    await load();
  }

  Future<void> chooseAccount() async {
    final choice = await _pick('Select ledger account', accounts);
    if (!mounted || choice == null) return;
    setState(() => accountUlid = field(choice['ulid']));
    await load();
  }

  String get productName {
    if (productUlid.isEmpty) return 'All products';
    for (final item in products) {
      if (field(item['ulid']) == productUlid) {
        return field(item['name'], 'Selected product');
      }
    }
    return 'Selected product';
  }

  String get accountName {
    if (accountUlid.isEmpty) return 'Choose a ledger account';
    for (final item in accounts) {
      if (field(item['ulid']) == accountUlid) {
        return field(item['name'], 'Selected account');
      }
    }
    return 'Selected account';
  }

  Widget _filterButton(String label, String value, VoidCallback choose) {
    return OutlinedButton.icon(
      onPressed: choose,
      icon: const Icon(Icons.tune_rounded, size: 17),
      label: Text('$label: $value', maxLines: 1,
        overflow: TextOverflow.ellipsis),
    );
  }

  Widget _amount(String label, dynamic value, IconData icon,
    {bool monetary = true}) => Expanded(child: BpStatCard(
    icon: icon, caption: label,
    value: monetary ? money(value, widget.app.currency) : field(value, '—'),
    hint: 'Server report',
  ));

  Widget _summary() {
    final t = objectOf(report['totals']);
    switch (widget.kind) {
      case NextReportKind.advanceSales:
        return Row(children: [
          _amount('Quantity sold', t['quantity'],
            Icons.inventory_2_outlined, monetary: false),
          const SizedBox(width: 8),
          _amount('Line amount', t['amount'], Icons.payments_outlined),
        ]);
      case NextReportKind.productTransactions:
        return Row(children: [
          _amount('Quantity in', t['in'], Icons.south_west_rounded,
            monetary: false),
          const SizedBox(width: 8),
          _amount('Quantity out', t['out'], Icons.north_east_rounded,
            monetary: false),
        ]);
      case NextReportKind.detailedTransactions:
        return Row(children: [
          _amount('Documents', t['count'], Icons.receipt_long_outlined,
            monetary: false),
          const SizedBox(width: 8),
          _amount('Signed total', t['amount'], Icons.payments_outlined),
        ]);
      case NextReportKind.fbrSales:
      case NextReportKind.fbrPurchases:
        return Column(children: [
          Row(children: [
            _amount('Value ex tax', t['value'], Icons.payments_outlined),
            const SizedBox(width: 8),
            _amount('Tax', t['tax'], Icons.percent_rounded),
          ]),
          const SizedBox(height: 8),
          BpStatCard(icon: Icons.receipt_long_outlined, caption: 'Gross',
            value: money(t['gross'], widget.app.currency),
            hint: 'Internal tax review only'),
        ]);
      case NextReportKind.dayBook:
        return Row(children: [
          _amount('Sales', t['sale'], Icons.receipt_long_outlined),
          const SizedBox(width: 8),
          _amount('Purchases', t['purchase'], Icons.shopping_bag_outlined),
        ]);
    }
  }

  List<Map<String, dynamic>> _rows() {
    if (widget.kind != NextReportKind.dayBook) {
      return recordsOf(report['rows']);
    }
    if (format == 'ledger') {
      return recordsOf(objectOf(report['ledger'])['rows']);
    }
    final grouped = objectOf(report['rows']);
    final rows = <Map<String, dynamic>>[];
    for (final type in documentTypes) {
      for (final item in recordsOf(grouped[type])) {
        rows.add({...item, '_group': type});
      }
    }
    return rows;
  }

  String _rowTitle(Map<String, dynamic> row) {
    final product = field(objectOf(row['product'])['name']);
    if (widget.kind == NextReportKind.productTransactions) {
      return product.isEmpty ? 'Stock movement' : product;
    }
    if (widget.kind == NextReportKind.advanceSales) {
      return product.isEmpty ? field(row['number'], 'Sale item') : product;
    }
    if (widget.kind == NextReportKind.detailedTransactions) {
      return field(row['party'], 'Unspecified party');
    }
    return field(row['number'], 'Document');
  }

  String _rowDetails(Map<String, dynamic> row) {
    final parts = <String>[
      field(row['date']),
      field(row['_group'], field(row['type'])),
      field(row['party']),
      if (widget.kind == NextReportKind.detailedTransactions)
        field(row['number']),
    ].where((x) => x.isNotEmpty).toList();
    return parts.join(' · ');
  }

  Widget _detail(String label, dynamic value, {bool isMoney = false}) {
    if (value == null || field(value).isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 11, color: colors.onSurfaceVariant))),
        Expanded(child: Text(isMoney
            ? money(value, widget.app.currency) : field(value),
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _reportRow(Map<String, dynamic> item) {
    final colors = Theme.of(context).colorScheme;
    final ledger = widget.kind == NextReportKind.dayBook && format == 'ledger';
    final income = widget.kind == NextReportKind.fbrSales ||
      widget.kind == NextReportKind.fbrPurchases;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Surface(padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(_rowTitle(item), maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900))),
            const SizedBox(width: 7),
            Text(field(item['number']),
              style: TextStyle(fontSize: 11, color: colors.primary)),
          ]),
          const SizedBox(height: 4),
          Text(_rowDetails(item), maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
          if (widget.kind == NextReportKind.advanceSales) ...[
            _detail('Sold quantity', item['sold']),
            _detail('Stock after movement', item['stock_at'] ?? 'Unavailable'),
            _detail('Current warehouse stock', item['current_stock']),
            _detail('Unit rate', item['rate'], isMoney: true),
            _detail('Line amount', item['amount'], isMoney: true),
          ] else if (widget.kind == NextReportKind.productTransactions) ...[
            _detail('Quantity in', item['quantity_in']),
            _detail('Quantity out', item['quantity_out']),
            _detail('Unit cost', item['unit_cost'], isMoney: true),
            _detail('Movement cost', item['total_cost'], isMoney: true),
            _detail('Document', item['number']),
          ] else if (widget.kind == NextReportKind.detailedTransactions) ...[
            _detail('Documents', item['count']),
            _detail('Signed amount', item['amount'], isMoney: true),
            for (final day in objectOf(item['days']).entries)
              _detail(day.key, day.value, isMoney: true),
            if (recordsOf(item['lines']).isNotEmpty)
              ExpansionTile(title: const Text('Document items'),
                tilePadding: EdgeInsets.zero,
                children: [
                  for (final line in recordsOf(item['lines']))
                    ListTile(
                      dense: true,
                      title: Text(field(objectOf(line['product'])['name'],
                        'Product line')),
                      subtitle: Text(field(line['quantity'], '')),
                      trailing: Text(field(line['amount'], '')),
                    ),
                ]),
          ] else if (income) ...[
            _detail('Party NTN', item['party_ntn']),
            _detail('Party STRN', item['party_strn']),
            _detail('Product', objectOf(item['product'])['name']),
            _detail('HS Code', item['hs_code']),
            _detail('Quantity', item['quantity']),
            _detail('Tax rate', item['tax_rate']),
            _detail('Value ex tax', item['value'], isMoney: true),
            _detail('Tax', item['tax'], isMoney: true),
            _detail('Gross', item['gross'], isMoney: true),
          ] else if (ledger) ...[
            _detail('Debit', item['debit'], isMoney: true),
            _detail('Credit', item['credit'], isMoney: true),
            _detail('Running balance', item['balance'], isMoney: true),
          ] else ...[
            _detail('Amount', item['amount'], isMoney: true),
          ],
        ])),
    );
  }

  Widget _limits() {
    final limits = report['limitations'];
    if (limits is! List || limits.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      for (final note in limits) Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Text(note.toString(),
          style: TextStyle(fontSize: 10.5, color: colors.onSurfaceVariant))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedFormat = widget.kind.formats.contains(format)
      ? format : widget.kind.formats.firstOrNull;
    final rows = _rows();
    final ledger = objectOf(report['ledger']);
    return Scaffold(
      appBar: AppBar(title: Text(widget.kind.title), actions: [
        IconButton(
          onPressed: loading ? null : load,
          tooltip: 'Refresh report',
          icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: RefreshIndicator(onRefresh: load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          SectionHeading(widget.kind.title),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: pickPeriod,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text('${iso(period.start)} — ${iso(period.end)}')),
          if (widget.kind.internalTaxReview) Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Surface(padding: const EdgeInsets.all(12), child: Row(children: [
              Icon(Icons.info_outline_rounded, color: colors.error, size: 21),
              const SizedBox(width: 9),
              const Expanded(child: Text(
                'INTERNAL TAX REVIEW — NOT FBR FILING-READY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
            ]))),
          if (widget.kind.supportsProduct) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _filterButton('Product', productName, chooseProduct)),
          if (widget.kind == NextReportKind.dayBook && format == 'ledger')
            Padding(padding: const EdgeInsets.only(top: 8),
              child: _filterButton('Ledger', accountName, chooseAccount)),
          if (widget.kind.formats.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DropdownButtonFormField<String>(
              key: ValueKey('format-$selectedFormat'),
              initialValue: selectedFormat,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Report format'),
              items: widget.kind.formats.map((name) => DropdownMenuItem(
                value: name, child: Text(name.toUpperCase()))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => format = value);
                load();
              },
            )),
          if (widget.kind.supportsTypes) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 7, runSpacing: 3, children: [
              for (final type in documentTypes)
                if (widget.kind == NextReportKind.dayBook || type != 'voucher')
                  FilterChip(
                    label: Text(type.replaceAll('_', ' ')),
                    selected: types.contains(type),
                    onSelected: (chosen) {
                      setState(() => chosen ? types.add(type) : types.remove(type));
                      load();
                    },
                  ),
            ]),
          ),
          const SizedBox(height: 14),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: load)
          else ...[
            _summary(),
            if (widget.kind == NextReportKind.dayBook &&
                format == 'ledger' && ledger.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                _amount('Opening', ledger['opening'], Icons.wallet_outlined),
                const SizedBox(width: 8),
                _amount('Closing', ledger['closing'], Icons.account_balance_outlined),
              ]),
            ],
            const SizedBox(height: 16),
            SectionHeading('Report entries',
              trailing: Text('${rows.length} records',
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant))),
            if (rows.isEmpty) const EmptyState(
              title: 'No matching transactions',
              subtitle: 'Change the period or filters and refresh.')
            else ...rows.map(_reportRow),
            _limits(),
          ],
          const SizedBox(height: 24),
        ])),
    );
  }
}

class _NextEntityPicker extends StatefulWidget {
  const _NextEntityPicker({required this.heading, required this.candidates});
  final String heading;
  final List<Map<String, dynamic>> candidates;
  @override
  State<_NextEntityPicker> createState() => _NextEntityPickerState();
}

class _NextEntityPickerState extends State<_NextEntityPicker> {
  String filter = '';
  @override
  Widget build(BuildContext context) {
    final shown = widget.candidates.where((item) {
      final name = field(item['name']).toLowerCase();
      final code = field(item['product_number'], field(item['code'])).toLowerCase();
      return name.contains(filter.toLowerCase()) ||
        code.contains(filter.toLowerCase());
    }).take(80).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16,
        MediaQuery.viewInsetsOf(context).bottom + 12),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .6,
        child: Column(children: [
          Text(widget.heading, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => filter = value.trim()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search available records'),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.clear_rounded),
            title: const Text('Clear selection'),
            onTap: () => Navigator.pop(context, <String, dynamic>{}),
          ),
          Expanded(child: ListView.builder(
            itemCount: shown.length,
            itemBuilder: (ctx, index) {
              final row = shown[index];
              return ListTile(
                title: Text(field(row['name'], 'Unnamed')),
                subtitle: Text(field(row['product_number'], field(row['code']))),
                onTap: () => Navigator.pop(context, row),
              );
            },
          )),
        ]),
      ),
    );
  }
}
