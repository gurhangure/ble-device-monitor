# BLE Device Monitor

A small Flutter BLE application for discovering nearby Bluetooth Low Energy devices, connecting to a custom GATT service, receiving live notifications, monitoring device status, and recovering automatically from unexpected connection loss.

## Features

- Scans nearby BLE devices
- Supports filtered discovery for the demo peripheral
- Connects to a BLE GATT peripheral
- Discovers custom services and characteristics
- Subscribes to live characteristic notifications
- Displays device status and battery information
- Tracks connection state
- Automatically reconnects after unexpected connection loss
- Distinguishes manual disconnects from unexpected disconnects
- Re-discovers services and re-subscribes after reconnection
- Displays a simple BLE event log

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

## Requirements

- Flutter SDK
- Android or iOS device with Bluetooth Low Energy support
- Bluetooth enabled
- Nearby devices permission on supported Android versions

## Run

Install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run the application:

```bash
flutter run
```

## Companion Peripheral

This repository is intended to be used with the companion [`ble-peripheral-macos`](https://github.com/gurhangure/ble-peripheral-macos) project, which:

1. Advertises service `FFF0`
2. Exposes notify/read characteristic `FFF1`
3. Sends status JSON every two seconds

Keeping the central and peripheral implementations in separate repositories makes each side independently understandable and reusable.

## Purpose

This repository is a focused demonstration of BLE client development with Flutter.

It is intended to demonstrate BLE discovery, GATT communication, live notifications, connection-state handling, and reconnection behavior without depending on a proprietary hardware device or protocol.