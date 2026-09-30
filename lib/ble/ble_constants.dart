import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract final class BleConstants {
  static final Guid demoServiceUuid = Guid('FFF0');
  static final Guid statusCharacteristicUuid = Guid('FFF1');

  static const String demoDeviceName = 'BLE Demo Device';
  static const Duration scanTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration reconnectTimeout = Duration(seconds: 8);
  static const Duration reconnectDelay = Duration(seconds: 2);

  static bool isDemoService(Guid uuid) =>
      uuid.toString().toLowerCase().contains('fff0');

  static bool isStatusCharacteristic(Guid uuid) =>
      uuid.toString().toLowerCase().contains('fff1');
}
