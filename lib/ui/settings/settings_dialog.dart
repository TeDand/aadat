import 'package:aadat/data/repositories/habit_model.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/settings/settings_viewmodel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Explains duplicate title rejection from [HabitService].
Future<void> showDuplicateHabitNameDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Name already in use'),
      content: const Text(
        'Another habit already has this title. Each habit needs a unique name so the app can tell them apart. Choose a different title and try again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showAppSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _AppSettingsDialog(),
  );
}

class _AppSettingsDialog extends StatelessWidget {
  const _AppSettingsDialog();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          const Text('Settings'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Appearance',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<SettingsViewModel>(
                builder: (context, settings, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Theme',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto, size: 18),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined, size: 18),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined, size: 18),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (next) {
                          if (next.isNotEmpty) {
                            settings.setThemeMode(next.first);
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'System follows your device appearance.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'Calendar',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Consumer<HomeViewModel>(
                builder: (context, vm, _) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Week starts on Monday'),
                    subtitle: Text(
                      vm.weekStartsOnMonday
                          ? 'Weeks and day columns: Mon → Sun'
                          : 'Weeks and day columns: Sun → Sat',
                    ),
                    value: vm.weekStartsOnMonday,
                    onChanged: (v) => vm.setWeekStartsOnMonday(v),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Applies to the calendar day grid, week rows, and how weeks are counted elsewhere.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'Habits',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<SettingsViewModel>(
                builder: (context, settings, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Default recurrence for new habits',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DropdownButton<HabitRecurrence>(
                          value: settings.defaultHabitRecurrence,
                          items: HabitRecurrence.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              settings.setDefaultHabitRecurrence(v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Confirm before deleting a habit'),
                        subtitle: const Text(
                          'Shows a confirmation when you delete from the Home list.',
                        ),
                        value: settings.confirmBeforeDelete,
                        onChanged: settings.setConfirmBeforeDelete,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'Accessibility',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<SettingsViewModel>(
                builder: (context, settings, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Text size',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<double>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment<double>(
                            value: 0.9,
                            label: Text('Small'),
                          ),
                          ButtonSegment<double>(
                            value: 1.0,
                            label: Text('Default'),
                          ),
                          ButtonSegment<double>(
                            value: 1.1,
                            label: Text('Large'),
                          ),
                        ],
                        selected: {settings.textScale},
                        onSelectionChanged: (next) {
                          if (next.isNotEmpty) {
                            settings.setTextScale(next.first);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Haptic feedback'),
                        subtitle: const Text(
                          'Light vibration when adding a habit from the Habits tab.',
                        ),
                        value: settings.useHaptics,
                        onChanged: settings.setUseHaptics,
                      ),
                    ],
                  );
                },
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 16),
                Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'Developer',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open dev build'),
                  subtitle: const Text(
                    'Switch to the dev branch build to test unreleased changes.',
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {
                    final devUri = Uri.base.resolve('dev/');
                    launchUrl(devUri, webOnlyWindowName: '_self');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
