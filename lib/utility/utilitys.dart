import 'package:blecarv3/config/config.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final log = Logger();

void snackBarMessage(BuildContext context, String message) {
  SnackBar snackBar = SnackBar(
    content: Text(message),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Future<String> getDeviceIP() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey("device_ip")) {
    prefs.setString("device_ip", defaultDeviceIP);
  }
  return Future<String>.value(prefs.getString("device_ip"));
}

Future<void> setDeviceIP(String ip) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString("device_ip", ip);
}

void sendCommand() {}

Future<bool> checkDevice() {
  return Future<bool>.value(true);
}
