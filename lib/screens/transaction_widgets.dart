import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

/// Strict ULID boundaries for API identifiers. BIGINT database keys are never
/// transported from, or chosen by, a mobile form.
final RegExp publicUlidPattern = RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$');
bool validPublicUlid(String value) => publicUlidPattern.hasMatch(value);

String isoLocalDate(DateTime value) =>
  '${value.year.toString().padLeft(4, '0')}-'
  '${value.month.toString().padLeft(2, '0')}-'
  '${value.day.toString().padLeft(2, '0')}';

bool validPositiveDecimal(String input, int scale) {
  final regex = RegExp('^(?:0|[1-9]\\d*)(?:\\.\\d{1,$scale})?\$');
  final value = Decimal.tryParse(input);
  return regex.hasMatch(input) && value != null && value > Decimal.zero;
}

bool validNonNegativeDecimal(String input, int scale) {
  final regex = RegExp('^(?:0|[1-9]\\d*)(?:\\.\\d{1,$scale})?\$');
  final value = Decimal.tryParse(input);
  return regex.hasMatch(input) && value != null && value >= Decimal.zero;
}

Map<String, dynamic> resourceOf(dynamic response) {
  final object = objectOf(response);
  return object.containsKey('ulid') ? object : objectOf(object['data']);
}

Future<bool> confirmMutation(
  BuildContext context, {
  required String title,
  required String warning,
  required String actionLabel,
}) async {
  return await showDialog<bool>(
    context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(warning),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true),
          child: Text(actionLabel)),
      ],
    ),
  ) ?? false;
}

Future<Map<String, dynamic>?> pickApiRecord(
  BuildContext context, {
  required AppController app,
  required String title,
  required String path,
  String nameKey = 'name',
  String subtitleKey = 'code',
  String searchParam = 'q',
}) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context, showDragHandle: true, useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _ApiRecordPicker(
      app: app, title: title, path: path,
      nameKey: nameKey, subtitleKey: subtitleKey,
      searchParam: searchParam,
    ),
  );
}

/// Shared searchable, server-scoped entity lookup for supplier, customer,
/// account and product selectors. No client-controlled tenant parameters.
class _ApiRecordPicker extends StatefulWidget {
  const _ApiRecordPicker({
    required this.app, required this.title, required this.path,
    required this.nameKey, required this.subtitleKey,
    required this.searchParam,
  });

  final AppController app;
  final String title, path, nameKey, subtitleKey, searchParam;

  @override
  State<_ApiRecordPicker> createState() => _ApiRecordPickerState();
}

class _ApiRecordPickerState extends State<_ApiRecordPicker> {
  final search = TextEditingController();
  Timer? debounce;
  List<Map<String, dynamic>> entries = const [];
  bool loading = true;
  String? error;
  int sequence = 0;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    search.dispose();
    debounce?.cancel();
    super.dispose();
  }

  Future<void> fetch() async {
    final current = ++sequence;
    setState(() { loading = true; error = null; });
    try {
      final uri = Uri.parse(widget.path);
      final parameters = <String, String>{
        ...uri.queryParameters,
        if (search.text.trim().isNotEmpty)
          widget.searchParam: search.text.trim(),
      };
      final next = uri.replace(queryParameters: parameters);
      final result = await widget.app.api.get(next.toString());
      if (!mounted || current != sequence) return;
      setState(() => entries = recordsOf(result).where(
        (row) => validPublicUlid(field(row['ulid']))).toList());
    } catch (ex) {
      if (mounted && current == sequence) {
        setState(() => error = ex.toString());
      }
    } finally {
      if (mounted && current == sequence) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 6, 16, MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Column(children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          TextField(
            controller: search,
            autofocus: true,
            onChanged: (_) {
              debounce?.cancel();
              debounce = Timer(const Duration(milliseconds: 300), fetch);
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search by name or code',
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: loading ? pageLoading()
            : error != null ? FailureState(message: error!, retry: fetch)
            : entries.isEmpty ? const EmptyState(
              title: 'No available records', subtitle: 'Try another search.')
            : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final row = entries[i];
                return ListTile(
                  title: Text(field(row[widget.nameKey], 'Unnamed')),
                  subtitle: Text(field(row[widget.subtitleKey])),
                  leading: CircleAvatar(
                    backgroundColor: palette.primaryContainer,
                    child: Icon(Icons.check_circle_outline_rounded,
                      color: palette.primary)),
                  onTap: () => Navigator.pop(context, row),
                );
              },
            )),
        ]),
      ),
    );
  }
}
