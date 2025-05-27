import 'package:blecarv3/utility/utilitys.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final textController = TextEditingController();
  bool textValidate = false;

  @override
  void initState() {
    _getDeviceFromPref();
    super.initState();
  }

  void _getDeviceFromPref() async {
    String ip = await getDeviceIP();
    setState(() {
      textController.text = ip;
      textValidate = ip.isNotEmpty;
    });
  }

  void _saveIPAddress(BuildContext context) async {
    String ip = textController.text;
    if (ip.isNotEmpty) {
      await setDeviceIP(ip);
      if (!context.mounted) return;
      Navigator.pop(context, ip);
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    textController.text = value;
                    textValidate = value.isNotEmpty;
                  });
                },
                controller: textController,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'IP Address',
                    errorText: textValidate ? null : "Invalidate"),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _saveIPAddress(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
