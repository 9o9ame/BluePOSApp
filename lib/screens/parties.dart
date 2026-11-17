import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_surface.dart';
import 'auth_reference_chrome.dart';
import 'customer_detail.dart';
import 'supplier_detail.dart';

/// Exact party endpoint contract: server owns tenant context and linked accounts.
Map<String, dynamic> partyPayload({
  required String type, required String code, required String name,
  required String accountTypeUlid, required bool isActive,
  String contact = '', String mobile = '', String address = '',
  String area = '', String email = '',
  String creditLimitAmount = '', String creditLimitDays = '',
}) {
  if (!const {'customer', 'vendor', 'account'}.contains(type) ||
      code.trim().isEmpty || name.trim().isEmpty ||
      !RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(accountTypeUlid)) {
    throw const FormatException('Invalid party fields');
  }
  return {
    'party_type': type,
    'code': code.trim().toUpperCase(),
    'name': name.trim(),
    'account_type_ulid': accountTypeUlid,
    'address': address.trim(),
    'area': area.trim(),
    'is_active': isActive,
    if (type != 'account') ...{
      'contact_person': contact.trim(), 'mobile': mobile.trim(),
      'email': email.trim(),
      if (creditLimitAmount.trim().isNotEmpty)
        'credit_limit_amount': creditLimitAmount.trim(),
      if (creditLimitDays.trim().isNotEmpty)
        'credit_limit_days': int.parse(creditLimitDays.trim()),
    },
  };
}

class PartyDirectory extends StatefulWidget {
  const PartyDirectory({super.key, required this.app, required this.type});
  final AppController app;
  final String type;
  @override
  State<PartyDirectory> createState() => _PartyDirectoryState();
}

class _PartyDirectoryState extends State<PartyDirectory> {
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = const [];
  // Posted, tenant/branch-scoped balances from the authorized ledger API.
  Map<String, dynamic> postedBalances = const {};
  bool loading = true;
  bool activeOnly = false;
  String? error;

  String get permission => switch (widget.type) {
    'vendor' => 'suppliers',
    'account' => 'accounts',
    _ => 'customers',
  };
  String get title => switch (widget.type) {
    'vendor' => 'Suppliers',
    'account' => 'Accounts',
    _ => 'Customers',
  };
  bool can(String action) => widget.app.hasPermission(permission + '.' + action) ||
    widget.app.hasPermission(permission + '.manage');

