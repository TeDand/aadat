import 'package:aadat/data/changelog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLastSeenVersionKey = 'last_seen_version';

/// Call once on app startup (after the first frame).
/// - First install: silently records the current version; no popup shown.
/// - Version upgrade: shows the What's New dialog, then records the version.
Future<void> checkAndShowWhatsNew(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final lastSeen = prefs.getString(_kLastSeenVersionKey);

  if (lastSeen == null) {
    // First install — record version without showing anything.
    await prefs.setString(_kLastSeenVersionKey, kAppVersion);
    return;
  }

  if (lastSeen == kAppVersion) return;

  final entries = kChangelog[kAppVersion];
  if (entries == null || entries.isEmpty) {
    await prefs.setString(_kLastSeenVersionKey, kAppVersion);
    return;
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => _WhatsNewDialog(entries: entries),
  );

  await prefs.setString(_kLastSeenVersionKey, kAppVersion);
}

class _WhatsNewDialog extends StatelessWidget {
  const _WhatsNewDialog({required this.entries});

  final List<ChangeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final features = entries.where((e) => e.type == ChangeType.feature).toList();
    final fixes = entries.where((e) => e.type == ChangeType.fix).toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          const Text("What's New"),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version $kAppVersion',
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (features.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'New',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                ...features.map((e) => _ChangeRow(entry: e)),
              ],
              if (fixes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Fixed',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                ...fixes.map((e) => _ChangeRow(entry: e)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.entry});

  final ChangeEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isFeature = entry.type == ChangeType.feature;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isFeature ? Icons.star_outline_rounded : Icons.bug_report_outlined,
            size: 16,
            color: isFeature ? scheme.primary : scheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(entry.description, style: textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
