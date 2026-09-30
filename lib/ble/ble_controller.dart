import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/device_status.dart';
import 'ble_constants.dart';

enum DeviceConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class BleController extends ChangeNotifier {
  final List<ScanResult> _scanResults = [];
  final List<String> _eventLog = [];

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _scanStateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  Timer? _reconnectTimer;

  BluetoothDevice? _selectedDevice;
  BluetoothCharacteristic? _statusCharacteristic;
  DeviceStatus? _deviceStatus;
  DateTime? _lastUpdate;
  DeviceConnectionStatus _connectionStatus = DeviceConnectionStatus.disconnected;
  bool _isScanning = false;
  bool _manualDisconnect = false;
  bool _isConnecting = false;
  bool _disposed = false;

  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  List<String> get eventLog => List.unmodifiable(_eventLog);
  BluetoothDevice? get selectedDevice => _selectedDevice;
  DeviceStatus? get deviceStatus => _deviceStatus;
  DateTime? get lastUpdate => _lastUpdate;
  DeviceConnectionStatus get connectionStatus => _connectionStatus;
  bool get isScanning => _isScanning;

  bool get isConnected =>
      _connectionStatus == DeviceConnectionStatus.connected;

  bool get isConnectionInProgress =>
      _connectionStatus == DeviceConnectionStatus.connecting ||
      _connectionStatus == DeviceConnectionStatus.reconnecting;

