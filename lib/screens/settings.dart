import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/appearance.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.app});
  final AppController app;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, dynamic> draft;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    draft = Map<String, dynamic>.from(widget.app.appearance.toJson());
  }

  void set(String name, dynamic value) {
    setState(() => draft[name] = value);
  }

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.app.saveAppearance(draft);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appearance saved to your BluePOS account.')));
    } catch (e) {
      if (mounted) await showApiError(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget option(String label, String name, List<String> values) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$name-${draft[name]}'),
      initialValue: draft[name] as String?,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values.map((value) => DropdownMenuItem(value: value,
          child: Text(value == '3d' ? '3D' : value.replaceAll('-', ' ').split(' ').map(
            (part) => part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}').join(' ')))).toList(),
      onChanged: (value) { if (value != null) set(name, value); },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final appearance = widget.app.appearance;
    final scheme = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SectionHeading('Account'),
      Surface(child: ListTile(contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(radius: 24, backgroundColor: appearance.accent,
          child: Text(widget.app.userName.isEmpty ? 'BP' : widget.app.userName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white))),
        title: Text(widget.app.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.app.tenantName),
      )),
      const SizedBox(height: 12),
      Surface(child: Column(children: [
        ListTile(title: const Text('Branch'), subtitle: Text(widget.app.branchName),
          leading: const Icon(Icons.storefront_outlined)),
        const Divider(height: 1),
        ListTile(title: const Text('Warehouse'), subtitle: Text(widget.app.warehouseName),
          leading: const Icon(Icons.warehouse_outlined)),
      ])),
      const SizedBox(height: 18),
      const SectionHeading('Theme & Appearance'),
      Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Syncs with your BluePOS web appearance settings.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 18),
        option('Appearance', 'theme', ['system','light','dark']),
        option('Primary theme', 'primaryTheme', AppAppearance.palette.keys.toList()),
        Wrap(spacing: 12, runSpacing: 12, children: AppAppearance.palette.entries.map((e) {
          return InkWell(onTap: () => set('primaryTheme', e.key),
            child: CircleAvatar(radius: 18, backgroundColor: e.value,
              child: draft['primaryTheme'] == e.key ? const Icon(Icons.check, size: 19, color: Colors.white) : null));
        }).toList()),
        const SizedBox(height: 20),
        option('Interface style', 'skin', ['classic','hybrid','advanced']),
        option('Font family', 'font',
          ['skin-default','inter','roboto-condensed','segoe-ui','tahoma','arial']),
        option('Density', 'density', ['compact','comfortable']),
        option('Border radius', 'radius', ['small','medium','large']),
        option('Card shadow', 'shadow', ['none','soft','normal','3d']),
        SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('UI animations'),
          value: draft['animations'] == true, onChanged: (v) => set('animations', v)),
        const SizedBox(height: 6),
        FilledButton.icon(onPressed: saving ? null : save,
          icon: const Icon(Icons.save_outlined),
          label: Text(saving ? 'Saving…' : 'Save appearance')),
      ])),
      const SizedBox(height: 18),
      const SectionHeading('Application'),
      Surface(child: Column(children: [
        const ListTile(leading: Icon(Icons.cloud_done_outlined),
          title: Text('Connected server'), subtitle: Text(apiOrigin)),
        const ListTile(leading: Icon(Icons.security_outlined),
          title: Text('Secure data'),
          subtitle: Text('Server permissions, tenant context and totals remain authoritative.')),
        const ListTile(leading: Icon(Icons.info_outline),
          title: Text('BluePOS Mobile'), subtitle: Text('First Android preview · v0.1.0')),
      ])),
      const SizedBox(height: 18),
      OutlinedButton.icon(onPressed: saving ? null : () async {
        final should = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('This removes your local secure session from this device.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out'))],
        ));
        if (should == true) await widget.app.logout();
      }, icon: const Icon(Icons.logout), label: const Text('Sign out')),
      const SizedBox(height: 24),
    ]);
  }
}
