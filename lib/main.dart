import 'package:abfahrt_finder/data/bvg_api.dart';
import 'package:abfahrt_finder/provider/app_settings.dart';
import 'package:abfahrt_finder/provider/loading_provider.dart';
import 'package:abfahrt_finder/provider/loading_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:abfahrt_finder/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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
};

const Map<String, String> dataServers = {
  "BVG": "https://v6.bvg.transport.rest",
  "VBB": "https://v6.vbb.transport.rest",
};

const String defaultDataServer = "VBB";

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.',
    );
  }

  return await Geolocator.getCurrentPosition();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting("de_DE");
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      builder: LoadingScreen.init(),
      home: AbfahrtenScreen(),
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

class AbfahrtenScreen extends StatefulWidget {
  const AbfahrtenScreen({super.key});

  @override
  State<AbfahrtenScreen> createState() => _AbfahrtenScreenState();
}

class StatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const StatefulWrapper({super.key, required this.onInit, required this.child});

  @override
  _StatefulWrapperState createState() => _StatefulWrapperState();
}

class _StatefulWrapperState extends State<StatefulWrapper> {
  @override
  void initState() {
    widget.onInit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class Connections extends StatefulWidget {
  final TransitStop stop;
  final String product;
  final String apiURL;

  const Connections({super.key, required this.stop, required this.product, required this.apiURL});

  @override
  State<Connections> createState() => _ConnectionsState();
}

class _ConnectionsState extends State<Connections> {
  List<Trip> trips = [];

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    try {
      final fetchedTrips = await fetchBVGArrivalData(context, int.parse(widget.stop.id), 20);
      setState(() {
        trips = fetchedTrips
            .where((e) => e.line.product == widget.product)
            .toList();
      });
    } catch (e) {
      print("Error loading trips: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stop.name),
      ),
      body: trips.isEmpty
        ? Center(child: Text("No connections found"))
        : RefreshIndicator(
          onRefresh: () async {
            return loadTrips();
          },
          child: CustomScrollView(
            slivers: <Widget>[
              SliverList.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return Card(
                    child: ListTile(
                      leading: Image.asset(
                          productImage[widget.product] != null
                              ? productImage[widget.product]!
                              : "assets/product/placeholder.png"
                      ),
                      title: Text(widget.stop.products.toMap()[widget.product]!),
                      subtitle: Text(
                          "Nach ${trip.provenance} um ${DateFormat("HH:mm").format(trip.getPlannedDateTime()!.toLocal())} "
                              "${trip.delay != null && trip.delay != 0 ? "(${trip.delay!.isNegative ? '' : '+'}${trimZero(trip.delay! / 60)}) " : ""}"
                              "Uhr"
                      ),
                    ),
                  );
                },
              ),
            ]
          )
        )
    );
  }
}

class Detail extends StatelessWidget {
  final TransitStop stop;
  final String apiURL;

  const Detail({super.key, required this.stop, required this.apiURL});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(stop.name)),
      body: Column(
        children: <Widget>[
          for (final prod in stop.products.toMap().keys)
            Card(
              child: ListTile(
                leading: Image.asset(productImage[prod] != null ? productImage[prod]! : "assets/product/placeholder.png" ),
                title: Text(stop.products.toMap()[prod]!),
                subtitle: Text("Siehe ${stop.products.toMap()[prod]} Verbindungen"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Connections(apiURL: apiURL, stop: stop, product: prod),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AbfahrtenScreenState extends State<AbfahrtenScreen> {
  List<TransitStop> futureStops = [];
  late String apiURL;
  late String dataServer;

  @override
  void initState() {
    super.initState();
    dataServer = defaultDataServer;
    apiURL = dataServers[dataServer]!;
  }

  Future<void> _fetchStops(BuildContext context, bool showLoading) async {
    final loadingProvider = context.read<LoadingProvider>();
    if (showLoading) {
      loadingProvider.setLoad(true);
    }

    try {
      final pos = await _determinePosition();
      final stops = await fetchBVGStopData(context, pos.latitude, pos.longitude);
      setState(() {
        futureStops = stops;
      });
    } catch (error) {
      print("Error fetching stops: $error");
    } finally {
      if (context.mounted && showLoading) {
        loadingProvider.setLoad(false);
      }
    }
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Abfahrt Finder Demo"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Open settings',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingsScreen()));
            },
          ),
        ],
      ),
      body: futureStops.isEmpty
        ? Center(
          child: Text(
            "Drücke den Knopf um Stops in der Nähe zu finden",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        )
        : RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: () => _fetchStops(context, false),
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverList.builder(
                itemCount: futureStops.length,
                itemBuilder: (context, index) {
                  final item = futureStops[index];
                  final stationItem = StationItem(
                    item.name,
                    "${item.distance.toString()}m",
                  );
                  return ListTile(
                    title: stationItem.buildTitle(context),
                    subtitle: stationItem.buildSubtitle(context),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Detail(apiURL: apiURL, stop: item),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (futureStops.isNotEmpty) {
            _refreshIndicatorKey.currentState?.show();
          } else {
            _fetchStops(context, true);
          }
        },
        tooltip: 'Search Location',
        child: const Icon(Icons.search),
      ),
    );
  }
}
