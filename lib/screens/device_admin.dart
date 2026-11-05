import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import 'transaction_widgets.dart';

class DeviceAdminScreen extends StatefulWidget {
  const DeviceAdminScreen({super.key, required this.app});
  final AppController app;
  @override
  State<DeviceAdminScreen> createState() => _DeviceAdminScreenState();
}

class _DeviceAdminScreenState extends State<DeviceAdminScreen> {
  List<Map<String, dynamic>> devices = const [];
  List<Map<String, dynamic>> requests = const [];
  List<Map<String, dynamic>> notifications = const [];
  bool loading = true;
  String? error, ownerOnlyMessage;
  int unread = 0, pending = 0;

  @override
  void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await widget.app.api.get('/api/devices');
      List<Map<String, dynamic>> nextRequests = const [],
        nextNotifications = const [];
      int nextUnread = 0, nextPending = 0;
      String? note;
      // Access reviews and notifications are visible to tenant owners only.
      try {
        final res = objectOf(await widget.app.api.get(
          '/api/devices/access-requests?status=pending&per_page=50'));
        nextRequests = recordsOf(res['requests']);
        nextPending = int.tryParse(field(res['pending_count'])) ?? 0;
        final notifs = objectOf(await widget.app.api.get(
          '/api/devices/access-notifications'));
        nextNotifications = recordsOf(notifs['notifications']);
        nextUnread = int.tryParse(field(notifs['unread_count'])) ?? 0;
      } on ApiFailure catch (ex) {
        note = ex.status == 403
          ? 'Device access requests are restricted to tenant owners.'
          : ex.message;
      } catch (_) {
        note = 'Access reviews could not be loaded.';
      }
      if (mounted) setState(() {
        devices = recordsOf(response);
        requests = nextRequests;
        notifications = nextNotifications;
        pending = nextPending; unread = nextUnread;
        ownerOnlyMessage = note;
      });
    } catch (ex) {
      if (mounted) setState(() => error = ex.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> command(
    String path, String title, String warning, {
    Map<String, dynamic> payload = const {},
  }) async {
    final approved = await confirmMutation(context,
      title: title, warning: warning, actionLabel: 'Confirm');
    if (!approved || !mounted) return;
    try {
      await widget.app.api.post(path, payload);
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Future<void> assignBranch(Map<String, dynamic> device) async {
    if (!widget.app.hasPermission('devices.assign_branch')) return;
    final id = field(device['ulid']);
    if (!validPublicUlid(id)) return;
    final branch = await pickApiRecord(context,
      app: widget.app, title: 'Assign device branch', path: '/api/branches');
    if (branch == null || !mounted) return;
    final branchId = field(branch['ulid']);
    if (!validPublicUlid(branchId)) return;
    if (!await confirmMutation(context,
      title: 'Assign device to this branch?',
      warning: 'Device warehouse assignment will be cleared. '
        'The server will validate device access to this tenant.',
      actionLabel: 'Assign Branch')) return;
    try {
      await widget.app.api.patch('/api/devices/$id',
        {'branch_ulid': branchId, 'warehouse_ulid': null});
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Future<void> markRead(Map<String, dynamic> notice) async {
    final id = field(notice['ulid']);
    if (!validPublicUlid(id) || notice['read_at'] != null) return;
    try {
      await widget.app.api.post(
        '/api/devices/access-notifications/$id/read', {});
      if (mounted) await refresh();
    } catch (ex) {
      if (mounted) await showApiError(context, ex);
    }
  }

  Widget deviceCard(Map<String, dynamic> device) {
    final colors = Theme.of(context).colorScheme;
    final id = field(device['ulid']);
    final status = field(device['status']);
    final isBrowser = field(device['device_type']) == 'browser';
    final requiresReview = field(device['employee_access_policy']) == 'managed';
    return Padding(padding: const EdgeInsets.only(bottom: 9),
      child: Surface(padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isBrowser ? Icons.language_outlined
              : Icons.smartphone_outlined, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(field(device['name'], 'Device'),
              style: const TextStyle(fontWeight: FontWeight.w900))),
            Text(status, style: TextStyle(
              color: status == 'revoked' ? colors.error : colors.primary,
              fontSize: 11)),
          ]),
          Text('${field(device['device_type'])} · '
            '${field(objectOf(device['branch'])['name'], 'Unassigned branch')}',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
          if (device['associated_usernames'] is List)
            Text((device['associated_usernames'] as List).join(', '),
              style: const TextStyle(fontSize: 11)),
          if (field(device['last_seen_at']).isNotEmpty)
            Text('Last seen: ${field(device['last_seen_at'])}',
              style: const TextStyle(fontSize: 10)),
          Wrap(spacing: 5, children: [
            if (widget.app.hasPermission('devices.assign_branch'))
              TextButton(onPressed: () => assignBranch(device),
                child: const Text('Assign Branch')),
            if (status != 'active' && status != 'revoked' &&
                !isBrowser && !requiresReview &&
                widget.app.hasPermission('devices.approve'))
              TextButton(onPressed: () => command(
                '/api/devices/$id/approve',
                'Approve device?',
                'Device enrollment must be authorized by your organization.'),
                child: const Text('Approve')),
            if (status == 'active' &&
                widget.app.hasPermission('devices.revoke'))
              TextButton(onPressed: () => command(
                '/api/devices/$id/revoke',
                'Revoke device?',
                'This revokes active device sessions. '
                  'You cannot revoke your currently authenticating device.'),
                child: const Text('Revoke')),
            if (status == 'revoked' &&
                widget.app.hasPermission('devices.revoke'))
              TextButton(onPressed: () => command(
                '/api/devices/$id/restore',
                'Restore revoked device?',
                'Only the tenant owner can restore access. '
                'Revoked sessions stay revoked.'),
                child: const Text('Restore')),
          ]),
        ])),
    );
  }

  Widget requestCard(Map<String, dynamic> row) {
    final colors = Theme.of(context).colorScheme;
    final id = field(row['ulid']);
    return Padding(padding: const EdgeInsets.only(bottom: 9),
      child: Surface(padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${field(row['username'])} · ${field(row['device_name'])}',
            style: const TextStyle(fontWeight: FontWeight.w900)),
          Text('Requested: ${field(row['created_at'])}',
            style: TextStyle(fontSize: 11,
              color: colors.onSurfaceVariant)),
          Text('Status: ${field(row['status'])}',
            style: const TextStyle(fontSize: 11)),
          if (row['status'] == 'pending' && validPublicUlid(id))
            Wrap(spacing: 8, children: [
              TextButton.icon(
                onPressed: () => command(
                  '/api/devices/access-requests/$id/review',
                  'Approve employee device access?',
                  'This grants the requested staff access after server '
                    'owner authority and device/network validation.',
                  payload: const {'decision': 'approved'}),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Approve')),
              TextButton.icon(
                onPressed: () => command(
                  '/api/devices/access-requests/$id/review',
                  'Reject employee device access?',
                  'This denies the staff access request.',
                  payload: const {'decision': 'rejected'}),
                icon: Icon(Icons.block_rounded, color: colors.error),
                label: const Text('Reject')),
            ]),
        ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Devices & Access')),
      body: RefreshIndicator(onRefresh: refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const SectionHeading('Authorized devices'),
          if (loading) pageLoading()
          else if (error != null) FailureState(message: error!, retry: refresh)
          else ...[
            if (devices.isEmpty)
              const EmptyState(title: 'No devices registered')
            else ...devices.map(deviceCard),
            const SizedBox(height: 10),
            SectionHeading('Employee access requests',
              trailing: Text('$pending pending')),
            if (ownerOnlyMessage != null)
              Text(ownerOnlyMessage!, style: TextStyle(
                fontSize: 11, color: colors.onSurfaceVariant)),
            if (requests.isEmpty)
              const EmptyState(title: 'No pending access requests')
            else ...requests.map(requestCard),
            const SizedBox(height: 12),
            SectionHeading('Device notifications',
              trailing: Text('$unread unread')),
            if (notifications.isEmpty)
              const EmptyState(title: 'No device notifications')
            else for (final notice in notifications)
              Padding(padding: const EdgeInsets.only(bottom: 8),
                child: Surface(padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text('${field(notice['username'])} · '
                      '${field(notice['device_name'])}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(field(notice['kind']),
                      style: const TextStyle(fontSize: 11)),
                    Text(field(notice['created_at']),
                      style: const TextStyle(fontSize: 10)),
                    if (notice['read_at'] == null &&
                        validPublicUlid(field(notice['ulid'])))
                      TextButton(
                        onPressed: () => markRead(notice),
                        child: const Text('Mark as read')),
                  ]))),
          ],
          const SizedBox(height: 70),
        ])),
    );
  }
}
