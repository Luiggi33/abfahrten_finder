import 'dart:convert';

import 'package:abfahrt_finder/provider/loading_provider.dart';
import 'package:abfahrt_finder/provider/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

const Map<String, String> productImage = {
  "Bus": "assets/product/bus.png",
  "S-Bahn": "assets/product/sbahn.png",
  "U-Bahn": "assets/product/ubahn.png",
};

Future<List<TransitStop>> fetchBVGData(double latitude, double longitude, int maxDistance) async {
  final response = await http.get(
    Uri.parse(
      "https://v6.bvg.transport.rest/locations/nearby?latitude=$latitude&longitude=$longitude&linesOfStops=true",
    ),
  );

  if (response.statusCode == 200) {
    List<dynamic> parsedListJson = jsonDecode(response.body);
    List<TransitStop> stops = parsedListJson.map((json) => TransitStop.fromJson(json)).where((e) => e.distance < maxDistance).toList();
    return stops;
  } else {
    throw Exception("Failed to load BVG data");
  }
}

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

class TransitStop {
  final String type;
  final String id;
  final String name;
  final Location location;
  final Products products;
  final List<Line> lines;
  final int distance;

  TransitStop({
    required this.type,
    required this.id,
    required this.name,
    required this.location,
    required this.products,
    required this.lines,
    required this.distance,
  });

  factory TransitStop.fromJson(Map<String, dynamic> json) {
    // Handle case where lines might be null
    var linesJson = json['lines'];
    List<Line> linesList = [];

    if (linesJson != null) {
      linesList =
          (linesJson as List)
              .map((lineJson) => Line.fromJson(lineJson))
              .toList();
    }

    return TransitStop(
      type: json['type'],
      id: json['id'],
      name: json['name'],
      location: Location.fromJson(json['location']),
      products: Products.fromJson(json['products']),
      lines: linesList,
      distance: json['distance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'name': name,
      'location': location.toJson(),
      'products': products.toJson(),
      'lines': lines.map((line) => line.toJson()).toList(),
      'distance': distance,
    };
  }
}

class Location {
  final String type;
  final String id;
  final double latitude;
  final double longitude;

  Location({
    required this.type,
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'],
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Products {
  final bool suburban;
  final bool subway;
  final bool tram;
  final bool bus;
  final bool ferry;
  final bool express;
  final bool regional;

  Products({
    required this.suburban,
    required this.subway,
    required this.tram,
    required this.bus,
    required this.ferry,
    required this.express,
    required this.regional,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      suburban: json['suburban'],
      subway: json['subway'],
      tram: json['tram'],
      bus: json['bus'],
      ferry: json['ferry'],
      express: json['express'],
      regional: json['regional'],
    );
  }

  Map<String, String> toMap() {
    Map<String, String> map = {};
    if (suburban) {
      map["suburban"] = "S-Bahn";
    }
    if (subway) {
      map["subway"] = "U-Bahn";
    }
    if (tram) {
      map["tram"] = "Tram";
    }
    if (bus) {
      map["bus"] = "Bus";
    }
    if (ferry) {
      map["ferry"] = "Fähre";
    }
    if (express) {
      map["express"] = "Express";
    }
    if (regional) {
      map["regional"] = "Regional";
    }
    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'suburban': suburban,
      'subway': subway,
      'tram': tram,
      'bus': bus,
      'ferry': ferry,
      'express': express,
      'regional': regional,
    };
  }

  @override
  String toString() {
    return "S-Bahn: ${suburban ? "Ja" : "Nein"}\nU-Bahn: ${subway ? "Ja" : "Nein"}\nTram: ${tram ? "Ja" : "Nein"}\nBus: ${bus ? "Ja" : "Nein"}\nFähre ${ferry ? "Ja" : "Nein"}";
  }
}

class Line {
  final String type;
  final String id;
  final String? fahrtNr;
  final String name;
  final bool public;
  final String productName;
  final String mode;
  final String product;

  Line({
    required this.type,
    required this.id,
    this.fahrtNr,
    required this.name,
    required this.public,
    required this.productName,
    required this.mode,
    required this.product,
  });

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      type: json['type'],
      id: json['id'],
      fahrtNr: json['fahrtNr'],
      name: json['name'],
      public: json['public'],
      productName: json['productName'],
      mode: json['mode'],
      product: json['product'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'fahrtNr': fahrtNr,
      'name': name,
      'public': public,
      'productName': productName,
      'mode': mode,
      'product': product,
    };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

class Connections extends StatelessWidget {
  final TransitStop stop;
  final String product;

  const Connections({super.key, required this.stop, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(stop.name)),
      body: Column(
        children: <Widget>[
          for (final prod in stop.lines.where((e) => e.product == product))
            Card(
              child: Text(prod.name),
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
                leading: Image.asset(productImage[stop.products.toMap()[prod]] != null ? productImage[stop.products.toMap()[prod]]! : "assets/product/placeholder.png" ),
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

  void _fetchStops(BuildContext context) {
    final loadingProvider = context.read<LoadingProvider>();
    loadingProvider.setLoad(true);

    _determinePosition().then((pos) {
      return fetchBVGData(pos.latitude, pos.longitude, 300);
    }).then((stops) {
      setState(() {
        futureStops = stops;
      });
    }).catchError((error) {
      print("Error fetching stops: $error");
    }).whenComplete(() {
      if (context.mounted) {
        loadingProvider.setLoad(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text("Abfahrt Finder Demo"),
      ),
      body: Column(
        children: <Widget>[
          if (futureStops.isEmpty)
            Expanded(
              child: Text("Drücke den Knopf um Stops in der Nähe zu finden", style: TextStyle(fontSize: 20)),
            )
          else
            Expanded(
              child: ListView.builder(
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
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchStops(context);
        },
        tooltip: 'Search Location',
        child: const Icon(Icons.search),
      ),
    );
  }
}
