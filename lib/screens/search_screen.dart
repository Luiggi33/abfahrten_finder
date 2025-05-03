import 'package:abfahrt_finder/provider/favorites_provider.dart';
import 'package:abfahrt_finder/screens/stops_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/settings_provider.dart';

class FavoriteStationItem implements ListItem {
  final String name;

  FavoriteStationItem(this.name);

  @override
  Widget buildTitle(BuildContext context) => Text(name);

  @override
  Widget buildSubtitle(BuildContext context) => Text("Click to view station");
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Station> favoriteStops = [];

  @override
  void initState() {
    super.initState();
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    favoriteStops = favoritesProvider.favoriteStations;
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: true);
    return Scaffold(
      body:
      favoriteStops.isEmpty
        ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
            ),
            child: Text(
              "You didn't mark any stops as your favorite yet",
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          )
      )
      : Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: favoriteStops.length,
              itemBuilder: (context, index) {
                final station = favoriteStops[index];
                final stationItem = FavoriteStationItem(station.name);
                return ListTile(
                  title: stationItem.buildTitle(context),
                  subtitle: stationItem.buildSubtitle(context),
                  trailing: IconButton(
                    icon: Icon(Icons.favorite),
                    onPressed: () => favoritesProvider.removeFavorite(station.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return LazyProductsScreen(apiURL: settings.apiURL, stopName: station.name, stopId: station.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      )
    );
  }
}
