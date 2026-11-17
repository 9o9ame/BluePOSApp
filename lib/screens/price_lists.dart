import 'package:flutter/material.dart';

import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'auth_reference_chrome.dart';

/// Screens 22–23: layout is reference-faithful but the backend does not expose
/// a verified Price Lists resource. Never display fictional prices or submit.
class PriceListsScreen extends StatelessWidget {
  const PriceListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Scaffold(
      backgroundColor: style.page,
      appBar: const BpReferenceSubpageAppBar(title: 'Price Lists'),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('price-lists-preview-form'),
        backgroundColor: const Color(0xFF07AD56),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const AddPriceListReferenceScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Price List Preview')),
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        ListView(
          key: const ValueKey('price-lists-reference'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 125),
          children: [
            Row(children: [
              Expanded(child: TextField(
                readOnly: true,
                decoration: style.search('Search price lists...',
                  prefixIcon: const Icon(Icons.search_rounded))
                  .copyWith(isDense: true))),
              const SizedBox(width: 8),
              Container(
                decoration: style.card(radius: 13),
                child: IconButton(
                  tooltip: 'Filters unavailable until API integration',
                  onPressed: null,
                  icon: const Icon(Icons.filter_alt_outlined))),
            ]),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: style.card(),
              child: Column(children: [
                Icon(Icons.sell_outlined, size: 45,
                  color: style.scheme.primary),
                const SizedBox(height: 8),
                Text('Price Lists API not available',
                  style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w900, color: style.ink)),
                const SizedBox(height: 7),
                Text('The reference design is available, but no price '
                  'list records or save endpoint have been verified. '
                  'No sample entries are shown as real data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: style.muted)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) =>
                      const AddPriceListReferenceScreen())),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Add Price List Design')),
              ]),
            ),
          ],
        ),
        const Positioned(left: 0, right: 0, bottom: 0,
          child: IgnorePointer(
            child: AuthReferenceWaves(height: 62))),
      ]),
    );
  }
}

class _PriceReferenceRow extends StatelessWidget {
  const _PriceReferenceRow({
    required this.icon,
    required this.label,
    required this.hint,
    this.multiline = false,
    this.dropdown = false,
  });
  final IconData icon;
  final String label;
  final String hint;
  final bool multiline;
  final bool dropdown;

  @override
  Widget build(BuildContext context) => BpReferenceFormField(
    label: label, hint: hint, icon: icon,
    readOnly: true, maxLines: multiline ? 2 : 1,
    suffixIcon: dropdown
      ? const Icon(Icons.keyboard_arrow_down_rounded) : null);

}

/// Screen 23: visible but non-submittable until a real API & RBAC contract
/// is available. Preview controls must not pretend to save pricing data.
class AddPriceListReferenceScreen extends StatelessWidget {
  const AddPriceListReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Scaffold(
      backgroundColor: style.page,
      appBar: const BpReferenceSubpageAppBar(title: 'Add Price List'),
      bottomNavigationBar: BpReferenceFooter(
        saveKey: const ValueKey('price-list-save-disabled'),
        saveLabel: 'Save Price List',
        onCancel: () => Navigator.of(context).pop()),
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        ListView(
          key: const ValueKey('add-price-list-reference'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 25),
          children: [
            const _PriceReferenceRow(
              icon: Icons.sell_rounded,
              label: 'Price List Name *', hint: 'Enter price list name'),
            const _PriceReferenceRow(
              icon: Icons.qr_code_rounded,
              label: 'Price List Code *', hint: 'Enter price list code'),
            const _PriceReferenceRow(
              icon: Icons.description_outlined,
              label: 'Description', hint: 'Enter description',
              multiline: true),
            const _PriceReferenceRow(
              icon: Icons.layers_outlined,
              label: 'Type', hint: 'Select type', dropdown: true),
            const _PriceReferenceRow(
              icon: Icons.people_alt_outlined,
              label: 'Applies To', hint: 'Select applies to',
              dropdown: true),
            const _PriceReferenceRow(
              icon: Icons.calendar_today_outlined,
              label: 'Effective From', hint: 'Select effective from date'),
            const _PriceReferenceRow(
              icon: Icons.calendar_month_outlined,
              label: 'Effective To', hint: 'Select effective to date'),
            const _PriceReferenceRow(
              icon: Icons.verified_user_outlined,
              label: 'Status', hint: 'Active / Inactive'),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                'Reference preview only. Saving is disabled until a '
                'validated Price Lists API and permissions are available.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: style.muted)),
            ),
          ],
        ),
      ]),
    );
  }
}
