import 'package:abfahrt_finder/data/bvg_api.dart';
import 'package:abfahrt_finder/provider/loading_provider.dart';
import 'package:abfahrt_finder/provider/loading_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

const Map<String, String> productImage = {
  "bus": "assets/product/bus.png",
  "suburban": "assets/product/sbahn.png",
  "subway": "assets/product/ubahn.png",
};

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

  const Connections({super.key, required this.stop, required this.product});

  @override
  State<Connections> createState() => _ConnectionsState();
}

class _ConnectionsState extends State<Connections> {
  List<Trip> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    try {
      final fetchedTrips = await fetchBVGArrivalData(int.parse(widget.stop.id), 20, 10);
      setState(() {
        trips = fetchedTrips
            .where((e) => e.line.product == widget.product)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error loading trips: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.stop.name)),
      body: Column(
        children: <Widget>[
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (trips.isEmpty)
            const Center(child: Text("No connections found"))
          else
            RefreshIndicator(
              onRefresh: () async {
                return Future<void>.delayed(const Duration(seconds: 3));
              },
              child: CustomScrollView(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
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
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back'),
            ),
          ),
        ],
      ),
    );
  }
}

class Detail extends StatelessWidget {
  final TransitStop stop;

  const Detail({super.key, required this.stop});

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
                      builder: (context) => Connections(stop: stop, product: prod),
                    ),
                  );
                },
              ),
            ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbfahrtenScreenState extends State<AbfahrtenScreen> {
  List<TransitStop> futureStops = [];

  Future<void> _fetchStops(BuildContext context, bool shouldShowLoading) async {
    final loadingProvider = context.read<LoadingProvider>();
    if (shouldShowLoading) {
      loadingProvider.setLoad(true);
    }

    try {
      final pos = await _determinePosition();
      final stops = await fetchBVGStopData(pos.latitude, pos.longitude, 300);

      setState(() {
        futureStops = stops;
      });
    } catch (error) {
      print("Error fetching stops: $error");
    } finally {
      if (context.mounted && shouldShowLoading) {
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
                          builder: (context) => Detail(stop: item),
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
