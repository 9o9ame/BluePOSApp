import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

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
  bool saving = false, biometricEnabled = false, biometricAvailable = false, biometricBusy = false;
  List<BiometricType> types = [];

  @override
  void initState() {
    super.initState();
    draft = Map<String, dynamic>.from(widget.app.appearance.toJson());
    inspectBiometrics();
  }

  Future<void> inspectBiometrics() async {
    final enrolled = await widget.app.biometric.supportedTypes();
    final active = await widget.app.biometric.enabledFor(widget.app.currentUserUlid);
    if (!mounted) return;
    setState(() {
      types = enrolled;
      biometricAvailable = enrolled.isNotEmpty;
      biometricEnabled = active;
    });
  }

  void set(String name, dynamic value) => setState(() => draft[name] = value);

  Future<void> save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await widget.app.saveAppearance(draft);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Appearance saved to your BluePOS account.')));
    } catch (e) { if (mounted) await showApiError(context, e); }
    finally { if (mounted) setState(() => saving = false); }
  }

  Future<void> toggleBiometric(bool enabled) async {
    if (biometricBusy) return;
    setState(() => biometricBusy = true);
    try {
      if (enabled) {
        final success = await widget.app.activateBiometrics();
        if (mounted && !success) await showApiError(context,
          'Biometric setup cancelled. Enroll fingerprint/face in Android Settings and retry.');
      } else {
        await widget.app.deactivateBiometrics();
      }
      await inspectBiometrics();
    } catch (e) { if (mounted) await showApiError(context, e); }
    finally { if (mounted) setState(() => biometricBusy = false); }
  }

  Future<void> pickBranch() async {
    try {
      final response = await widget.app.api.get('/api/branches');
      final branches = recordsOf(response);
      if (!mounted) return;
      final chosen = await showModalBottomSheet<Map<String, dynamic>>(
        context: context, useSafeArea: true, showDragHandle: true,
        builder: (ctx) => SafeArea(child: ListView(shrinkWrap: true, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Authorized branches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          ...branches.map((branch) => ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(field(branch['name'])),
            subtitle: Text(field(branch['code'])),
            onTap: () => Navigator.pop(ctx, branch),
          )),
        ])));
      if (chosen == null || !mounted) return;
      final target = field(chosen['ulid']);
      final active = field(objectOf(widget.app.session?['branch'])['ulid']);
      if (target == active) return;
      final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Switch branch?'),
        content: const Text('This will discard any unsaved cart. A pending server sale must be resolved before switching.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Switch'))],
      ));
      if (confirmed != true || !mounted) return;
      await widget.app.switchBranch(target);
      if (mounted) Navigator.of(context).pop();
    } catch (e) { if (mounted) await showApiError(context, e); }
  }

  Widget option(String label, String name, List<String> values) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$name-${draft[name]}'),
      initialValue: draft[name] as String?,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values.map((value) => DropdownMenuItem(value: value,
        child: Text(value == '3d' ? '3D' : value.replaceAll('-', ' ').split(' ').map(
          (part) => part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}').join(' ')))).toList(),
      onChanged: (value) {if (value != null) set(name, value);},
    ),
  );

  Widget appearanceMode() => SegmentedButton<String>(
    segments: const [
      ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
      ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
      ButtonSegment(value: 'system', icon: Icon(Icons.phone_android_outlined), label: Text('System')),
    ],
    selected: {field(draft['theme'], 'system')},
    onSelectionChanged: (selection) => set('theme', selection.first),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    return ListView(padding: const EdgeInsets.all(16), children: [
      GradientHero(appearance: app.appearance, child: Row(children: [
        const BlueposBrandMark(size: 58), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(app.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
            fontSize: 19)),
          Text(app.tenantName, style: const TextStyle(color: Colors.white70)),
          Text('${app.branchName} • ${app.warehouseName}', maxLines: 1,
            overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
      ])),
      const SizedBox(height: 20),
      Surface(child: ListTile(leading: const Icon(Icons.storefront_outlined),
        title: const Text('Active branch'),
        subtitle: Text(app.branchName),
        trailing: const Icon(Icons.swap_horiz_rounded),
        onTap: pickBranch)),
      const SizedBox(height: 17),
      const SectionHeading('Appearance'),
      Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Choose your display', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        appearanceMode(),
        const SizedBox(height: 19),
        const Text('Primary theme', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 11),
        Wrap(spacing: 10, runSpacing: 10, children: AppAppearance.palette.entries.map((entry) =>
          InkWell(onTap: () => set('primaryTheme', entry.key), borderRadius: BorderRadius.circular(30),
            child: CircleAvatar(radius: 22, backgroundColor: entry.value,
              child: draft['primaryTheme'] == entry.key ? const Icon(Icons.check, color: Colors.white) : null))).toList()),
        const SizedBox(height: 20),
        option('Interface style', 'skin', ['classic', 'hybrid', 'advanced']),
        option('Font family', 'font',
          ['skin-default', 'inter', 'roboto-condensed', 'segoe-ui', 'tahoma', 'arial']),
        option('Density', 'density', ['compact', 'comfortable']),
        option('Border radius', 'radius', ['small', 'medium', 'large']),
        option('Card shadow', 'shadow', ['none', 'soft', 'normal', '3d']),
        SwitchListTile.adaptive(contentPadding: EdgeInsets.zero,
          title: const Text('UI animations'), subtitle: const Text('Respect motion preferences'),
          value: draft['animations'] == true, onChanged: (v) => set('animations', v)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.check_rounded),
          label: Text(saving ? 'Saving…' : 'Save & Sync Appearance')),
      ])),
      const SizedBox(height: 20),
      const SectionHeading('Biometric Security'),
      Surface(child: Column(children: [
        ListTile(contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.fingerprint_rounded, color: scheme.primary, size: 31),
          title: const Text('Fingerprint / Face Unlock', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(!biometricAvailable
            ? 'No enrolled Android biometrics found. Set up fingerprint or face in Android Settings.'
            : 'Use your enrolled ${types.contains(BiometricType.face) ? 'fingerprint or face' : 'fingerprint / supported biometric'} to unlock a valid BluePOS session.'),
        ),
        SwitchListTile.adaptive(contentPadding: EdgeInsets.zero,
          value: biometricEnabled,
          title: const Text('App lock on return'),
          subtitle: const Text('Requires operating system verification after app resumes.'),
          onChanged: !biometricAvailable || biometricBusy ? null : toggleBiometric),
        Text('First login always requires mart code, password, location and any server device/MFA approvals. Biometrics do not create a new server session.',
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ])),
      const SizedBox(height: 20),
      const SectionHeading('Application'),
      Surface(child: Column(children: [
        const ListTile(leading: Icon(Icons.cloud_done_outlined), title: Text('Live server'), subtitle: Text(apiOrigin)),
        const Divider(height: 1),
        const ListTile(leading: Icon(Icons.security_outlined), title: Text('Access control'),
          subtitle: Text('Permissions, prices, stock and totals remain server-authoritative.')),
        const Divider(height: 1),
        const ListTile(leading: Icon(Icons.info_outline), title: Text('BluePOS Mobile'),
          subtitle: Text('Android design edition • v0.2.1')),
      ])),
      const SizedBox(height: 18),
      OutlinedButton.icon(icon: const Icon(Icons.logout), label: const Text('Sign out'),
        onPressed: saving ? null : () async {
          final should = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text('This clears local session credentials and biometric unlock enrollment for this app.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out'))],
          ));
          if (should == true) await app.logout();
        }),
      const SizedBox(height: 28),
    ]);
  }
}
