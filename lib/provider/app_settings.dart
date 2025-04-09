import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class AppSettings extends ChangeNotifier {
  // Data Server URLs for the API requests
  String _currentDataServer = defaultDataServer;
  String get currentDataServer => _currentDataServer;
  String get apiURL => dataServers[_currentDataServer]!;

  void setDataServer(String server) {
    if (dataServers.containsKey(server) && _currentDataServer != server) {
      _currentDataServer = server;
      notifyListeners();
      _saveSettings();
    }
  }

  // Default distance for search (in meters)
  int _searchRadius = 300;
  int get searchRadius => _searchRadius;

  void setSearchRadius(int value) {
    if (_searchRadius != value) {
      _searchRadius = value;
      notifyListeners();
      _saveSettings();
    }
  }

  // Should the stops be loaded on start
  bool _loadOnStart = true;
  bool get loadOnStart => _loadOnStart;

  void setLoadOnStart(bool value) {
    if (_loadOnStart != value) {
      _loadOnStart = value;
      notifyListeners();
      _saveSettings();
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentDataServer = prefs.getString('dataServer') ?? defaultDataServer;
    _searchRadius = prefs.getInt('searchRadius') ?? 300;
    _loadOnStart = prefs.getBool('loadOnStart') ?? true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dataServer', _currentDataServer);
    await prefs.setInt('searchRadius', _searchRadius);
    await prefs.setBool('loadOnStart', _loadOnStart);
  }
}