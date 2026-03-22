import 'package:aadat/main.dart';
import 'package:aadat/ui/home/view_models/home_viewmodel.dart';
import 'package:aadat/ui/settings/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App loads with navigation', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeViewModel()),
          ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
  });
}
