import 'package:flutter/material.dart';

import 'ble/ble_controller.dart';
import 'screens/scanner_screen.dart';

void main() {
  runApp(const BleDeviceMonitorApp());
}

class BleDeviceMonitorApp extends StatefulWidget {
  const BleDeviceMonitorApp({super.key});

  @override
  State<BleDeviceMonitorApp> createState() => _BleDeviceMonitorAppState();
}

class _BleDeviceMonitorAppState extends State<BleDeviceMonitorApp> {
  late final BleController _bleController;

  @override
  void initState() {
    super.initState();
    _bleController = BleController()..initialize();
  }

  @override
  void dispose() {
    _bleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE Device Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ScannerScreen(controller: _bleController),
    );
  }
}