  @override
  void initState() { super.initState(); refresh(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> refresh() async {
    if (!can('view')) {
      setState(() { loading = false; error = 'Access denied.'; });
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final data = await widget.app.api.get('/api/parties?type=${widget.type}');
      final loadedRows = recordsOf(data);
      final balances = <String, dynamic>{};
      if (widget.type == 'customer' || widget.type == 'vendor') {
        final identifiers = loadedRows.map((row) => field(row['ulid']))
          .where((id) => RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(id))
          .toList();
        // Backend accepts up to 250 ULIDs; never submit more in one batch.
        for (var offset = 0; offset < identifiers.length; offset += 200) {
          final end = offset + 200 < identifiers.length
              ? offset + 200 : identifiers.length;
          try {
            final response = objectOf(await widget.app.api.post(
              '/api/parties/ledger-balances', {
                'items': identifiers.sublist(offset, end)
                  .map((ulid) => {'type': widget.type, 'ulid': ulid})
                  .toList(),
              }));
            balances.addAll(objectOf(response['balances']));
          } catch (_) {
            // Ledger data is optional in the directory; do not show
            // an invented zero or a stale credit limit as a balance.
            break;
          }
        }
      }
      if (mounted) setState(() {
        rows = loadedRows;
        postedBalances = balances;
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit({Map<String, dynamic>? record}) async {
    final updating = record != null;
    if (!(updating ? can('edit') : can('create'))) return;
    final ulid = field(record?['ulid']);
    if (updating && ulid.length != 26) return;

    List<Map<String, dynamic>> accounts;
    try {
      accounts = recordsOf(await widget.app.api.get('/api/coa/account-types'))
        .where((row) => row['is_active'] != false).toList();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
      return;
    }
    if (!mounted) return;
    final code = TextEditingController(text: field(record?['code']));
    final name = TextEditingController(text: field(record?['name']));
    final contact = TextEditingController(text: field(record?['contact_person']));
    final mobile = TextEditingController(text: field(record?['mobile']));
    final address = TextEditingController(text: field(record?['address']));
    final area = TextEditingController(text: field(record?['area']));
    final email = TextEditingController(text: field(record?['email']));
    final creditLimit = TextEditingController(
      text: field(record?['credit_limit_amount']));
    final creditDays = TextEditingController(
      text: field(record?['credit_limit_days']));
    var selected = field(record?['account_type_ulid']);
    if (!accounts.any((row) => field(row['ulid']) == selected)) selected = '';
    var active = record?['is_active'] != false;
    var saving = false;
    String? message;
    Future<void> saveParty(BuildContext sheet, StateSetter update) async {
                    final amount = creditLimit.text.trim();
                    final days = creditDays.text.trim();
                    if ((amount.isNotEmpty &&
                         !RegExp(r'^\d+(\.\d{1,4})?$').hasMatch(amount)) ||
                        (days.isNotEmpty &&
                         (!RegExp(r'^\d+$').hasMatch(days) ||
                          int.tryParse(days) == null ||
                          int.parse(days) > 99999))) {
                      update(() => message = 'Enter a valid credit limit and days.');
                      return;
                    }
                    if (code.text.trim().isEmpty || name.text.trim().isEmpty ||
                        selected.length != 26) {
                      update(() => message = 'Enter code, name and account type.');
                      return;
                    }
                    update(() { saving = true; message = null; });
                    try {
                      final payload = partyPayload(type: widget.type,
                        code: code.text, name: name.text,
                        accountTypeUlid: selected, isActive: active,
                        contact: contact.text, mobile: mobile.text,
                        address: address.text, area: area.text,
                        email: email.text,
                        creditLimitAmount: creditLimit.text,
                        creditLimitDays: creditDays.text);
                      if (updating) {
                        await widget.app.api.patch('/api/parties/' + ulid, payload);
                      } else {
                        await widget.app.api.post('/api/parties', payload);
                      }
                      if (sheet.mounted) Navigator.pop(sheet, true);
                    } catch (ex) {
                      if (sheet.mounted) update(() => message = ex.toString());
                    } finally {
                      if (sheet.mounted) update(() => saving = false);
                    }
                  }
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => StatefulBuilder(
          builder: (sheet, update) => Scaffold(
            backgroundColor: BpReferenceStyle.of(sheet).page,
            appBar: BpReferenceSubpageAppBar(
              title: updating ? 'Edit $title' :
                'Add ${widget.type == 'vendor' ? 'Supplier' : widget.type == 'customer' ? 'Customer' : 'Account'}'),
            bottomNavigationBar: BpReferenceFooter(
              saveKey: const ValueKey('party-editor-save'),
              saveLabel: updating ? 'Save Changes'
                : 'Save ${widget.type == 'vendor' ? 'Supplier' : widget.type == 'customer' ? 'Customer' : 'Account'}',
              saving: saving,
              onCancel: () => Navigator.pop(sheet, false),
              onSave: () => saveParty(sheet, update)),
            body: Stack(children: [
              const Positioned(top: 0, right: 0,
                child: BpReferenceTopAccent()),
              SafeArea(child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16,
                MediaQuery.viewInsetsOf(sheet).bottom + 22),
              child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                BpReferenceFormField(
                  label: 'Code *', hint: 'Enter party code',
                  fieldKey: const ValueKey('party-editor-code'),
                  icon: Icons.qr_code_rounded, controller: code,
                  maxLength: 64),
                BpReferenceFormField(
                  label: 'Name *', hint: 'Enter name',
                  fieldKey: const ValueKey('party-editor-name'),
                  icon: Icons.person_rounded, controller: name,
                  maxLength: 180),
                BpReferenceFormField(
                  label: 'Account Type *', hint: '',
                  icon: Icons.account_balance_outlined,
                  child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selected.isEmpty ? null : selected,
                  decoration: BpReferenceStyle.of(sheet)
                    .search('Select account type').copyWith(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7)),
                  items: accounts.map((row) => DropdownMenuItem<String>(
                    value: field(row['ulid']),
                    child: Text(field(row['name']),
                      maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: saving ? null : (value) =>
                    update(() => selected = value ?? ''),
                )),
                if (widget.type != 'account') ...[
                  BpReferenceFormField(
                    label: 'Contact Person', hint: 'Enter contact person',
                    icon: Icons.person_outline_rounded,
                    controller: contact, maxLength: 180),
                  BpReferenceFormField(
                    label: 'Mobile Number', hint: 'Enter mobile number',
                    icon: Icons.phone_rounded, controller: mobile,
                    maxLength: 64, keyboardType: TextInputType.phone),
                  BpReferenceFormField(
                    label: 'Email', hint: 'Enter email address',
                    icon: Icons.email_outlined, controller: email,
                    keyboardType: TextInputType.emailAddress),
                ],
                if (widget.type == 'customer' || widget.type == 'vendor')
                  BpReferenceFormField(
                    label: 'City / Area', hint: 'Enter city / area',
                    fieldKey: const ValueKey('party-editor-area'),
                    icon: Icons.location_on_rounded,
                    controller: area, maxLength: 120),
                BpReferenceFormField(
                  label: 'Address', hint: 'Enter address',
                  icon: Icons.home_rounded, controller: address,
                  maxLines: 2),
                if (widget.type == 'customer' || widget.type == 'vendor') ...[
                  BpReferenceFormField(
                    label: 'Credit Limit', hint: 'Enter credit limit',
                    icon: Icons.credit_card_outlined,
                    controller: creditLimit,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  BpReferenceFormField(
                    label: 'Credit Days', hint: 'Enter credit days',
                    icon: Icons.calendar_today_outlined,
                    controller: creditDays,
                    keyboardType: TextInputType.number),
                ],
                BpReferenceFormField(
                  label: 'Status *', hint: '',
                  icon: Icons.verified_user_outlined,
                  child: BpReferenceStatusSelector(
                    active: active, enabled: !saving,
                    onChanged: (value) => update(() => active = value))),
                if (message != null) Text(message!, style: TextStyle(
                  color: Theme.of(sheet).colorScheme.error)),
                const SizedBox(height: 10),
                const SizedBox(height: 12),
              ],
            )),
          )),
        ])))));
      if (saved == true && mounted) {
        await refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully.')));
      }
    } finally {
      code.dispose(); name.dispose(); contact.dispose();
      mobile.dispose(); address.dispose(); area.dispose();
      email.dispose(); creditLimit.dispose(); creditDays.dispose();
    }
  }

