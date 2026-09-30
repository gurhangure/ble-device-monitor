# BLE Device Monitor

A small Flutter BLE application that demonstrates a production-oriented Bluetooth Low Energy (BLE) workflow: device discovery, GATT connection, characteristic notifications, connection-state handling, and automatic recovery after an unexpected disconnect.

The app is designed to work with a companion macOS BLE peripheral demo that advertises a custom GATT service and streams JSON status updates.

## Features

- Scan for all nearby BLE peripherals
- Filter discovery to the demo GATT service
- Connect to a selected BLE device
- Discover a custom GATT service and characteristic
- Subscribe to characteristic notifications
- Parse and display live device status and battery data
- Track BLE lifecycle events in an in-app event log
- Distinguish manual disconnects from unexpected connection loss
- Automatically reconnect after an unexpected disconnect
- Re-discover services and re-subscribe to notifications after reconnect

## BLE Contract

| Item | Value |
| --- | --- |
| Demo device name | `BLE Demo Device` |
| Service UUID | `FFF0` |
| Status characteristic UUID | `FFF1` |
| Characteristic properties | Read / Notify |
| Notification payload | JSON |

Example notification:

```json
{"status":"active","battery":87}
```

## App Flow

```text
Scan
  ↓
Discover BLE peripheral
  ↓
Connect
  ↓
Discover FFF0 service
  ↓
Subscribe to FFF1 notifications
  ↓
Display live status
  ↓
Unexpected disconnect
  ↓
Reconnect → rediscover → resubscribe
```

An explicit user disconnect intentionally disables automatic reconnection.

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

`BleController` owns BLE lifecycle and connection state. UI screens remain focused on presentation, while `DeviceStatus` handles notification payload parsing.

## Tech Stack

- Flutter / Dart
- `flutter_blue_plus`
- `permission_handler`
- Android BLE APIs through Flutter
- iOS Core Bluetooth integration through Flutter

## Getting Started

### Requirements

- Flutter SDK
- A physical Android or iOS device with BLE support
- A BLE peripheral exposing service `FFF0` and characteristic `FFF1`

BLE scanning should be tested on physical hardware rather than an emulator.

### Run

```bash
flutter pub get
flutter run
```

On Android 12 and newer, the app requests Nearby Devices permissions at runtime. Android 11 and older use the legacy Bluetooth/location permission model.

## Companion Peripheral

This repository is intended to be used with the companion [`ble-peripheral-macos`](https://github.com/gurhangure/ble-peripheral-macos) project, which:

1. Advertises service `FFF0`
2. Exposes notify/read characteristic `FFF1`
3. Sends status JSON every two seconds

Keeping the central and peripheral implementations in separate repositories makes each side independently understandable and reusable.

## Testing

Run static analysis and tests with:

```bash
flutter analyze
flutter test
```

The project includes unit coverage for BLE notification payload parsing.

## Platform Notes

The current demo workflow was validated with a physical Android device. iOS Bluetooth usage descriptions are included, but the iOS path should be validated on physical iOS hardware before being treated as production-ready.

## Scope

This is a focused portfolio/demo project rather than a production device SDK. A production implementation would normally add items such as structured error reporting, reconnect backoff policies, telemetry, broader device-compatibility testing, and integration tests against target hardware.

## Dependency License Note

This demo uses `flutter_blue_plus` with its nonprofit/personal-use connection license option. Review that package's current license terms before using the same dependency in a commercial product.
