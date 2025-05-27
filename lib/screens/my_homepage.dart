import 'dart:async';
import 'dart:io';

import 'package:blecarv3/constants.dart';
import 'package:blecarv3/screens/controller.dart';
import 'package:blecarv3/utility/utilitys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:blecarv3/utility/extra.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  List<BluetoothDevice> _connectedDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  late BluetoothDevice targetDevice;

  Future<void> _navigateToController() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              ControllerScreen(title: widget.title, device: targetDevice)),
    );
    if (!mounted) return;
    log.i(result);
    onScanning();
    // if (result != null && result == true) {
    //   onScanning();
    // }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    bleInit();
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isScanning && targetDevice == null) {
          onScanning();
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        onStopScanning();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void bleInit() {
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      setState(() {});
    });

    FlutterBluePlus.systemDevices.then((devices) {
      _connectedDevices = devices;
      log.i(_connectedDevices.toString());
      setState(() {});
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      findTargetDevice();
    }, onError: (e) {});

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      setState(() {});
    });

    onScanning();
  }

  Future onScanning() async {
    try {
      // android is slow when asking for all advertisments,
      // so instead we only ask for 1/8 of them
      int divisor = Platform.isAndroid ? 8 : 1;
      await FlutterBluePlus.startScan(
          timeout: null, continuousUpdates: true, continuousDivisor: divisor);
    } catch (e) {}
    setState(() {}); // force refresh of systemDevices
  }

  Future onStopScanning() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {}
  }

  void findTargetDevice() async {
    final index = _scanResults
        .indexWhere((item) => item.device.remoteId.str == DEVICE_MAC_ID);
    if (index >= 0) {
      targetDevice = _scanResults[index].device;

      onStopScanning();

      await targetDevice?.connectAndUpdateStream().catchError((e) async {
        await targetDevice?.disconnectAndUpdateStream();
        onScanning();
      });

      if (targetDevice!.isConnected) {
        await Future.delayed(const Duration(seconds: 1));

        if (!context.mounted) return;
        _navigateToController();

        // var result = await Navigator.pushNamed(
        //   'controller',
        //   extra: targetDevice,
        // );

        // if (result != null && result == true) {
        //   onScanning();
        // }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _adapterState == BluetoothAdapterState.on
          ? Center(
              child: Lottie.asset('assets/lottiefiles/1701372850288.json'),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Turn on Bluetooth",
                    textAlign: TextAlign.center,
                  ),
                  Lottie.asset('assets/lottiefiles/1701382328732.json')
                ],
              ),
            ),
    );
  }
}
