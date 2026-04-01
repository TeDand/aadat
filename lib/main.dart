import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/home/widgets/home_page.dart';
import 'package:aadat/ui/whats_new_dialog.dart';
import 'package:flutter/material.dart';
import 'package:aadat/ui/home/widgets/calendar_page.dart';
import 'package:aadat/ui/home/widgets/habits_page.dart';
import 'package:aadat/ui/home/widgets/metrics_page.dart';
import 'package:aadat/ui/home/widgets/resources_page.dart';
import 'package:aadat/ui/settings/settings_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: const MainApp(),
    ),
  );
}

ColorScheme _minimalScheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF222222),
    brightness: brightness,
  );
  return base.copyWith(
    primary: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF111111),
    onPrimary: isDark ? const Color(0xFF111111) : Colors.white,
    primaryContainer: isDark ? const Color(0xFF262626) : const Color(0xFFEEEEEE),
    onPrimaryContainer: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF111111),
    secondary: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF555555),
    onSecondary: isDark ? const Color(0xFF111111) : Colors.white,
    secondaryContainer: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2),
    onSecondaryContainer: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF111111),
    surface: isDark ? const Color(0xFF0D0D0D) : Colors.white,
    surfaceContainerLowest: isDark ? const Color(0xFF0D0D0D) : Colors.white,
    surfaceContainerLow: isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9),
    surfaceContainer: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4),
    surfaceContainerHigh: isDark ? const Color(0xFF222222) : const Color(0xFFEEEEEE),
    surfaceContainerHighest: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
    onSurface: isDark ? const Color(0xFFEEEEEE) : const Color(0xFF111111),
    onSurfaceVariant: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
    outline: isDark ? const Color(0xFF555555) : const Color(0xFF888888),
    outlineVariant: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDDDDDD),
    error: isDark ? const Color(0xFFCF6679) : const Color(0xFFC62828),
    onError: isDark ? const Color(0xFF111111) : Colors.white,
  );
}

ThemeData _appThemeFromScheme(ColorScheme colorScheme) {
  final baseText = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  ).textTheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: GoogleFonts.jetBrainsMonoTextTheme(baseText),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final lightScheme = _minimalScheme(Brightness.light);
    final darkScheme = _minimalScheme(Brightness.dark);

    return MaterialApp(
      title: 'aadat',
      theme: _appThemeFromScheme(lightScheme),
      darkTheme: _appThemeFromScheme(darkScheme),
      themeMode: settings.themeMode,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(settings.textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Router(),
    );
  }
}

class Router extends StatefulWidget {
  const Router({super.key});

  @override
  State<Router> createState() => _RouterState();
}

class _RouterState extends State<Router> {
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkAndShowWhatsNew(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePage();
      case 1:
        page = HabitsPage();
      case 2:
        page = CalendarPage();
      case 3:
        page = MetricsPage();
      case 4:
        page = ResourcesPage();
      default:
        page = HomePage();
    }

    return Scaffold(
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Metrics',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_outlined),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Resources',
          ),
        ],
      ),
    );
  }
}
