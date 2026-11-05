import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';

/// Browses server-stored POS holds. A hold is retained when recalled; the POS
/// confirms a successful sale before removing a matching hold from the server.
class SaleHoldsScreen extends StatefulWidget {
  const SaleHoldsScreen({super.key, required this.app});
  final AppController app;

  @override
  State<SaleHoldsScreen> createState() => _SaleHoldsScreenState();
}

class _SaleHoldsScreenState extends State<SaleHoldsScreen> {
  List<Map<String, dynamic>> holds = const [];
  bool busy = true;
  String? error;

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { busy = true; error = null; });
    try {
      final data = await widget.app.api.get('/api/sales/holds');
      if (mounted) setState(() => holds = recordsOf(data));
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recall(Map<String, dynamic> row) async {
    final ulid = field(row['ulid']);
    if (!validPublicUlid(ulid)) return;
    try {
      final result = resourceOf(
        await widget.app.api.get('/api/sales/holds/$ulid'));
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Future<void> discard(Map<String, dynamic> row) async {
    if (!widget.app.hasPermission('sales.hold')) return;
    final ulid = field(row['ulid']);
    if (!validPublicUlid(ulid)) return;
    final accepted = await confirmMutation(context,
      title: 'Discard this held sale?',
      warning: 'This removes the saved cart from the server. '
        'It cannot be recovered once deleted.',
      actionLabel: 'Discard Hold');
    if (!accepted || !mounted) return;
    try {
      await widget.app.api.request('DELETE', '/api/sales/holds/$ulid');
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Held Sales')),
      body: RefreshIndicator(onRefresh: refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Saved POS carts'),
          const Text('Choose a hold to load its items back into POS. '
            'Advanced promotional holds may require the web editor.',
            style: TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          if (busy) pageLoading()
          else if (error != null) FailureState(message: error!, retry: refresh)
          else if (holds.isEmpty) const EmptyState(title: 'No held sales')
          else for (final hold in holds) Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Surface(padding: const EdgeInsets.all(13),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(field(objectOf(hold['customer'])['name'], 'Walk-in'),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
                Text('Saved: ${field(hold['held_at'])}',
                  style: TextStyle(fontSize: 11,
                    color: colors.onSurfaceVariant)),
                Text('Items: ${field(hold['sale_line_count'])} '
                  '· Price: ${field(hold['price_type'])}',
                  style: const TextStyle(fontSize: 11)),
                Wrap(spacing: 10, children: [
                  TextButton.icon(
                    onPressed: () => recall(hold),
                    icon: const Icon(Icons.shopping_cart_checkout_outlined),
                    label: const Text('Recall to POS')),
                  if (widget.app.hasPermission('sales.hold'))
                    TextButton.icon(
                      onPressed: () => discard(hold),
                      icon: Icon(Icons.delete_outline, color: colors.error),
                      label: const Text('Discard')),
                ]),
              ]))),
          const SizedBox(height: 30),
        ])),
    );
  }
}
