# BLE Device Monitor

A small Flutter BLE application that demonstrates device discovery, GATT connectivity, live characteristic notifications, connection-state handling, and automatic recovery after unexpected connection loss.

## Features

- Scans for nearby BLE peripherals
- Supports filtered discovery for the demo peripheral
- Connects to a selected BLE device
- Discovers custom GATT services and characteristics
- Subscribes to live characteristic notifications
- Parses and displays device status and battery data
- Tracks BLE lifecycle events in an event log
- Distinguishes manual disconnects from unexpected connection loss
- Automatically reconnects after unexpected disconnects
- Re-discovers services and re-subscribes after reconnection

## BLE Contract

| Type | UUID | Behavior |
| --- | --- | --- |
| Primary service | `FFF0` | Demo device service |
| Status characteristic | `FFF1` | Read + Notify |

Example notification payload:

```json
{
  "status": "active",
  "battery": 87
}
```

## App Flow

```text
Scan
  ↓
Discover BLE peripheral
  ↓
Connect
  ↓
Discover GATT services
  ↓
Find FFF0 service
  ↓
Subscribe to FFF1
  ↓
Receive live notifications
  ↓
Display device status
```

If the connection is lost unexpectedly:

```text
Connection lost
  ↓
Reconnecting...
  ↓
Connected
  ↓
Re-discover services
  ↓
Re-subscribe to notifications
  ↓
Live data resumes
```

A manual disconnect does not trigger automatic reconnection.

## Project Structure

```text
lib/
├── main.dart
├── ble/
│   ├── ble_constants.dart
│   └── ble_controller.dart
├── models/
│   └── device_status.dart
└── screens/
    ├── device_screen.dart
    └── scanner_screen.dart
```

`BleController` owns the BLE lifecycle and connection state, while the UI screens remain focused on presentation.

## Tech Stack

- Flutter
- Dart
- `flutter_blue_plus`
- `permission_handler`
- Bluetooth Low Energy
- GATT

## Requirements

- Flutter SDK
- Physical Android or iOS device with BLE support
- Bluetooth enabled
- BLE peripheral exposing service `FFF0` and characteristic `FFF1`

BLE scanning should be tested on physical hardware rather than an emulator.

## Run

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Companion Peripheral

This repository is designed to work with the native macOS BLE peripheral:

[`ble-peripheral-macos`](https://github.com/gurhangure/ble-peripheral-macos)

The peripheral:

1. Advertises service `FFF0`
2. Exposes read/notify characteristic `FFF1`
3. Sends status JSON every two seconds

Keeping the central and peripheral implementations in separate repositories makes each side independently understandable and reusable.

## Testing

The project includes unit coverage for BLE notification payload parsing.

## Platform Notes

The demo workflow has been validated with a physical Android device.

iOS Bluetooth usage descriptions are included, but the iOS path should be validated on physical iOS hardware before being treated as production-ready.

## Scope

This is a focused portfolio and demonstration project rather than a production device SDK.

A production implementation would typically add structured error reporting, reconnect backoff policies, telemetry, broader device compatibility testing, and integration tests against target hardware.

## Dependency License Note

This demo uses `flutter_blue_plus` with its nonprofit/personal-use connection license option. Review the package's current license terms before using the same dependency in a commercial product.