import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../data/api_handler.dart';
import '../main.dart';
import '../provider/settings_provider.dart';
import '../provider/favorites_provider.dart';
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

abstract class ListItem {
  Widget buildTitle(BuildContext context);

  Widget buildSubtitle(BuildContext context);
}

class StationItem implements ListItem {
  final String name;
  final num distance;

  StationItem(this.name, this.distance);

  @override
  Widget buildTitle(BuildContext context) => Text(name);

  @override
  Widget buildSubtitle(BuildContext context) => Text("Distanz: ${distance}m");
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

class LazyProductsScreen extends StatelessWidget {
  final String stopName;
  final String stopId;
  final String apiURL;

  const LazyProductsScreen({super.key, required this.stopName, required this.stopId, required this.apiURL});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(stopName)),
      body: FutureBuilder<TransitStop>(
        future: fetchStopData(apiURL, stopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading station data...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error loading data: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          }

          final stop = snapshot.data!;
          return Column(
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
          );
        },
      ),
    );
  }
}

class StopCacheState {
  static final StopCacheState _instance = StopCacheState._internal();
  factory StopCacheState() => _instance;
  StopCacheState._internal();

  bool initialLoad = false;
  List<TransitStop> cachedStops = [];
  Position? lastPosition;
  double? lastHeading;
}

class CloseStops extends StatefulWidget {
  const CloseStops({super.key});

  @override
  State<CloseStops> createState() => _CloseStopsState();
}

class _CloseStopsState extends State<CloseStops> {
  List<TransitStop> futureStops = [];
  late Position currentPos;
  late double userHeading;
  late StreamSubscription<CompassEvent> compassEvent;
  late StreamSubscription<Position> positionEvent;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<AppSettings>(context, listen: false);
    if (StopCacheState().cachedStops.isNotEmpty && StopCacheState().lastPosition != null && StopCacheState().lastHeading != null) {
      setState(() {
        futureStops = StopCacheState().cachedStops;
        currentPos = StopCacheState().lastPosition!;
        userHeading = StopCacheState().lastHeading!;
      });
    }
    if (settings.loadOnStart && !StopCacheState().initialLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StopCacheState().initialLoad = true;
        _fetchStops(context, true).catchError((e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e', textAlign: TextAlign.center),
              duration: Duration(seconds: 3),
              width: 250,
              padding: EdgeInsets.symmetric(vertical: 6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            ),
          );
        });
      });
    }
    positionEvent = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      )
    ).listen((Position position) {
      setState(() {
        currentPos = position;
        StopCacheState().lastPosition = currentPos;
      });
    });
    compassEvent = FlutterCompass.events!.listen((CompassEvent event) {
      setState(() {
        userHeading = event.heading! < 0 ? (360 + event.heading!) : event.heading!;
        StopCacheState().lastHeading = userHeading;
      });
    });
  }

  @override
  void dispose() {
    compassEvent.cancel();
    positionEvent.cancel();
    super.dispose();
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
      return Future.error("No connection to the internet");
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
      final stops = await fetchStopsByLocation(settings.apiURL, pos.latitude, pos.longitude, settings.searchRadius);
      setState(() {
        futureStops = stops;
        currentPos = pos;

        StopCacheState().cachedStops = stops;
        StopCacheState().lastPosition = pos;
      });
    } catch (error) {
      loadingProvider.setLoad(false);
      return Future.error(error);
    } finally {
      if (context.mounted && showLoading) {
        loadingProvider.setLoad(false);
      }
    }
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: true);
    return Scaffold(
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
          onRefresh: () async {
            try {
              return await _fetchStops(context, true);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$e', textAlign: TextAlign.center),
                  duration: Duration(seconds: 3),
                  width: 250,
                  padding: EdgeInsets.symmetric(vertical: 6),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              );
              return Future<void>.value();
            }
          },
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverList.builder(
                itemCount: futureStops.length,
                itemBuilder: (context, index) {
                  final item = futureStops[index];
                  final isFavorite = favoritesProvider.isFavorite(item.id);
                  final distanceBetween = Geolocator.distanceBetween(currentPos.latitude, currentPos.longitude, item.location.latitude, item.location.longitude);
                  final bearingBetween = Geolocator.bearingBetween(currentPos.latitude, currentPos.longitude, item.location.latitude, item.location.longitude);
                  double rotationAngle = bearingBetween - (userHeading ?? 0);
                  if (rotationAngle > 180) rotationAngle -= 360;
                  if (rotationAngle < -180) rotationAngle += 360;
                  final stationItem = StationItem(
                    item.name,
                    distanceBetween.ceil(),
                  );
                  return ListTile(
                    leading: Transform.rotate(
                      angle: rotationAngle * (pi / 180),
                      child: Icon(Icons.arrow_upward, color: Colors.blue, size: 24),
                    ),
                    trailing: IconButton(
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                      onPressed: () {
                        if (isFavorite) {
                          favoritesProvider.removeFavorite(item.id);
                        } else {
                          favoritesProvider.addFavorite(item.id, item.name);
                        }
                      },
                    ),
                    title: stationItem.buildTitle(context),
                    subtitle: stationItem.buildSubtitle(context),
                    onTap: () {
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
            _fetchStops(context, true).catchError((e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$e', textAlign: TextAlign.center),
                  duration: Duration(seconds: 3),
                  width: 250,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              );
            });
          }
        },
        tooltip: 'Search Location',
        child: const Icon(Icons.search),
      ),
    );
  }
}
