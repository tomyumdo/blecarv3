import 'dart:async';

import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:blecarv3/constants.dart';
import 'package:blecarv3/utility/extra.dart';
import 'package:blecarv3/utility/utilitys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:vibration/vibration.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({
    super.key,
    required this.title,
    required this.device,
  });
  final String title;
  final BluetoothDevice device;

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  bool ledstatus = false;
  bool connected = false;

  double _sliderValue1 = 0;
  double _sliderValue2 = 0;

  bool isLightPressed = false;
  bool isDownPressed = false;
  bool isUpPressed = false;
  bool isLeftPressed = false;
  bool isRightPressed = false;

  void onSlider1ChangeEnd(value) {
    writeBLE(CH2, _sliderValue1.round());
  }

  void onSlider2ChangeEnd(value) {
    writeBLE(CH3, _sliderValue2.round());
  }

  int? _rssi;

  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;

  List<int> _value = [];
  late StreamSubscription<List<int>> _lastValueSubscription;

  BluetoothCharacteristic? _characteristicTX;

  final speedNotifier = ValueNotifier<double>(10);

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  void writeBLE(int channel, int data) async {
    if (!isConnected) {
      backToHome(true);
      return;
    }

    await _characteristicTX?.write([channel, data], timeout: 1);
  }

  void backToHome(bool needToReConnect) {
    onDisconnect();
    Navigator.pop(context, needToReConnect);
  }

  Future onDisconnect() async {
    try {
      await widget.device.disconnectAndUpdateStream();
    } catch (e) {
      log.w("Disconnect Error:${e.toString()}");
    }
  }

  Future onDiscoverServices() async {
    _isDiscoveringServices = true;
    try {
      _services = await widget.device.discoverServices();
      final targetServiceUUID = _services.singleWhere(
        (item) => item.serviceUuid.str == SERVICE_UUID,
      );

      final targetCharacterUUID = targetServiceUUID.characteristics.singleWhere(
        (item) => item.characteristicUuid.str == CHARACTERISTIC_UUID_RX,
      );

      await targetCharacterUUID.setNotifyValue(true);

      _lastValueSubscription = targetCharacterUUID.lastValueStream.listen((
        value,
      ) {
        _value = value;
        setState(() {});
      });

      _characteristicTX = targetServiceUUID.characteristics.singleWhere(
        (item) => item.characteristicUuid.str == CHARACTERISTIC_UUID_TX,
      );
    } catch (e) {
      log.w("Discover Services Error:${e.toString()}");
    }
    _isDiscoveringServices = false;
  }

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.device.connectionState.listen((
      state,
    ) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }

      if (state == BluetoothConnectionState.disconnected) {
        backToHome(true);
      }
    });

    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      setState(() {});
    });

    _isDisconnectingSubscription = widget.device.isDisconnecting.listen((
      value,
    ) {
      _isDisconnecting = value;
      setState(() {});
    });

    onDiscoverServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            opacity: 1,
            fit: BoxFit.fitWidth,
            image: AssetImage('assets/backgrounds/background.jpeg'),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Listener(
                        onPointerDown: (details) {
                          Vibration.vibrate(duration: 100);
                          setState(() {
                            isLightPressed = true;
                          });
                          writeBLE(CH3, 1); // LED On
                        },
                        onPointerUp: (details) {
                          setState(() {
                            isLightPressed = false;
                          });
                          writeBLE(CH3, 0); // LED Off
                        },
                        child: SizedBox(
                          width: 55,
                          height: 55,
                          child: Icon(
                            Icons.tungsten,
                            size: 55,
                            color: isLightPressed
                                ? Colors.amberAccent
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      SizedBox(
                        width: 385,
                        height: 59,
                        child: Image(
                          fit: BoxFit.cover,
                          image: AssetImage('assets/title.png'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const SizedBox(
                              width: 55,
                              height: 55,
                              child: Icon(
                                Icons.settings,
                                size: 55,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              FlutterExitApp.exitApp(iosForceExit: true);
                            },
                            child: const SizedBox(
                              width: 55,
                              height: 55,
                              child: Icon(
                                Icons.exit_to_app,
                                size: 55,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Listener(
                        onPointerDown: (details) {
                          Vibration.vibrate(duration: 100);
                          setState(() {
                            isUpPressed = true;
                          });
                          writeBLE(CH1, 1); // forward
                        },
                        onPointerUp: (details) {
                          setState(() {
                            isUpPressed = false;
                          });
                          writeBLE(CH1, 0); // stop
                        },
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image(
                            fit: BoxFit.cover,
                            image: isUpPressed
                                ? const AssetImage(
                                    'assets/buttons/up_pressed.png',
                                  )
                                : const AssetImage('assets/buttons/up.png'),
                          ),
                        ),
                      ),
                      Listener(
                        onPointerDown: (details) {
                          Vibration.vibrate(duration: 100);
                          setState(() {
                            isDownPressed = true;
                          });
                          writeBLE(CH1, 2); // backward
                        },
                        onPointerUp: (details) {
                          setState(() {
                            isDownPressed = false;
                          });
                          writeBLE(CH1, 0); //stop
                        },
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image(
                            fit: BoxFit.cover,
                            image: isDownPressed
                                ? const AssetImage(
                                    'assets/buttons/down_pressed.png',
                                  )
                                : const AssetImage(
                                    'assets/buttons/down.png',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Listener(
                        onPointerDown: (details) {
                          Vibration.vibrate(duration: 100);
                          setState(() {
                            isLeftPressed = true;
                          });
                          writeBLE(CH2, 3);
                        },
                        onPointerUp: (details) {
                          setState(() {
                            isLeftPressed = false;
                          });
                          writeBLE(CH2, 0);
                        },
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image(
                            fit: BoxFit.cover,
                            image: isLeftPressed
                                ? const AssetImage(
                                    'assets/buttons/left_pressed.png',
                                  )
                                : const AssetImage(
                                    'assets/buttons/left.png',
                                  ),
                          ),
                        ),
                      ),
                      Listener(
                        onPointerDown: (details) {
                          Vibration.vibrate(duration: 100);
                          setState(() {
                            isRightPressed = true;
                          });
                          writeBLE(CH2, 4);
                        },
                        onPointerUp: (details) {
                          setState(() {
                            isRightPressed = false;
                          });
                          writeBLE(CH2, 0);
                        },
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image(
                            fit: BoxFit.cover,
                            image: isRightPressed
                                ? const AssetImage(
                                    'assets/buttons/right_pressed.png',
                                  )
                                : const AssetImage(
                                    'assets/buttons/right.png',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
