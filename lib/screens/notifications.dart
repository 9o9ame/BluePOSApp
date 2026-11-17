import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/reference_navigation.dart';
import 'auth_reference_chrome.dart';

/// Reference screen 10: only owner-authorized device access notifications
/// are currently exposed by the BluePOS API. Other mockup alert types are
/// intentionally not fabricated.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.app,
    this.onNavigate, this.onScan});
  final AppController app;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onScan;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notices = const [];
  bool busy = true;
  String? error;
  int unread = 0;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() { busy = true; error = null; });
    try {
      final response = objectOf(
        await widget.app.api.get('/api/devices/access-notifications'));
      if (!mounted) return;
      setState(() {
        notices = recordsOf(response['notifications']);
        unread = int.tryParse(field(response['unread_count'])) ?? 0;
      });
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        notices = const [];
        error = e.status == 403
          ? 'Device notifications are available to tenant owners only.'
          : e.message;
      });
    } catch (_) {
      if (mounted) setState(() {
        notices = const [];
        error = 'Notifications could not be loaded.';
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> markRead(Map<String, dynamic> notice) async {
    if (notice['read_at'] != null) return;
    final ulid = field(notice['ulid']);
    if (ulid.length != 26) return;
    try {
      await widget.app.api.post(
        '/api/devices/access-notifications/$ulid/read', {});
      if (mounted) await reload();
    } catch (e) {
      if (mounted) await showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF068A70),
        brightness: Brightness.light,
        surface: const Color(0xFFF7F8FF)),
      scaffoldBackgroundColor: const Color(0xFFF7F8FF),
      cardColor: Colors.white,
      textTheme: theme.textTheme.apply(
        bodyColor: const Color(0xFF101F43),
        displayColor: const Color(0xFF101F43)),
    );
    return Theme(data: light, child: Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FF),
        foregroundColor: const Color(0xFF081943),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back to More',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!(4);
            } else {
              Navigator.of(context).maybePop();
            }
          }),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const BlueposBrandMark(size: 37),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text.rich(TextSpan(children: [
                TextSpan(text: 'Blue',
                  style: TextStyle(color: Color(0xFF081943))),
                TextSpan(text: 'POS',
                  style: TextStyle(color: Color(0xFF058DF5))),
              ]), style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.w900)),
              const Text('P O S  &  E R P',
                style: TextStyle(fontSize: 7,
                  color: Color(0xFF081943),
                  fontWeight: FontWeight.w700)),
            ]),
        ]),
        actions: [
          const Icon(Icons.notifications_none_rounded,
            color: Color(0xFF081943)),
          const SizedBox(width: 17),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
          child: Row(children: [
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded,
                color: Color(0xFF081943)),
              onPressed: () => Navigator.of(context).maybePop()),
            const SizedBox(width: 4),
            const Expanded(child: Text('Notifications',
              style: TextStyle(color: Color(0xFF081943),
                fontSize: 22, fontWeight: FontWeight.w900))),
            PopupMenuButton<int>(
              key: const ValueKey('notification-filter-menu'),
              tooltip: 'Filter notifications',
              icon: const Icon(Icons.filter_alt_outlined,
                color: Color(0xFF081943)),
              onSelected: (value) => setState(() => tab = value),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 0, child: Text('All notifications')),
                PopupMenuItem(value: 1, child: Text('Alerts')),
                PopupMenuItem(value: 2, child: Text('Activity')),
              ]),
          ]),
        ),
        Expanded(child: Stack(children: [
          const Positioned(left: 0, right: 0, bottom: 0,
            child: AuthReferenceWaves(height: 65)),
          RefreshIndicator(
            onRefresh: reload,
            child: NotificationsView(
              notices: notices, unread: unread, busy: busy, error: error,
              selectedTab: tab,
              onTabChanged: (value) => setState(() => tab = value),
              onRead: markRead,
            ),
          ),
        ])),
      ]),
      bottomNavigationBar: widget.onNavigate == null
        ? null
        : BlueposReferenceNav(
            selectedIndex: 4,
            onSelect: widget.onNavigate!,
            onScan: widget.onScan ?? () {},
          ),
    ));
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({
    super.key,
    required this.notices,
    required this.unread,
    required this.busy,
    required this.error,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onRead,
  });

  final List<Map<String, dynamic>> notices;
  final int unread;
  final bool busy;
  final String? error;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<Map<String, dynamic>> onRead;

  String _noticeTitle(Map<String, dynamic> notice) {
    return switch (field(notice['kind'])) {
      'new_device' => 'New device approval request',
      'new_network' => 'New network approval request',
      'device_reactivated' => 'Device approval updated',
      _ => 'Device access notification',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = selectedTab == 2
      ? <Map<String, dynamic>>[]
      : notices;
    return ListView(
      key: const ValueKey('notifications-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 112),
      children: [
        if (unread > 0)
          Align(alignment: Alignment.centerRight,
            child: Text('$unread unread',
              style: const TextStyle(color: Color(0xFF068B75),
                fontSize: 12, fontWeight: FontWeight.w800))),
        const SizedBox(height: 6),
        Row(
          key: const ValueKey('notification-filters'),
          children: [
            for (final filter in const [
              (0, 'All', Icons.notifications_none_rounded),
              (1, 'Alerts', Icons.warning_amber_rounded),
              (2, 'Activity', Icons.monitor_heart_outlined),
            ]) ...[
              Expanded(child: ChoiceChip(
                label: Text(filter.$2,
                  style: TextStyle(
                    color: selectedTab == filter.$1
                      ? Colors.white : const Color(0xFF17254A),
                    fontSize: 12, fontWeight: FontWeight.w800)),
                avatar: filter.$1 == 0 ? null
                  : Icon(filter.$3, size: 16,
                    color: filter.$1 == 1
                      ? const Color(0xFFE14B61)
                      : const Color(0xFF2B7CE8)),
                selected: selectedTab == filter.$1,
                selectedColor: const Color(0xFF05AE80),
                labelStyle: TextStyle(
                  color: selectedTab == filter.$1
                    ? Colors.white : const Color(0xFF142A52),
                  fontWeight: FontWeight.w800),
                backgroundColor: const Color(0xFFF3F5FF),
                showCheckmark: false,
                side: BorderSide.none,
                onSelected: (_) => onTabChanged(filter.$1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              )),
              if (filter.$1 != 2) const SizedBox(width: 7),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (busy)
          const Padding(padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()))
        else if (error != null)
          Surface(child: Column(children: [
            Icon(Icons.lock_outline_rounded, color: scheme.onSurfaceVariant),
            const SizedBox(height: 9),
            Text(error!, textAlign: TextAlign.center),
          ]))
        else if (visible.isEmpty)
          EmptyState(
            icon: selectedTab == 2
              ? Icons.history_rounded : Icons.notifications_none_rounded,
            title: selectedTab == 2
              ? 'Activity feed not available'
              : 'No notifications',
            subtitle: selectedTab == 2
              ? 'A general activity notification feed is not yet provided by BluePOS.'
              : 'Authorized device access alerts will appear here.'),
        for (final notice in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Colors.white, Color(0xFFF3F6FF)]),
                border: Border.all(color: Colors.white, width: 1.5),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [BoxShadow(color: Color(0x23566DB0),
                  blurRadius: 10, offset: Offset(0, 5))]),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 49, height: 49,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEEFF),
                      borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.devices_rounded,
                      color: Color(0xFF087DF1))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_noticeTitle(notice),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        field(notice['device_name'], 'Device') +
                          ' · ' + field(notice['username'], 'Team member'),
                        maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 7),
                      Text(field(notice['created_at'], ''),
                        style: TextStyle(color: scheme.onSurfaceVariant,
                          fontSize: 11)),
                    ],
                  )),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    if (notice['read_at'] == null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: CircleAvatar(
                          radius: 4, backgroundColor: Color(0xFFE62944))),
                    IconButton(
                      key: ValueKey('read-${field(notice['ulid'])}'),
                      tooltip: 'Mark notification read',
                      onPressed: notice['read_at'] == null
                        ? () => onRead(notice) : null,
                      icon: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF31466A))),
                  ]),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}
