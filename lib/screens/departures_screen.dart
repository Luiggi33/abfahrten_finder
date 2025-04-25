import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/api_handler.dart';
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
  double currentSecondPercent = 0;
  bool hasRun = false;
  Timer? lerpTimer;

  @override
  void initState() {
    super.initState();
    loadTrips();
    setPercentToNextMinute();
    lerpTimer = Timer.periodic(Duration(milliseconds: 20), (_) {
      final now = DateTime.now();

      if (now.second == 0) {
        if (!hasRun) {
          loadTrips();
          hasRun = true;
        }
      } else {
        hasRun = false;
      }

      updateLerp();
    });
  }

  @override
  void dispose() {
    lerpTimer?.cancel();
    super.dispose();
  }

  void setPercentToNextMinute() {
    final now = DateTime.now();
    int seconds = now.second;
    int milliseconds = now.millisecond;
    double totalElapsedMs = (seconds.toDouble() * 1000) + milliseconds.toDouble();

    currentSecondPercent = totalElapsedMs / 60000;
  }

  void updateLerp() {
    setPercentToNextMinute();

    setState(() {
      currentSecondPercent = currentSecondPercent + (currentSecondPercent - currentSecondPercent) * 0.1;
    });
  }

  Future<void> loadTrips() async {
    try {
      final settings = Provider.of<AppSettings>(context, listen: false);
      final products = Products.fromString(widget.product);
      final fetchedTrips = await fetchProductArrivalData(settings.apiURL, settings.arrivalOffset, int.parse(widget.stop.id), 20, 30, products);

      if (listEquals(fetchedTrips, trips)) {
        return Future.value(null);
      }
      setState(() {
        trips = fetchedTrips;
      });
    } catch (e) {
      return Future.error(e);
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
                  SliverToBoxAdapter(
                    child: LinearProgressIndicator(value: currentSecondPercent),
                  ),
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