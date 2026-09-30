import 'package:flutter/material.dart';

import '../ble/ble_controller.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.controller});

  final BleController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Device'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _DeviceHeader(controller: controller),
              const SizedBox(height: 24),
              _StatusCard(controller: controller),
              const SizedBox(height: 24),
              Text(
                'Event Log',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _EventLog(events: controller.eventLog),
              const SizedBox(height: 24),
              _ConnectionAction(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.controller});

  final BleController controller;

  @override
  Widget build(BuildContext context) {
    final icon = controller.isConnected
        ? Icons.bluetooth_connected
        : Icons.bluetooth_disabled;

    return Row(
      children: [
        Icon(icon, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.selectedDeviceName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(controller.connectionStatusLabel),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller});

  final BleController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.deviceStatus;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _InfoRow(
              label: 'Status',
              value: status?.status.toUpperCase() ?? '-',
            ),
            const Divider(),
            _InfoRow(
              label: 'Battery',
              value: status == null ? '-' : '${status.battery}%',
            ),
            const Divider(),
            _InfoRow(
              label: 'Connection',
              value: controller.connectionStatusLabel,
            ),
            const Divider(),
            _InfoRow(
              label: 'Last Update',
              value: _formatTime(controller.lastUpdate),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '-';
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EventLog extends StatelessWidget {
  const _EventLog({required this.events});

  final List<String> events;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: events.isEmpty
            ? const Text('Waiting for BLE events...')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: events
                    .take(8)
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(event),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }
}

class _ConnectionAction extends StatelessWidget {
  const _ConnectionAction({required this.controller});

  final BleController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isConnected) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: controller.disconnect,
          icon: const Icon(Icons.bluetooth_disabled),
          label: const Text('Disconnect'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: controller.isConnectionInProgress ? null : controller.connect,
        icon: const Icon(Icons.bluetooth_connected),
        label: Text(
          controller.isConnectionInProgress ? 'Connecting...' : 'Connect',
        ),
      ),
    );
  }
}
