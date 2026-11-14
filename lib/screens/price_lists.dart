import 'package:flutter/material.dart';

import '../widgets/common.dart';

/// Newer design reference 22. The inspected BluePOS API has no price-list
/// resource/route. Keep the approved navigation visible without inventing
/// price-list records, permissions, amounts or writable endpoints.
class PriceListsScreen extends StatelessWidget {
  const PriceListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Price Lists')),
      body: ListView(
        key: const ValueKey('price-lists-reference'),
        padding: const EdgeInsets.all(16),
        children: [
          Text('Price Lists', style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(children: [
            const Expanded(child: TextField(
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search price lists...',
                helperText: 'Search available after API integration'))),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Filters not yet available',
              onPressed: null,
              icon: const Icon(Icons.filter_alt_outlined)),
          ]),
          const SizedBox(height: 24),
          Surface(child: Column(children: [
            Icon(Icons.sell_outlined, size: 52, color: scheme.primary),
            const SizedBox(height: 12),
            Text('Price Lists integration pending',
              style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 9),
            const Text(
              'The current BluePOS API does not expose a Price Lists '
              'endpoint. No lists or default prices are shown until '
              'the backend contract and permissions are verified.',
              textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const ValueKey('price-lists-preview-form'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) =>
                  const AddPriceListReferenceScreen())),
              icon: const Icon(Icons.add_rounded),
              label: const Text('View Add Price List design')),
          ])),
        ],
      ),
    );
  }
}

/// Newer design reference 23. This is a non-submittable reference layout,
/// NOT a connected Add Price List form.
class AddPriceListReferenceScreen extends StatelessWidget {
  const AddPriceListReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Price List')),
      body: ListView(
        key: const ValueKey('add-price-list-reference'),
        padding: const EdgeInsets.all(16),
        children: [
          Surface(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Icon(Icons.sell_outlined,
                size: 52, color: scheme.primary)),
              const SizedBox(height: 17),
              const Text('Price List Name *',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const TextField(
                readOnly: true, decoration: InputDecoration(
                  hintText: 'Enter price list name')),
              const SizedBox(height: 12),
              const Text('Price List Code *',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const TextField(
                readOnly: true, decoration: InputDecoration(
                  hintText: 'Backend contract pending')),
              const SizedBox(height: 12),
              const Text('Description',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const TextField(
                readOnly: true, maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter description')),
              const SizedBox(height: 12),
              const Text('Type',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Select type',
                  suffixIcon: Icon(Icons.arrow_drop_down)),
                child: Text('Not available')),
              const SizedBox(height: 12),
              const Text('Applies To',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const InputDecorator(
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.arrow_drop_down)),
                child: Text('Not available')),
              const SizedBox(height: 12),
              const Text('Effective From / To',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const TextField(
                readOnly: true, decoration: InputDecoration(
                  hintText: 'Date range unavailable',
                  suffixIcon: Icon(Icons.calendar_today_outlined))),
              const SizedBox(height: 15),
              Text('This screen is a design reference only. Saving is disabled '
                'until BluePOS exposes a validated, authorized Price Lists API.',
                style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          )),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'))),
            const SizedBox(width: 10),
            const Expanded(child: FilledButton(
              onPressed: null,
              child: Text('Save Price List'))),
          ]),
        ],
      ),
    );
  }
}
