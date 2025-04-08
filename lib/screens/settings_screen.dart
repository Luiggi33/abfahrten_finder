import 'package:abfahrt_finder/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../provider/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({ super.key });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  late String apiURLKey;

  @override
  void initState() {
    super.initState();
    final settingData = Provider.of<AppSettings>(context, listen: false);
    apiURLKey = settingData.currentDataServer;
  }

  void _show(BuildContext ctx) {
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5,
      context: ctx,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.width * 0.5,
        width: MediaQuery.of(ctx).size.height * 0.5,
        child: Padding(
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 15,
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
                    final settings = Provider.of<AppSettings>(ctx, listen: false);
                    settings.setDataServer(dservID);
                    setState(() {
                      apiURLKey = dservID;
                    });
                    Navigator.pop(ctx);
                  }, child: Text(dservID)),
              ],
            ),
          )
        )
      )
    );
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
                onPressed: (BuildContext context) {
                  _show(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}