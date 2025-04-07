import 'package:abfahrt_finder/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../provider/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  late String apiURLKey;

  SettingsScreen({super.key, required this.apiURLKey });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState  extends State<SettingsScreen> {

  void _show(BuildContext ctx) {
    showModalBottomSheet(
      isScrollControlled: true,
      elevation: 5,
      context: ctx,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final dservID in dataServers.keys)
              ElevatedButton(onPressed: () {
                final settings = Provider.of<AppSettings>(ctx, listen: false);
                settings.setDataServer(dataServers[dservID]!);
                setState(() {
                  widget.apiURLKey = dservID;
                });
                Navigator.pop(ctx);
              }, child: Text(dservID))
          ],
        ),
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
                description: Text(widget.apiURLKey),
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