import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../../models/connection_config.dart';
import '../../../models/connection_mode.dart';
import '../../../models/connection_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surface_card.dart';
import '../../../widgets/gradient_primary_button.dart';
import '../home_controller.dart';
import 'connection_panel_header.dart';

/// BLE 设备扫描、选择和连接面板。
class BleConnectionPanel extends StatefulWidget {
  const BleConnectionPanel({super.key, required this.controller});

  final HomeController controller;

  @override
  State<BleConnectionPanel> createState() => _BleConnectionPanelState();
}

class _BleConnectionPanelState extends State<BleConnectionPanel> {
  BleConfig? _savedConfig;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedConfig());
  }

  Future<void> _loadSavedConfig() async {
    final config = await widget.controller.loadSavedConfig(ConnectionMode.ble);
    if (!mounted || config is! BleConfig) {
      return;
    }
    setState(() {
      _savedConfig = config;
    });
  }

  Future<void> _openScanner() async {
    final colors = context.appColors;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      barrierColor: colors.barrier,
      builder: (context) => BleScanSheet(controller: widget.controller),
    );
  }

  Future<void> _connect() async {
    final selected = widget.controller.selectedBleDevice.value;
    final saved = _savedConfig;
    final config = selected == null
        ? saved
        : saved?.remoteId == selected.remoteId
        ? saved
        : BleConfig(remoteId: selected.remoteId);
    if (config == null) {
      return;
    }
    await widget.controller.connect(config);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SignalBuilder(
      builder: (context) {
        final snapshot = widget.controller.connectionState.value;
        final selected = widget.controller.selectedBleDevice.value;
        final connected = snapshot.status == TransportStatus.connected;
        final busy = snapshot.status.isBusy;
        final actionLoading =
            snapshot.status == TransportStatus.connecting ||
            snapshot.status == TransportStatus.disconnecting;
        final displayName = selected?.displayName;
        final remoteId = selected?.remoteId ?? _savedConfig?.remoteId;
        final canConnect = !busy && (selected != null || _savedConfig != null);
        return AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ConnectionPanelHeader(status: snapshot.status),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  border: Border.all(color: colors.outline),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.bluetooth_rounded,
                        color: colors.primary,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            displayName ?? '选择 BLE 设备',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            remoteId ?? '扫描附近蓝牙低功耗设备',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamily: remoteId == null
                                      ? null
                                      : 'monospace',
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if ((snapshot.message ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  snapshot.message!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => unawaited(_openScanner()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.bluetooth_searching_rounded),
                      label: const Text('扫描设备', maxLines: 1, softWrap: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: GradientPrimaryButton(
                      label: connected ? '断开' : '连接',
                      icon: connected
                          ? Icons.link_off_rounded
                          : Icons.link_rounded,
                      isLoading: actionLoading,
                      onPressed: busy
                          ? null
                          : connected
                          ? () => unawaited(widget.controller.disconnect())
                          : canConnect
                          ? () => unawaited(_connect())
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// BLE 扫描结果弹层。
class BleScanSheet extends StatefulWidget {
  const BleScanSheet({super.key, required this.controller});

  final HomeController controller;

  @override
  State<BleScanSheet> createState() => _BleScanSheetState();
}

class _BleScanSheetState extends State<BleScanSheet> {
  _BleDeviceFilter _filter = _BleDeviceFilter.all;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.startBleScan());
  }

  @override
  void dispose() {
    unawaited(widget.controller.stopBleScan());
    super.dispose();
  }

  Future<void> _restartScan() async {
    await widget.controller.stopBleScan();
    await widget.controller.startBleScan();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: SignalBuilder(
        builder: (context) {
          final colors = context.appColors;
          final devices = widget.controller.bleDevices.value;
          final scanning = widget.controller.isBleScanning.value;
          final filteredDevices = switch (_filter) {
            _BleDeviceFilter.all => devices,
            _BleDeviceFilter.named =>
              devices
                  .where((device) => device.name.isNotEmpty)
                  .toList(growable: false),
            _BleDeviceFilter.unnamed =>
              devices
                  .where((device) => device.name.isEmpty)
                  .toList(growable: false),
          };
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 10, 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.bluetooth_searching_rounded,
                        size: 20,
                        color: colors.primaryDeep,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '附近 BLE 设备',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '重新扫描',
                      onPressed: _restartScan,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_BleDeviceFilter>(
                    key: const ValueKey<String>('ble-device-filter'),
                    showSelectedIcon: false,
                    segments: const <ButtonSegment<_BleDeviceFilter>>[
                      ButtonSegment<_BleDeviceFilter>(
                        value: _BleDeviceFilter.all,
                        label: Text(
                          '全部',
                          key: ValueKey<String>('ble-filter-all'),
                        ),
                      ),
                      ButtonSegment<_BleDeviceFilter>(
                        value: _BleDeviceFilter.named,
                        label: Text(
                          '已命名',
                          key: ValueKey<String>('ble-filter-named'),
                        ),
                      ),
                      ButtonSegment<_BleDeviceFilter>(
                        value: _BleDeviceFilter.unnamed,
                        label: Text(
                          '未命名',
                          key: ValueKey<String>('ble-filter-unnamed'),
                        ),
                      ),
                    ],
                    selected: <_BleDeviceFilter>{_filter},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _filter = selection.single;
                      });
                    },
                  ),
                ),
              ),
              if (scanning)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: colors.primary,
                  backgroundColor: colors.primarySoft,
                )
              else
                const SizedBox(height: 2),
              const Divider(height: 1),
              Expanded(
                child: devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.bluetooth_searching_rounded,
                              size: 48,
                              color: colors.mutedIcon,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              scanning ? '正在扫描附近设备' : '未发现 BLE 设备',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.inkMuted),
                            ),
                          ],
                        ),
                      )
                    : filteredDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.filter_alt_off_outlined,
                              size: 44,
                              color: colors.mutedIcon,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '当前筛选下暂无设备',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.inkMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDevices.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final device = filteredDevices[index];
                          return Material(
                            color: colors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                widget.controller.selectBleDevice(device);
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: colors.outline),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.bluetooth_rounded,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            device.displayName,
                                            style: TextStyle(
                                              color: colors.ink,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            device.remoteId,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontFamily: 'monospace',
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${device.rssi} dBm',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _BleDeviceFilter { all, named, unnamed }
