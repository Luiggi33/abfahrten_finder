import 'package:abfahrt_finder/provider/app_settings.dart';
import 'package:abfahrt_finder/provider/loading_provider.dart';
import 'package:abfahrt_finder/provider/loading_widget.dart';
import 'package:abfahrt_finder/screens/stops_screen.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = AppSettings();
  await settings.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

const Map<String, String> productImage = {
  "bus": "assets/product/bus.png",
  "suburban": "assets/product/sbahn.png",
  "subway": "assets/product/ubahn.png",
  "tram": "assets/product/tram.png",
  "ferry": "assets/product/ferry.png",
};

const Map<String, String> dataServers = {
  "BVG": "https://v6.bvg.transport.rest",
  "VBB": "https://v6.vbb.transport.rest",
};

const String defaultDataServer = "VBB";
const int minDistance = 100;
const int maxDistance = 500;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    initializeDateFormatting("de_DE");
    return MaterialApp(
      title: 'Flutter Demo',
      theme: settings.theme,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      builder: LoadingScreen.init(),
      home: CloseStops(),
    );
  }
}

abstract class ListItem {
  Widget buildTitle(BuildContext context);

  Widget buildSubtitle(BuildContext context);
}

class StationItem implements ListItem {
  final String name;
  final String distance;

  StationItem(this.name, this.distance);

  @override
  Widget buildTitle(BuildContext context) => Text(name);

  @override
  Widget buildSubtitle(BuildContext context) => Text("Distanz: $distance");
}
