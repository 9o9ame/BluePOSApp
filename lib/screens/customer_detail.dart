import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'auth_reference_chrome.dart';

/// Screen 28: public-ULID server-authorized customer details.
/// Never display fabricated receivables, limits, or transaction figures.
class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.app,
    required this.customerUlid, this.onEdit});
  final AppController app;
  final String customerUlid;
  final VoidCallback? onEdit;
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Map<String, dynamic>? customer;
  bool loading = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')
          .hasMatch(widget.customerUlid)) {
        throw const FormatException('Invalid customer reference');
      }
      final result = objectOf(await widget.app.api.get(
        '/api/parties/${widget.customerUlid}?type=customer'));
      if (mounted) setState(() {
        customer = objectOf(result['data']).isNotEmpty
          ? objectOf(result['data']) : result;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BpReferenceStyle.of(context).page,
    appBar: const BpReferenceSubpageAppBar(title: 'Customer Detail'),
    body: loading ? const Center(child: CircularProgressIndicator())
      : error != null ? FailureState(message: error!, retry: load)
      : RefreshIndicator(onRefresh: load, child: CustomerDetailView(
        customer: customer ?? const {},
        canEdit: widget.app.hasPermission('customers.edit') ||
          widget.app.hasPermission('customers.manage'),
        onEdit: widget.onEdit)),
  );
}

class CustomerDetailView extends StatelessWidget {
  const CustomerDetailView({super.key, required this.customer,
    this.canEdit = false, this.onEdit});
  final Map<String, dynamic> customer;
  final bool canEdit;
  final VoidCallback? onEdit;

  Widget _line(BuildContext context, String name, dynamic value,
      IconData icon) => BpReferenceDetailLine(
        label: name, value: field(value), icon: icon);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = BpReferenceStyle.of(context);
    final credit = customer['credit_limit_amount'];
    return ListView(
      key: const ValueKey('customer-detail-view'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 85), children: [
        Container(padding: const EdgeInsets.all(11),
          decoration: style.card(radius: 16), child: Row(children: [
          Container(width: 62, height: 62, decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.people_alt_outlined,
              color: scheme.primary, size: 34)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field(customer['name'], 'Customer'),
                style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900)),
              Text(field(customer['code'], 'Code not available'),
                style: TextStyle(color: scheme.onSurfaceVariant)),
              Text(customer['is_active'] == false ? 'Inactive' : 'Active',
                style: TextStyle(fontWeight: FontWeight.w800,
                  color: customer['is_active'] == false
                    ? scheme.error : scheme.primary)),
            ])),
        ])),
        const SizedBox(height: 12),
        Container(decoration: style.card(radius: 16), child: Column(children: [
          _line(context, 'Mobile Number', customer['mobile'], Icons.phone_outlined),
          const Divider(height: 1),
          _line(context, 'Area / City', customer['area'], Icons.location_on_outlined),
          const Divider(height: 1),
          _line(context, 'Address', customer['address'], Icons.home_outlined),
          const Divider(height: 1),
          _line(context, 'Contact Person', customer['contact_person'],
            Icons.person_outline),
          const Divider(height: 1),
          _line(context, 'Email', customer['email'], Icons.email_outlined),
          if (credit != null) ...[
            const Divider(height: 1),
            _line(context, 'Credit Limit', credit, Icons.credit_card_outlined),
          ],
        ])),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(12),
          decoration: style.card(radius: 16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Recent Transactions', style: Theme.of(context)
              .textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Transaction and receivable amounts are not included '
              'in the customer details response. No estimated balance is shown.'),
          ],
        )),
        if (canEdit && onEdit != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('customer-detail-edit'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Customer')),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}