  void initialize() {
    _scanResultsSubscription = FlutterBluePlus.onScanResults.listen((results) {
      _scanResults
        ..clear()
        ..addAll(results);
      _notifyListeners();
    });

    _scanStateSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      _notifyListeners();
    });
  }

  Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> scanAllDevices() async {
    await _startScan();
  }

  Future<void> scanDemoDevice() async {
    await _startScan(withServices: [BleConstants.demoServiceUuid]);
  }

  Future<void> _startScan({List<Guid>? withServices}) async {
    final permissionsGranted = await requestBluetoothPermissions();
    if (!permissionsGranted) {
      throw const BlePermissionException();
    }

    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;

    _scanResults.clear();
    _notifyListeners();

    await FlutterBluePlus.startScan(
      withServices: withServices ?? const [],
      timeout: BleConstants.scanTimeout,
    );
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  Future<void> selectAndConnect(BluetoothDevice device) async {
    _selectedDevice = device;
    _eventLog.clear();
    _deviceStatus = null;
    _lastUpdate = null;
    _notifyListeners();

    await connect();
  }

  Future<void> connect() async {
    final device = _selectedDevice;
    if (device == null || _isConnecting) {
      return;
    }

    _manualDisconnect = false;
    _isConnecting = true;
    _connectionStatus = DeviceConnectionStatus.connecting;
    _addLog('Connecting to device');

    await FlutterBluePlus.stopScan();
    await _connectionStateSubscription?.cancel();

    _connectionStateSubscription = device.connectionState.listen(
      (state) => _handleConnectionState(device, state),
    );

    try {
      await device.connect(
        license: License.nonprofit,
        timeout: BleConstants.connectionTimeout,
      );
    } catch (_) {
      _addLog('Connection attempt failed');
      if (!_manualDisconnect) {
        _connectionStatus = DeviceConnectionStatus.reconnecting;
        _notifyListeners();
        _scheduleReconnect(device);
      }
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _handleConnectionState(
    BluetoothDevice device,
    BluetoothConnectionState state,
  ) async {
    if (state == BluetoothConnectionState.connected) {
      _reconnectTimer?.cancel();
      _connectionStatus = DeviceConnectionStatus.connected;
      _addLog('Device connected');
      await _discoverAndSubscribe(device);
      return;
    }

    if (state != BluetoothConnectionState.disconnected || _isConnecting) {
      return;
    }

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _statusCharacteristic = null;

    if (_manualDisconnect) {
      _connectionStatus = DeviceConnectionStatus.disconnected;
      _addLog('Device disconnected');
    } else {
      _connectionStatus = DeviceConnectionStatus.reconnecting;
      _addLog('Connection lost');
      _scheduleReconnect(device);
    }

    _notifyListeners();
  }

  Future<void> _discoverAndSubscribe(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      for (final service in services) {
        if (!BleConstants.isDemoService(service.uuid)) {
          continue;
        }

        _addLog('FFF0 service discovered');

        for (final characteristic in service.characteristics) {
          if (!BleConstants.isStatusCharacteristic(characteristic.uuid)) {
            continue;
          }

          _statusCharacteristic = characteristic;

          await _notificationSubscription?.cancel();
          _notificationSubscription = characteristic.onValueReceived.listen(
            _handleNotification,
          );

          await characteristic.setNotifyValue(true);
          _addLog('Subscribed to FFF1 notifications');
          return;
        }
      }

      _addLog('FFF1 characteristic not found');
    } catch (_) {
      _addLog('Service discovery failed');
    }
  }

  void _handleNotification(List<int> value) {
    final payload = String.fromCharCodes(value);

    try {
      _deviceStatus = DeviceStatus.fromJsonString(payload);
      _lastUpdate = DateTime.now();
      _addLog('Notification received');
    } on FormatException {
      _addLog('Invalid notification payload');
    }
  }

  void _scheduleReconnect(BluetoothDevice device) {
    if (_manualDisconnect) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(BleConstants.reconnectDelay, () async {
      if (_manualDisconnect || _isConnecting || _disposed) {
        return;
      }

      _addLog('Attempting reconnect');
      _isConnecting = true;

      try {
        await device.connect(
          license: License.nonprofit,
          timeout: BleConstants.reconnectTimeout,
        );
      } catch (_) {
        _addLog('Reconnect failed');
        _isConnecting = false;
        _scheduleReconnect(device);
        return;
      }

      _isConnecting = false;
    });
  }

  Future<void> disconnect() async {
    final device = _selectedDevice;
    if (device == null) {
      return;
    }

    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _addLog('Manual disconnect requested');

    await device.disconnect();
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _statusCharacteristic = null;
    _connectionStatus = DeviceConnectionStatus.disconnected;
    _deviceStatus = null;
    _lastUpdate = null;
    _notifyListeners();
  }

  Future<void> returnToScanner() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();

    final device = _selectedDevice;
    if (device != null) {
      await device.disconnect();
    }

    await _connectionStateSubscription?.cancel();
    await _notificationSubscription?.cancel();
    _connectionStateSubscription = null;
    _notificationSubscription = null;
    _selectedDevice = null;
    _statusCharacteristic = null;
    _deviceStatus = null;
    _lastUpdate = null;
    _connectionStatus = DeviceConnectionStatus.disconnected;
    _eventLog.clear();
    _notifyListeners();
  }

  String displayNameFor(ScanResult result) {
    final advertisedName = result.advertisementData.advName.trim();
    if (advertisedName.isNotEmpty) {
      return advertisedName;
    }

    final isDemoDevice = result.advertisementData.serviceUuids.any(
      BleConstants.isDemoService,
    );

    return isDemoDevice
        ? BleConstants.demoDeviceName
        : 'Unknown BLE Device';
  }

  String get selectedDeviceName {
    final platformName = _selectedDevice?.platformName.trim() ?? '';
    return platformName.isNotEmpty
        ? platformName
        : BleConstants.demoDeviceName;
  }

  String get connectionStatusLabel => switch (_connectionStatus) {
    DeviceConnectionStatus.disconnected => 'Disconnected',
    DeviceConnectionStatus.connecting => 'Connecting...',
    DeviceConnectionStatus.connected => 'Connected',
    DeviceConnectionStatus.reconnecting => 'Reconnecting...',
  };

  void _addLog(String message) {
    _eventLog.insert(0, '${_formatTime(DateTime.now())}  $message');
    if (_eventLog.length > 20) {
      _eventLog.removeLast();
    }
    _notifyListeners();
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  void _notifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _scanResultsSubscription?.cancel();
    _scanStateSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _notificationSubscription?.cancel();
    _selectedDevice?.disconnect();
    super.dispose();
  }
}

class BlePermissionException implements Exception {
  const BlePermissionException();
}
