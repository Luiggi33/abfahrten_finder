import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/bvg_api.dart';
import '../main.dart';
import '../provider/app_settings.dart';

class DeparturesScreen extends StatefulWidget {
  final TransitStop stop;
  final String product;
  final String apiURL;

  const DeparturesScreen({super.key, required this.stop, required this.product, required this.apiURL});

  @override
  State<DeparturesScreen> createState() => _DeparturesScreenState();
}

class _DeparturesScreenState extends State<DeparturesScreen> {
  List<Trip> trips = [];

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    try {
      final settings = Provider.of<AppSettings>(context, listen: false);
      final fetchedTrips = await fetchArrivalData(settings.apiURL, int.parse(widget.stop.id), 20, 30);
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
                          title: Text("${trip.line.name} nach ${trip.provenance}"),
                          subtitle: Text(
                              "Um ${DateFormat("HH:mm").format(trip.getPlannedDateTime()!.toLocal())} "
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