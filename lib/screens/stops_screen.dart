import 'package:abfahrt_finder/screens/settings_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../data/bvg_api.dart';
import '../main.dart';
import '../provider/app_settings.dart';
import '../provider/loading_provider.dart';
import 'departures_screen.dart';

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

class ProductsScreen extends StatelessWidget {
  final TransitStop stop;
  final String apiURL;

  const ProductsScreen({super.key, required this.stop, required this.apiURL});

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
                      builder: (context) => DeparturesScreen(apiURL: apiURL, stop: stop, product: prod),
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

class CloseStops extends StatefulWidget {
  const CloseStops({super.key});

  @override
  State<CloseStops> createState() => _CloseStopsState();
}

class _CloseStopsState extends State<CloseStops> {
  List<TransitStop> futureStops = [];

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<AppSettings>(context, listen: false);
    if (settings.loadOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchStops(context, true);
      });
    }
  }

  Future<void> _fetchStops(BuildContext context, bool showLoading) async {
    final loadingProvider = context.read<LoadingProvider>();
    if (loadingProvider.loading) {
      return;
    }

    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.mobile) && !connectivityResult.contains(ConnectivityResult.wifi) && !connectivityResult.contains(ConnectivityResult.ethernet)) {
      if (!context.mounted) {
        return Future.value(null);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No connection to the internet!', textAlign: TextAlign.center),
          duration: Duration(seconds: 5),
          width: 250,
          padding: EdgeInsets.symmetric(vertical: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      );
      return Future.value(null);
    }

    if (showLoading) {
      loadingProvider.setLoad(true);
    }

    try {
      final pos = await _determinePosition();
      if (!context.mounted) {
        loadingProvider.setLoad(false);
        return;
      }
      final settings = Provider.of<AppSettings>(context, listen: false);
      final stops = await fetchStopData(settings.apiURL, pos.latitude, pos.longitude, settings.searchRadius);
      setState(() {
        futureStops = stops;
      });
    } catch (error) {
      print("Error fetching stops: $error");
      loadingProvider.setLoad(false);
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
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
            ),
            child: Text(
              "Drücke den Knopf um Stops in der Nähe zu finden",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          )
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
                      final settings = Provider.of<AppSettings>(context, listen: false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductsScreen(apiURL: settings.apiURL, stop: item),
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
