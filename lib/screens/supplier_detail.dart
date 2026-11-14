import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Newer design 30. Read-only vendor details; accounting summaries require
/// separate authorized ledger queries, never illustrative mockup balances.
class SupplierDetailScreen extends StatefulWidget {
  const SupplierDetailScreen({super.key, required this.app,
    required this.supplierUlid, this.onEdit});
  final AppController app;
  final String supplierUlid;
  final VoidCallback? onEdit;
  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  Map<String, dynamic>? supplier;
  bool busy = true;
  String? error;
  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { busy = true; error = null; });
    try {
      if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')
          .hasMatch(widget.supplierUlid)) {
        throw const FormatException('Invalid supplier reference');
      }
      final response = objectOf(await widget.app.api.get(
        '/api/parties/${widget.supplierUlid}?type=vendor'));
      final data = objectOf(response['data']);
      if (mounted) setState(() =>
        supplier = data.isNotEmpty ? data : response);
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Supplier Detail'),
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded),
        tooltip: 'Refresh', onPressed: load)]),
    body: busy ? const Center(child: CircularProgressIndicator())
      : error != null ? FailureState(message: error!, retry: load)
      : RefreshIndicator(onRefresh: load,
        child: SupplierDetailView(supplier: supplier ?? const {},
          canEdit: widget.app.hasPermission('suppliers.edit') ||
            widget.app.hasPermission('suppliers.manage'),
          onEdit: widget.onEdit)),
  );
}

/// Widget can be tested with in-memory server shaped records.
class SupplierDetailView extends StatelessWidget {
  const SupplierDetailView({super.key, required this.supplier,
    this.canEdit = false, this.onEdit});
  final Map<String, dynamic> supplier;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget line(String label, dynamic value, IconData icon) {
      final txt = field(value);
      return Padding(padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Icon(icon, color: scheme.primary, size: 21),
          const SizedBox(width: 11),
          Expanded(child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700))),
          Flexible(child: Text(txt.isEmpty ? 'Not available' : txt,
            maxLines: 3, textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis)),
        ]));
    }

    return ListView(key: const ValueKey('supplier-detail-view'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16), children: [
        Surface(child: Row(children: [
          Container(width: 64, height: 64,
            decoration: BoxDecoration(color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.local_shipping_outlined,
              color: scheme.primary, size: 34)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field(supplier['name'], 'Supplier'),
                maxLines: 3, style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
              Text(field(supplier['code'], 'Code not available'),
                style: TextStyle(color: scheme.onSurfaceVariant)),
              Text(supplier['is_active'] == false ? 'Inactive' : 'Active',
                style: TextStyle(color: supplier['is_active'] == false
                  ? scheme.error : scheme.primary,
                  fontWeight: FontWeight.w800)),
            ])),
        ])),
        const SizedBox(height: 12),
        Surface(child: Column(children: [
          line('Mobile Number', supplier['mobile'], Icons.phone_outlined),
          const Divider(height: 1),
          line('City / Area', supplier['area'], Icons.place_outlined),
          const Divider(height: 1),
          line('Address', supplier['address'], Icons.home_outlined),
          const Divider(height: 1),
          line('Contact Person', supplier['contact_person'],
            Icons.person_outline_rounded),
          const Divider(height: 1),
          line('Email', supplier['email'], Icons.email_outlined),
          const Divider(height: 1),
          line('Account Type', objectOf(supplier['account_type'])['name'],
            Icons.account_balance_outlined),
        ])),
        const SizedBox(height: 13),
        Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Recent Purchases', style: Theme.of(context)
              .textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            const Text('Purchase history and payable balance are not included '
              'in this supplier details API response. No amounts are estimated.'),
          ])),
        if (canEdit && onEdit != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('supplier-detail-edit'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Supplier')),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
