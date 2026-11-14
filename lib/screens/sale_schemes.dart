import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Screen 24: authorized real sale schemes. No client-side discount arithmetic.
class SaleSchemesScreen extends StatefulWidget {
  const SaleSchemesScreen({super.key, required this.app});
  final AppController app;
  @override
  State<SaleSchemesScreen> createState() => _SaleSchemesScreenState();
}

class _SaleSchemesScreenState extends State<SaleSchemesScreen> {
  final search = TextEditingController();
  bool loading = true;
  bool filterActive = false;
  String? error;
  List<Map<String, dynamic>> schemes = const [];

  bool get canView => widget.app.hasPermission('sale_schemes.view') ||
      widget.app.hasPermission('sale_schemes.manage');

  @override
  void initState() { super.initState(); reload(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> reload() async {
    if (!canView) {
      setState(() { loading = false; error = 'Access denied.'; });
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final data = await widget.app.api.get('/api/sale-schemes');
      if (mounted) setState(() => schemes = recordsOf(data));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = search.text.trim().toLowerCase();
    final filtered = schemes.where((row) =>
      (!filterActive || row['is_active'] != false) &&
      (query.isEmpty || field(row['name']).toLowerCase().contains(query))).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Schemes'),
        actions: [IconButton(tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded), onPressed: reload)]),
      floatingActionButton: canView ? FloatingActionButton.extended(
        key: const ValueKey('sale-scheme-add-preview'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const AddSaleSchemeReferenceScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Scheme')) : null,
      body: RefreshIndicator(onRefresh: reload, child: ListView(
        key: const ValueKey('sale-schemes-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(child: Text('Sale Schemes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900))),
            Icon(Icons.local_offer_outlined, color: scheme.primary),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search sale schemes...'))),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const ValueKey('sale-scheme-filter'),
              tooltip: 'Show active only',
              onPressed: () => setState(() => filterActive = !filterActive),
              icon: Icon(filterActive ? Icons.filter_alt : Icons.filter_alt_outlined)),
          ]),
          const SizedBox(height: 14),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: reload)
          else if (filtered.isEmpty) const EmptyState(title: 'No sale schemes')
          else ...filtered.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: SaleSchemeCard(item: row))),
          const SizedBox(height: 90),
        ],
      )),
    );
  }
}

class SaleSchemeCard extends StatelessWidget {
  const SaleSchemeCard({super.key, required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = item['is_active'] != false;
    final starts = field(item['starts_on']);
    final ends = field(item['ends_on']);
    return Surface(child: Row(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 48, width: 48,
          decoration: BoxDecoration(color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.card_giftcard_outlined, color: scheme.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(field(item['name'], 'Sale scheme'),
              style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(field(item['scheme_type'], 'Type not available'),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            Text('Apply mode: ${field(item['apply_mode'], 'Not available')}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
            if (starts.isNotEmpty || ends.isNotEmpty)
              Text([starts, ends].where((v) => v.isNotEmpty).join(' – '),
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        )),
        const SizedBox(width: 5),
        Text(active ? 'Active' : 'Inactive',
          style: TextStyle(color: active ? scheme.primary : scheme.error,
            fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    ));
  }
}

/// Screen 25 is an intentionally non-submittable design reference.
/// Live SaleScheme API requires a reward product ULID and quantity,
/// which the illustrative mockup form does not collect.
class AddSaleSchemeReferenceScreen extends StatelessWidget {
  const AddSaleSchemeReferenceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Sale Scheme')),
    body: ListView(key: const ValueKey('add-sale-scheme-preview'),
      padding: const EdgeInsets.all(16), children: [
        Surface(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: Icon(Icons.local_offer_outlined, size: 56)),
            const SizedBox(height: 16),
            for (final label in [
              'Scheme Name', 'Scheme Code', 'Scheme Type', 'Apply On',
              'Discount Value', 'Start Date', 'End Date', 'Description',
              'Applicable Products/Categories'
            ]) ...[
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Design reference — not editable')),
              const SizedBox(height: 11),
            ],
            const Text('Status: Active / Inactive'),
            const SizedBox(height: 12),
            const Text('A reward product and quantity are required by the '
              'current Sale Schemes API. This design preview cannot be saved.'),
          ],
        )),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'))),
          const SizedBox(width: 8),
          const Expanded(child: FilledButton(
            key: ValueKey('sale-scheme-save-disabled'),
            onPressed: null, child: Text('Save Scheme'))),
        ]),
      ],
    ),
  );
}
