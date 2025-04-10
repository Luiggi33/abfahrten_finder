import 'package:abfahrt_finder/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../provider/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({ super.key });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  late String apiURLKey;
  late int searchRadius;
  late bool loadOnStart;

  @override
  void initState() {
    super.initState();
    final settingData = Provider.of<AppSettings>(context, listen: false);
    apiURLKey = settingData.currentDataServer;
    searchRadius = settingData.searchRadius;
    loadOnStart = settingData.loadOnStart;
  }

  void _showAPIServerSettings(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5,
      context: context,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.width * 0.5,
          width: MediaQuery.of(context).size.height * 0.5,
          child: Padding(
            padding: EdgeInsets.only(
              top: 15,
              left: 15,
              right: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom + 15,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 10,
                children: [
                  Text("Please select API server"),
                  for (final dservID in dataServers.keys)
                    ElevatedButton(onPressed: () {
                      final settings = Provider.of<AppSettings>(context, listen: false);
                      settings.setDataServer(dservID);
                      setState(() {
                        apiURLKey = dservID;
                      });
                      Navigator.pop(context);
                    }, child: Text(dservID)),
                ],
              ),
            )
          )
        )
      )
    );
  }

  void _showSearchRadiusSettings(BuildContext context) {
    final settings = Provider.of<AppSettings>(context, listen: false);
    int localSearchRadius = settings.searchRadius;
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.width * 0.5,
            width: MediaQuery.of(context).size.height * 0.5,
            child: Padding(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                bottom: MediaQuery.of(context).viewInsets.bottom + 15,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Select Search Radius", style: TextStyle(fontSize: 20),),
                    SizedBox(height: 15),
                    Text("Current Radius: $localSearchRadius"),
                    SizedBox(height: 25),
                    Slider(
                      value: localSearchRadius.toDouble(),
                      min: minDistance.toDouble(),
                      max: maxDistance.toDouble(),
                      divisions: 40,
                      label: localSearchRadius.toString(),
                      onChanged: (double value) {
                        setModalState(() {
                          localSearchRadius = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
              )
            )
          )
        )
      )
    ).then((_) {
      settings.setSearchRadius(localSearchRadius);
      setState(() {
        searchRadius = localSearchRadius.toInt();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Common'),
            tiles: [
              SettingsTile.navigation(
                title: Text('API Server'),
                description: Text(apiURLKey),
                leading: Icon(Icons.language),
                onPressed: (context) => _showAPIServerSettings(context),
              ),
              SettingsTile.navigation(
                title: Text('Search Radius'),
                description: Text(searchRadius.toString()),
                leading: Icon(Icons.radar),
                onPressed: (context) => _showSearchRadiusSettings(context),
              ),
              SettingsTile.switchTile(
                title: Text('Load Stops on App Start'),
                initialValue: loadOnStart,
                leading: Icon(Icons.search),
                onToggle: (value) {
                  final settingData = Provider.of<AppSettings>(context, listen: false);
                  settingData.setLoadOnStart(value);
                  setState(() {
                    loadOnStart = value;
                  });
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}