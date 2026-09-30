import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../ble/ble_controller.dart';
import 'device_screen.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key, required this.controller});

  final BleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('BLE Device Monitor'),
            actions: [
              if (controller.isScanning)
                IconButton(
                  onPressed: controller.stopScan,
                  icon: const Icon(Icons.stop),
                  tooltip: 'Stop Scan',
                ),
            ],
          ),
          body: _buildBody(context),
          bottomNavigationBar: _ScanActions(
            isScanning: controller.isScanning,
            onScanAll: () => _runScan(context, controller.scanAllDevices),
            onScanDemo: () => _runScan(context, controller.scanDemoDevice),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.scanResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            controller.isScanning
                ? 'Scanning for BLE devices...'
                : 'Choose a scan option to discover nearby BLE devices.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: controller.scanResults.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = controller.scanResults[index];
        return _DeviceTile(
          result: result,
          deviceName: controller.displayNameFor(result),
          onTap: () => _openDevice(context, result.device),
        );
      },
    );
  }

  Future<void> _runScan(
    BuildContext context,
    Future<void> Function() scan,
  ) async {
    try {
      await scan();
    } on BlePermissionException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth permissions are required to scan.'),
        ),
      );
    }
  }

  Future<void> _openDevice(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    await controller.selectAndConnect(device);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceScreen(controller: controller),
      ),
    );

    await controller.returnToScanner();
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.result,
    required this.deviceName,
    required this.onTap,
  });

  final ScanResult result;
  final String deviceName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final services = result.advertisementData.serviceUuids;

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.bluetooth)),
      title: Text(deviceName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.device.remoteId.str),
          if (services.isNotEmpty) Text('Services: ${services.join(', ')}'),
        ],
      ),
      trailing: Text('${result.rssi} dBm'),
      onTap: onTap,
    );
  }
}

class _ScanActions extends StatelessWidget {
  const _ScanActions({
    required this.isScanning,
    required this.onScanAll,
    required this.onScanDemo,
  });

  final bool isScanning;
  final VoidCallback onScanAll;
  final VoidCallback onScanDemo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isScanning ? null : onScanAll,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Scan All Devices'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: isScanning ? null : onScanDemo,
                icon: const Icon(Icons.memory),
                label: const Text('Scan for Demo Device'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
