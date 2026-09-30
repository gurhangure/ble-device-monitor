import 'dart:convert';

class DeviceStatus {
  const DeviceStatus({required this.status, required this.battery});

  final String status;
  final int battery;

  factory DeviceStatus.fromJsonString(String source) {
    final data = jsonDecode(source);

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object.');
    }

    final status = data['status'];
    final battery = data['battery'];

    if (status is! String || battery is! num) {
      throw const FormatException('Invalid device status payload.');
    }

    return DeviceStatus(status: status, battery: battery.toInt());
  }
}
