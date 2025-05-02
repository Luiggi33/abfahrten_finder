import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../main.dart';

class Station {
  final String id;
  final String name;

  Station({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Station.fromMap(Map<String, dynamic> map) {
    return Station(
      id: map['id'],
      name: map['name'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Station.fromJson(String source) => Station.fromMap(json.decode(source));
}

class FavoritesProvider extends ChangeNotifier {
  List<Station> _favoriteStations = [];
  List<Station> get favoriteStations => _favoriteStations;

  bool isFavorite(String stationId) {
    return _favoriteStations.any((station) => station.id == stationId);
  }

  String? getStationName(String stationId) {
    final station = _favoriteStations.firstWhere(
          (station) => station.id == stationId,
      orElse: () => Station(id: '', name: ''),
    );
    return station.id.isNotEmpty ? station.name : null;
  }

  void addFavorite(String stationId, String stationName) {
    final newStation = Station(id: stationId, name: stationName);

    if (!_favoriteStations.any((station) => station.id == stationId) && _favoriteStations.length < maxFavorites) {
      _favoriteStations.add(newStation);
      notifyListeners();
      _saveFavorites();
    }
  }

  void removeFavorite(String stationId) {
    _favoriteStations.removeWhere((station) => station.id == stationId);
    notifyListeners();
    _saveFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stationsJson = prefs.getStringList("favoriteStations") ?? [];

    if (stationsJson.isNotEmpty) {
      _favoriteStations = stationsJson
        .map((stationJson) => Station.fromJson(stationJson))
        .toList();
    } else {
      _favoriteStations = [];
    }

    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> stationsJson = _favoriteStations
      .map((station) => station.toJson())
      .toList();

    await prefs.setStringList('favoriteStations', stationsJson);
  }
}