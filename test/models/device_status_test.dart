import 'package:ble_device_monitor/models/device_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceStatus', () {
    test('parses a valid BLE notification payload', () {
      final status = DeviceStatus.fromJsonString(
        '{"status":"active","battery":87}',
      );

      expect(status.status, 'active');
      expect(status.battery, 87);
    });

    test('rejects an invalid payload', () {
      expect(
        () => DeviceStatus.fromJsonString('{"status":"active"}'),
        throwsFormatException,
      );
    });
  });
}
