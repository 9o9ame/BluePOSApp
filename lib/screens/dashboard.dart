import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'history.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key, required this.app, required this.navigate,
  });
  final AppController app;
  final ValueChanged<int> navigate;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool busy = true;
  String? error;
  int? todayInvoices;
  int? branchInvoices;
  int? productsCount;
  List<Map<String, dynamic>> recent = const [];

  @override
  void initState() { super.initState(); reload(); }

  String _date(DateTime date) =>
    date.year.toString().padLeft(4, '0') + '-' +
    date.month.toString().padLeft(2, '0') + '-' +
    date.day.toString().padLeft(2, '0');

  Future<void> reload() async {
    setState(() { busy = true; error = null; });
    try {
      final today = _date(DateTime.now());
      final result = await Future.wait([
        widget.app.api.get('/api/sales?per_page=5'),
        widget.app.api.get('/api/products?per_page=1'),
        widget.app.api.get('/api/sales?per_page=1&date_from=' +
          today + '&date_to=' + today),
      ]);
      if (!mounted) return;
      setState(() {
        recent = recordsOf(result[0]);
        branchInvoices = int.tryParse(field(
          objectOf(objectOf(result[0])['meta'])['total']));
        productsCount = int.tryParse(field(
          objectOf(objectOf(result[1])['meta'])['total']));
        todayInvoices = int.tryParse(field(
          objectOf(objectOf(result[2])['meta'])['total']));
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _sales() => Navigator.push(context, MaterialPageRoute(
    builder: (_) => DataListScreen(
      app: widget.app, title: 'Sales invoices',
      path: '/api/sales?per_page=25',
      nameKey: 'document_number', subtitleKey: 'sale_date',
      amountKey: 'grand_total', detailPrefix: '/api/sales',
    ),
  ));

  Widget _action(IconData icon, String caption, VoidCallback onPressed) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed, borderRadius: BorderRadius.circular(16),
      child: Surface(padding: const EdgeInsets.symmetric(
        horizontal: 4, vertical: 13),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 24, color: scheme.primary),
          ),
          const SizedBox(height: 9),
          Text(caption, maxLines: 2, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(onRefresh: reload, child: ListView(
      padding: EdgeInsets.all(app.appearance.spacing), children: [
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GOOD MORNING', style: TextStyle(
                color: scheme.primary, fontWeight: FontWeight.w800,
                letterSpacing: 1.5, fontSize: 10)),
              const SizedBox(height: 3),
              Text(app.userName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(app.branchName + ' • ' + app.warehouseName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          )),
          CircleAvatar(radius: 25, backgroundColor: scheme.primaryContainer,
            child: Text(app.userName.isEmpty ? 'B' :
              app.userName.substring(0, 1).toUpperCase(),
              style: TextStyle(color: scheme.primary,
                fontSize: 20, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 16),
        GradientHero(appearance: app.appearance,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.storefront_outlined, color: Colors.white, size: 25),
              const Spacer(),
              const Icon(Icons.verified_user_outlined,
                color: Colors.white70, size: 19),
            ]),
            const SizedBox(height: 10),
            Text(app.tenantName, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white,
                fontSize: 23, fontWeight: FontWeight.w900)),
            const Text('Your secure business workspace',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: () => widget.navigate(1),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: app.appearance.accent),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('New Sale')),
              ),
            ]),
          ])),
        const SizedBox(height: 16),
        const SectionHeading('Business at a glance'),
        if (busy) pageLoading()
        else if (error != null) FailureState(message: error!, retry: reload)
        else Column(children: [
          Row(children: [
            Expanded(child: BpStatCard(
              icon: Icons.today_outlined,
              caption: "Today's invoices",
              value: todayInvoices?.toString() ?? '—',
              hint: 'Current branch')),
            const SizedBox(width: 9),
            Expanded(child: BpStatCard(
              icon: Icons.inventory_2_outlined,
              caption: 'Products',
              value: productsCount?.toString() ?? '—',
              hint: 'Authorized catalog')),
          ]),
          const SizedBox(height: 9),
          BpStatCard(
            icon: Icons.receipt_long_outlined,
            caption: 'All invoices',
            value: branchInvoices?.toString() ?? '—',
            hint: 'Current branch • API record count'),
        ]),
        const SizedBox(height: 16),
        const SectionHeading('Quick actions'),
        GridView.count(
          crossAxisCount: 4,
          childAspectRatio: .78,
          mainAxisSpacing: 8, crossAxisSpacing: 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _action(Icons.point_of_sale_outlined, 'New Sale',
              () => widget.navigate(1)),
            _action(Icons.inventory_2_outlined, 'Products',
              () => widget.navigate(2)),
            _action(Icons.receipt_long_outlined, 'Invoices', _sales),
            _action(Icons.analytics_outlined, 'Reports',
              () => widget.navigate(3)),
          ],
        ),
        const SizedBox(height: 17),
        SectionHeading('Recent invoices',
          trailing: TextButton(onPressed: _sales,
            child: const Text('View all'))),
        if (!busy && error == null)
          if (recent.isEmpty) const EmptyState(title: 'No invoices yet')
          else ...recent.take(5).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Surface(padding: const EdgeInsets.symmetric(
              horizontal: 13, vertical: 12),
              child: Row(children: [
                CircleAvatar(backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.receipt_long_rounded,
                    color: scheme.primary, size: 20)),
                const SizedBox(width: 11),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(field(item['document_number'], 'Invoice'),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(field(item['sale_date']),
                      style: TextStyle(fontSize: 11,
                        color: scheme.onSurfaceVariant)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(money(item['grand_total'], app.currency),
                    style: const TextStyle(fontWeight: FontWeight.w900,
                      fontSize: 12)),
                  Text(field(item['status']),
                    style: TextStyle(fontSize: 10,
                      color: scheme.onSurfaceVariant)),
                ]),
              ]),
            )),
          ),
        const SizedBox(height: 16),
      ],
    ));
  }
}
