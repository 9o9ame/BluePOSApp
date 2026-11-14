import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Reference screen 10: only owner-authorized device access notifications
/// are currently exposed by the BluePOS API. Other mockup alert types are
/// intentionally not fabricated.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.app});
  final AppController app;

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [
        IconButton(
          tooltip: 'Refresh notifications',
          onPressed: busy ? null : reload,
          icon: const Icon(Icons.refresh_rounded)),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: reload,
      child: NotificationsView(
        notices: notices, unread: unread, busy: busy, error: error,
        selectedTab: tab,
        onTabChanged: (value) => setState(() => tab = value),
        onRead: markRead,
      ),
    ),
  );
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = selectedTab == 2
      ? <Map<String, dynamic>>[]
      : notices;
    return ListView(
      key: const ValueKey('notifications-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: Text('Notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900))),
          if (unread > 0)
            Text('$unread unread', style: TextStyle(
              color: scheme.primary, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 14),
        SegmentedButton<int>(
          key: const ValueKey('notification-filters'),
          segments: const [
            ButtonSegment(value: 0, label: Text('All')),
            ButtonSegment(value: 1, label: Text('Alerts')),
            ButtonSegment(value: 2, label: Text('Activity')),
          ],
          selected: {selectedTab},
          onSelectionChanged: (selection) => onTabChanged(selection.first),
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
            child: Surface(
              padding: const EdgeInsets.all(13),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 49, height: 49,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.devices_rounded,
                      color: scheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Device access ${field(notice['kind'], 'notification')}',
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
                  if (notice['read_at'] == null)
                    IconButton(
                      key: ValueKey('read-${field(notice['ulid'])}'),
                      tooltip: 'Mark notification read',
                      onPressed: () => onRead(notice),
                      icon: Icon(Icons.mark_email_read_outlined,
                        color: scheme.primary)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
