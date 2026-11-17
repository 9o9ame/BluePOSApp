import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'auth_reference_chrome.dart';

/// Screen 24 — real, permission-gated sale scheme list.
class SaleSchemesScreen extends StatefulWidget {
  const SaleSchemesScreen({super.key, required this.app});
  final AppController app;

  @override
  State<SaleSchemesScreen> createState() => _SaleSchemesScreenState();
}

class _SaleSchemesScreenState extends State<SaleSchemesScreen> {
  final search = TextEditingController();
  final searchFocus = FocusNode();
  bool loading = true;
  bool filterActive = false;
  String? error;
  List<Map<String, dynamic>> schemes = const [];

  bool get canView => widget.app.hasPermission('sale_schemes.view') ||
      widget.app.hasPermission('sale_schemes.manage');

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    search.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    if (!canView) {
      if (mounted) {
        setState(() { loading = false; error = 'Access denied.'; });
      }
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
    final style = BpReferenceStyle.of(context);
    final query = search.text.trim().toLowerCase();
    final filtered = schemes.where((row) =>
      (!filterActive || row['is_active'] != false) &&
      (query.isEmpty || field(row['name']).toLowerCase().contains(query)))
      .toList();

    return Scaffold(
      backgroundColor: style.page,
      appBar: BpReferenceSubpageAppBar(
        title: 'Sale Schemes',
        onSearch: () => searchFocus.requestFocus()),
      floatingActionButton: canView
        ? SizedBox(width: 86, height: 86,
            child: FloatingActionButton(
              key: const ValueKey('sale-scheme-add-preview'),
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF09B65B),
              shape: const CircleBorder(side: BorderSide(
                color: Colors.white, width: 2.5)),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AddSaleSchemeReferenceScreen())),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 31),
                  Text('Add Scheme', style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 10)),
                ]),
            ))
        : null,
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        RefreshIndicator(onRefresh: reload, child: ListView(
          key: const ValueKey('sale-schemes-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
          children: [
            Row(children: [
              Expanded(child: TextField(
                controller: search, focusNode: searchFocus,
                onChanged: (_) => setState(() {}),
                decoration: style.search('Search sale schemes...',
                  prefixIcon: const Icon(Icons.search_rounded))
                  .copyWith(isDense: true))),
              const SizedBox(width: 8),
              Container(
                decoration: style.card(radius: 13),
                child: IconButton(
                  key: const ValueKey('sale-scheme-filter'),
                  tooltip: 'Show active only',
                  onPressed: () => setState(
                    () => filterActive = !filterActive),
                  icon: Icon(filterActive
                    ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: style.scheme.primary)),
              ),
            ]),
            const SizedBox(height: 15),
            if (loading) pageLoading()
            else if (error != null)
              FailureState(message: error!, retry: reload)
            else if (filtered.isEmpty)
              EmptyState(title: schemes.isEmpty
                ? 'No sale schemes yet' : 'No matching sale schemes',
                subtitle: 'Only authorized server records are shown.')
            else
              for (var i = 0; i < filtered.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SaleSchemeCard(item: filtered[i], index: i)),
          ],
        )),
        const Positioned(left: 0, right: 0, bottom: 0,
          child: IgnorePointer(
            child: AuthReferenceWaves(height: 60))),
      ]),
    );
  }
}

/// Presentation only: every displayed value comes from a sale scheme response.
class SaleSchemeCard extends StatelessWidget {
  const SaleSchemeCard({
    super.key,
    required this.item,
    this.index = 0,
  });

