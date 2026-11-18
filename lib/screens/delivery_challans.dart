import 'package:flutter/material.dart';

import '../widgets/reference_surface.dart';

/// References 51–53. The existing BluePOS API has no delivery challan
/// endpoints. These screens intentionally do not fabricate server records,
/// document numbers, dispatch statuses, stock posting or write payloads.
enum DeliveryChallanReferencePage { list, form, detail }

class DeliveryChallanReferenceScreen extends StatelessWidget {
  const DeliveryChallanReferenceScreen({
    super.key, this.page = DeliveryChallanReferencePage.list,
  });

  final DeliveryChallanReferencePage page;

  static const contractNote =
    'Delivery Challans are not available in the current BluePOS API. '
    'This screen is a visual preview; no document can be saved, '
    'dispatched, printed or shared until its actual server workflow '
    'and permissions are implemented.';

  String get title => switch (page) {
    DeliveryChallanReferencePage.list => 'Delivery Challans',
    DeliveryChallanReferencePage.form => 'Create Delivery Challan',
    DeliveryChallanReferencePage.detail => 'Delivery Challan Detail',
  };

  void open(BuildContext context, DeliveryChallanReferencePage next) {
    Navigator.push<void>(context,
      MaterialPageRoute(builder: (_) =>
        DeliveryChallanReferenceScreen(page: next)));
  }

  @override
  Widget build(BuildContext context) {
    final style = BpReferenceStyle.of(context);
    return Scaffold(
      backgroundColor: style.page,
      appBar: BpReferenceSubpageAppBar(
        title: title, titleBelowBack: true),
      floatingActionButton: page == DeliveryChallanReferencePage.list
        ? FloatingActionButton.extended(
            backgroundColor: const Color(0xFF05B856),
            foregroundColor: Colors.white,
            onPressed: () => open(
              context, DeliveryChallanReferencePage.form),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Challan'))
        : null,
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        ListView(
          key: ValueKey('challan-reference-${page.name}'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 110),
          children: [
            if (page == DeliveryChallanReferencePage.list) ...[
              TextField(
                readOnly: true,
                decoration: style.search(
                  'Search challan, customer or invoice...',
                  prefixIcon: const Icon(Icons.search_rounded))),
              const SizedBox(height: 18),
              Center(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.local_shipping_outlined, size: 48,
                    color: style.muted),
                  const SizedBox(height: 8),
                  Text('No delivery challans',
                    style: TextStyle(color: style.ink,
                      fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('No challan records can be loaded until '
                    'the BluePOS server exposes the workflow.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5,
                      color: style.muted)),
                ]),
              )),
            ],
            if (page == DeliveryChallanReferencePage.form) ...[
              BpReferenceInlinePanel(children: [
                BpReferenceInlineRow(
                  label: 'Challan Number',
                  icon: Icons.receipt_long_outlined,
                  child: Text('Server endpoint pending',
                    style: TextStyle(color: style.muted,
                      fontSize: 10.5))),
                BpReferenceInlineRow(
                  label: 'Sales Invoice',
                  icon: Icons.description_outlined,
                  child: Text('No verified selection API',
                    style: TextStyle(color: style.muted,
                      fontSize: 10.5))),
                BpReferenceInlineRow(
                  label: 'Dispatch',
                  icon: Icons.local_shipping_outlined,
                  child: Text('Not available',
                    style: TextStyle(color: style.muted,
                      fontSize: 10.5))),
              ]),
              const SizedBox(height: 10),
              BpReferenceInlinePanel(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Icon(Icons.inventory_2_outlined,
                      color: style.scheme.primary),
                    const SizedBox(width: 9),
                    Expanded(child: Text('Delivery Items',
                      style: TextStyle(color: style.ink,
                        fontWeight: FontWeight.w900))),
                    Text('0', style: TextStyle(color: style.muted)),
                  ]),
                ),
              ]),
            ],
            if (page == DeliveryChallanReferencePage.detail) ...[
              BpReferenceInlinePanel(children: [
                BpReferenceInlineRow(
                  label: 'Document',
                  icon: Icons.description_outlined,
                  child: Text('No server record',
                    style: TextStyle(color: style.muted))),
                BpReferenceInlineRow(
                  label: 'Delivery Status',
                  icon: Icons.local_shipping_outlined,
                  child: Text('Unavailable',
                    style: TextStyle(color: style.muted))),
              ]),
              const SizedBox(height: 10),
              BpReferenceInlinePanel(children: [
                Padding(padding: const EdgeInsets.all(14),
                  child: Text('No delivery lines are available.',
                    style: TextStyle(color: style.muted))),
              ]),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: style.card(radius: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                    color: style.scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(contractNote,
                    style: TextStyle(color: style.muted,
                      fontSize: 11))),
                ],
              ),
            ),
            if (page == DeliveryChallanReferencePage.list)
              TextButton.icon(
                key: const ValueKey('challan-detail-preview'),
                onPressed: () => open(
                  context, DeliveryChallanReferencePage.detail),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Preview detail layout')),
          ],
        ),
        const Positioned(bottom: 0, left: 0, right: 0,
          child: IgnorePointer(child: BpReferenceFooterWave())),
      ]),
      bottomNavigationBar: page == DeliveryChallanReferencePage.list
        ? null : BpReferenceWorkflowActions(
            leftLabel: 'Back',
            rightLabel: page == DeliveryChallanReferencePage.form
              ? 'Dispatch Unavailable' : 'Print Unavailable',
            leftIcon: Icons.arrow_back_outlined,
            rightIcon: Icons.block_outlined,
            onLeft: () => Navigator.of(context).maybePop(),
            onRight: null),
    );
  }
}
