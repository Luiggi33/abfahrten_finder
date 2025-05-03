import 'package:abfahrt_finder/provider/favorites_provider.dart';
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
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.textContaining('Abfahrt Finder'), findsOneWidget);
  });

  testWidgets('Check for bottom bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(NavigationBar), findsOne);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Nearby Stops'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Search button should be visible', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
          ChangeNotifierProvider(create: (_) => FavoritesProvider()),
          ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byTooltip('Search Location'), findsOneWidget);
  });
}