  final Map<String, dynamic> item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    const icons = <IconData>[
      Icons.card_giftcard_rounded, Icons.savings_rounded,
      Icons.calendar_month_rounded, Icons.inventory_2_rounded,
      Icons.local_drink_rounded,
    ];
    const colors = <Color>[
      Color(0xFFFF9910), Color(0xFF13BA60),
      Color(0xFF9A51F5), Color(0xFF118EF3),
      Color(0xFFED4A82),
    ];
    final color = colors[index % colors.length];
    final active = item['is_active'] != false;
    final starts = field(item['starts_on']);
    final ends = field(item['ends_on']);
    final code = field(item['code']);
    final kind = field(item['scheme_type']);
    final description = field(item['description']);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: style.card(radius: 15),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 49, height: 49,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icons[index % icons.length],
            color: color, size: 26)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (code.isNotEmpty)
              Text(code, style: TextStyle(fontSize: 9,
                color: style.muted, fontWeight: FontWeight.w700)),
            Text(field(item['name'], 'Sale scheme'),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.5,
                color: style.ink, fontWeight: FontWeight.w900)),
            if (description.isNotEmpty)
              Text(description, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: style.muted))
            else if (kind.isNotEmpty)
              Text(kind, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: style.muted)),
            if (starts.isNotEmpty || ends.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.calendar_today_outlined,
                  size: 12, color: style.muted),
                const SizedBox(width: 3),
                Expanded(child: Text(
                  [starts, ends].where((value) => value.isNotEmpty).join(' – '),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: style.muted))),
              ]),
            ],
          ],
        )),
        const SizedBox(width: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: active
              ? const Color(0xFFDBF9E9) : const Color(0xFFFFE9EB),
            borderRadius: BorderRadius.circular(18)),
          child: Text(active ? '✓ Active' : 'Inactive',
            style: TextStyle(fontSize: 10,
              fontWeight: FontWeight.w900,
              color: active
                ? const Color(0xFF06853B) : const Color(0xFFAF3853))),
        ),
      ]),
    );
  }
}

class _SchemePreviewField extends StatelessWidget {
  const _SchemePreviewField({
    required this.label, required this.hint, required this.icon,
    this.twoLines = false, this.dropdown = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final bool twoLines;
  final bool dropdown;

  @override
  Widget build(BuildContext context) => BpReferenceFormField(
    label: label, hint: hint, icon: icon,
    readOnly: true, maxLines: twoLines ? 2 : 1,
    suffixIcon: dropdown
      ? const Icon(Icons.keyboard_arrow_down_rounded) : null);

}

/// Screen 25 preview, not a writable sale scheme editor. Existing server
/// validation requires reward product/quantity not covered by the mockup.
class AddSaleSchemeReferenceScreen extends StatelessWidget {
  const AddSaleSchemeReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Scaffold(
      backgroundColor: style.page,
      appBar: const BpReferenceSubpageAppBar(title: 'Add Sale Scheme'),
      bottomNavigationBar: BpReferenceFooter(
        saveKey: const ValueKey('sale-scheme-save-disabled'),
        saveLabel: 'Save Scheme',
        onCancel: () => Navigator.of(context).pop()),
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        ListView(
          key: const ValueKey('add-sale-scheme-preview'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
          children: [
            const _SchemePreviewField(
              icon: Icons.sell_rounded,
              label: 'Scheme Name *', hint: 'Enter scheme name'),
            const _SchemePreviewField(
              icon: Icons.qr_code_rounded,
              label: 'Scheme Code *', hint: 'Enter scheme code'),
            const _SchemePreviewField(
              icon: Icons.percent_rounded,
              label: 'Scheme Type', hint: 'Select scheme type',
              dropdown: true),
            const _SchemePreviewField(
              icon: Icons.layers_rounded,
              label: 'Apply On', hint: 'Select apply on',
              dropdown: true),
            const _SchemePreviewField(
              icon: Icons.discount_outlined,
              label: 'Discount Value',
              hint: 'Enter discount value'),
            const _SchemePreviewField(
              icon: Icons.calendar_today_outlined,
              label: 'Start Date', hint: 'Select start date'),
            const _SchemePreviewField(
              icon: Icons.calendar_month_outlined,
              label: 'End Date', hint: 'Select end date'),
            const _SchemePreviewField(
              icon: Icons.description_outlined,
              label: 'Description', hint: 'Enter description',
              twoLines: true),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: style.card(radius: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Applicable Products / Categories',
                    style: TextStyle(fontSize: 11,
                      color: style.ink, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  Text('Category    Product    Customer Group',
                    style: TextStyle(fontSize: 11, color: style.muted)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: style.card(radius: 14),
              child: Row(children: [
                Icon(Icons.verified_user_outlined,
                  color: style.scheme.primary),
                const SizedBox(width: 10),
                Text('Status', style: TextStyle(
                  fontWeight: FontWeight.w900, color: style.ink)),
                const Spacer(),
                Text('Active / Inactive',
                  style: TextStyle(fontSize: 12, color: style.muted)),
              ]),
            ),
            const SizedBox(height: 10),
            Text('Preview only: the current server contract requires a '
              'reward product and quantity. Saving is disabled.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: style.muted)),
          ],
        ),
      ]),
    );
  }
}
