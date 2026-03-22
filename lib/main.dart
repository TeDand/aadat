import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/home/widgets/home_page.dart';
import 'package:flutter/material.dart';
import 'package:aadat/ui/home/widgets/calendar_page.dart';
import 'package:aadat/ui/home/widgets/habits_page.dart';
import 'package:aadat/ui/home/widgets/metrics_page.dart';
import 'package:aadat/ui/settings/settings_dialog.dart';
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

const _seed = Color(0xFF2563EB);

ThemeData _appThemeFromScheme(ColorScheme colorScheme) {
  final baseText = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  ).textTheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(baseText),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      elevation: 1,
      indicatorColor: colorScheme.primaryContainer,
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final lightScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

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
      default:
        page = HomePage();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NavigationRail(
                        extended: constraints.maxWidth >= 600,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.home),
                            label: Text('Home'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.checklist),
                            label: Text('Habits'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.calendar_month),
                            label: Text('Calendar'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.insights_rounded),
                            label: Text('Metrics'),
                          ),
                        ],
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (value) {
                          setState(() {
                            selectedIndex = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => showAppSettingsDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
