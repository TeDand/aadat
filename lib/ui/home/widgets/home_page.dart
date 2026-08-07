import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/settings/settings_dialog.dart';
import 'package:aadat/data/repositories/habit_model.dart';
import 'metrics_page.dart';
import 'templates_page.dart';
import 'resources_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _salutation() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _displayName() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['display_name'] as String? ?? '';
  }

  String _dateLabel() {
    final now = DateTime.now();
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final today = habitDateOnly(DateTime.now());
    final summary = viewModel.completionSummaryForDay(today);
    final name = _displayName();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      endDrawer: const _AppMenuDrawer(),
      appBar: AppBar(
        title: _AadatWordmark(foreground: scheme.onPrimary),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showAppSettingsDialog(context),
          ),
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        children: [
          Text(
            '${_salutation()}${name.isNotEmpty ? ', $name' : ''}',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _dateLabel(),
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          _TappableCard(
            onTap: () {
              final vm = context.read<HomeViewModel>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: vm,
                    child: const MetricsPage(),
                  ),
                ),
              );
            },
            scheme: scheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Today's habits",
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${summary.completed}',
                        style: textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${summary.total}',
                        style: textTheme.headlineMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (summary.total > 0) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: summary.completed / summary.total,
                    backgroundColor: scheme.outlineVariant,
                    color: scheme.primary,
                    minHeight: 2,
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Tap to see your stats',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _TappableCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplatesPage()),
            ),
            scheme: scheme,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not sure where to start?',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse habit templates and resources',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TappableCard extends StatelessWidget {
  const _TappableCard({
    required this.onTap,
    required this.scheme,
    required this.child,
  });

  final VoidCallback onTap;
  final ColorScheme scheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: child,
      ),
    );
  }
}

class _AppMenuDrawer extends StatelessWidget {
  const _AppMenuDrawer();

  void _go(BuildContext context, Widget page, {HomeViewModel? vm}) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => vm != null
            ? ChangeNotifierProvider.value(value: vm, child: page)
            : page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'menu',
                style: textTheme.bodySmall?.copyWith(
                  letterSpacing: 3,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Divider(color: scheme.outlineVariant),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Stats'),
              onTap: () {
                final vm = context.read<HomeViewModel>();
                _go(context, const MetricsPage(), vm: vm);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Templates'),
              onTap: () => _go(context, const TemplatesPage()),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Resources'),
              onTap: () => _go(context, const ResourcesPage()),
            ),
            const Spacer(),
            Divider(color: scheme.outlineVariant),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.onSurfaceVariant),
              title: Text(
                'Sign out',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              onTap: () => Supabase.instance.client.auth.signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AadatWordmark extends StatelessWidget {
  const _AadatWordmark({required this.foreground});

  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '>_',
          style: textTheme.bodySmall?.copyWith(
            color: foreground.withValues(alpha: 0.45),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'aadat',
          style: textTheme.titleMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
