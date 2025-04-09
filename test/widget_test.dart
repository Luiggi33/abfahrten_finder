import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abfahrt_finder/main.dart';
import 'package:abfahrt_finder/provider/app_settings.dart';
import 'package:abfahrt_finder/provider/loading_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App should render title in the AppBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.textContaining('Abfahrt Finder'), findsOneWidget);
  });

  testWidgets('Initial state shows instruction message', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Drücke den Knopf um Stops in der Nähe zu finden'), findsOneWidget);
  });

  testWidgets('Search button should be visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byTooltip('Search Location'), findsOneWidget);
  });

  testWidgets('Settings button should be visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byTooltip('Open settings'), findsOneWidget);
  });
}