  Future<void> openCustomerDetails(Map<String, dynamic> record) async {
    if (widget.type != 'customer' || !can('view')) return;
    final ulid = field(record['ulid']);
    if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(ulid)) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
      CustomerDetailScreen(app: widget.app, customerUlid: ulid,
        onEdit: can('edit') ? () {
          Navigator.of(context).pop();
          edit(record: record);
        } : null)));
    if (mounted) await refresh();
  }

  Future<void> openSupplierDetails(Map<String, dynamic> record) async {
    if (widget.type != 'vendor' || !can('view')) return;
    final ulid = field(record['ulid']);
    if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(ulid)) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
      SupplierDetailScreen(app: widget.app, supplierUlid: ulid,
        onEdit: can('edit') ? () {
          Navigator.of(context).pop();
          edit(record: record);
        } : null)));
    if (mounted) await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.type == 'customer';
    final isSupplier = widget.type == 'vendor';
    final query = search.text.trim().toLowerCase();
    final filtered = rows.where((row) =>
      (!activeOnly || row['is_active'] != false) &&
      (query.isEmpty ||
        ('${field(row['name'])} ${field(row['code'])} ${field(row['mobile'])}')
          .toLowerCase().contains(query))).toList();
    final style = BpReferenceStyle.of(context);
    return Scaffold(
      backgroundColor: style.page,
      appBar: BpReferenceSubpageAppBar(title: title),
      floatingActionButton: can('create')
        ? SizedBox(width: 80, height: 80,
          child: FloatingActionButton(
            key: const ValueKey('party-add'),
            onPressed: () => edit(),
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF0DBA61),
            shape: const CircleBorder(side: BorderSide(
              color: Colors.white, width: 2.5)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 27),
                Text(isCustomer ? 'Add Customer'
                  : isSupplier ? 'Add Supplier' : 'Add Account',
                  style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900)),
              ]),
          ))
        : null,
      body: Stack(children: [
        const Positioned(top: 0, right: 0,
          child: BpReferenceTopAccent()),
        RefreshIndicator(onRefresh: refresh,
          child: ListView(
            key: const ValueKey('party-directory-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 105),
            children: [
              Row(children: [
                Expanded(child: TextField(
                  key: const ValueKey('party-search'),
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: style.search(
                    'Search ${title.toLowerCase()}...',
                    prefixIcon: const Icon(Icons.search_rounded))
                    .copyWith(isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8)))),
                if (isCustomer || isSupplier) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: style.card(radius: 12),
                    child: IconButton(
                      tooltip: 'Active records filter',
                      key: const ValueKey('party-filter'),
                      onPressed: () =>
                        setState(() => activeOnly = !activeOnly),
                      icon: Icon(activeOnly ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                        color: style.scheme.primary))),
                ],
              ]),
              const SizedBox(height: 12),
              if (loading) pageLoading()
              else if (error != null)
                FailureState(message: error!, retry: refresh)
              else if (filtered.isEmpty)
                EmptyState(title: rows.isEmpty
                  ? 'No ${title.toLowerCase()} yet'
                  : 'No matching ${title.toLowerCase()}')
              else
                for (var i = 0; i < filtered.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('party-row-${field(filtered[i]['ulid'])}'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: isCustomer
                          ? () => openCustomerDetails(filtered[i])
                          : isSupplier
                            ? () => openSupplierDetails(filtered[i])
                            : can('edit') ? () => edit(record: filtered[i]) : null,
                        child: Container(
                          height: 73,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          decoration: style.card(radius: 14),
                          child: Row(children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF168EF7)
                                  .withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(12)),
                              child: Icon(isSupplier
                                ? Icons.local_shipping_rounded
                                : Icons.storefront_rounded,
                                color: const Color(0xFF168EF7),
                                size: 25)),
                            const SizedBox(width: 9),
                            Expanded(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(field(filtered[i]['name'], 'Unnamed'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: style.ink)),
                                Text(field(filtered[i]['code']),
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 10,
                                    color: style.muted)),
                                if (field(filtered[i]['area']).isNotEmpty)
                                  Text(field(filtered[i]['area']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10,
                                      color: style.muted))
                                else if (field(filtered[i]['mobile']).isNotEmpty)
                                  Text(field(filtered[i]['mobile']),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10,
                                      color: style.muted)),
                              ]),
                            ),
                            if ((isCustomer || isSupplier) &&
                                postedBalances.containsKey(
                                  '${widget.type}:${field(filtered[i]['ulid'])}'))
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 96),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Posted balance', maxLines: 1,
                                      style: TextStyle(fontSize: 9,
                                        color: style.muted)),
                                    Text(field(postedBalances[
                                      '${widget.type}:${field(filtered[i]['ulid'])}']),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10,
                                        color: style.green,
                                        fontWeight: FontWeight.w900)),
                                  ])),
                            if (isSupplier || isCustomer)
                              Padding(
                                padding: const EdgeInsets.only(left: 3),
                                child: Icon(Icons.chevron_right_rounded,
                                  size: 18, color: style.muted)),
                          ]),
                        ),
                      ),
                    ),
                  ),
            ],
          )),
        const Positioned(left: 0, right: 0, bottom: 0,
          child: IgnorePointer(child: AuthReferenceWaves(height: 52))),
      ]),
    );
  }
}
