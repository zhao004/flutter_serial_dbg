import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../../models/connection_config.dart';
import '../../../models/connection_mode.dart';
import '../../../models/connection_state.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surface_card.dart';
import '../../../widgets/app_toast.dart';
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

  Future<void> _configureGatt() async {
    final selected = widget.controller.selectedBleDevice.value;
    final current = _savedConfig;
    final remoteId = selected?.remoteId ?? current?.remoteId;
    if (remoteId == null) {
      AppToast.warning(context, '请先选择 BLE 设备');
      return;
    }
    final colors = context.appColors;
    final configured = await showModalBottomSheet<BleConfig>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      barrierColor: colors.barrier,
      builder: (context) => _BleGattConfigSheet(
        initial: current?.remoteId == remoteId
            ? current!
            : BleConfig(remoteId: remoteId),
      ),
    );
    if (!mounted || configured == null) {
      return;
    }
    setState(() {
      _savedConfig = configured;
    });
    final saved = await widget.controller.saveConnectionConfig(configured);
    if (mounted) {
      if (saved) {
        AppToast.success(context, 'GATT UUID 配置已保存');
      } else {
        AppToast.error(context, '保存 GATT UUID 配置失败');
      }
    }
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey<String>('ble-gatt-action'),
                  onPressed: connected
                      ? () => unawaited(context.push<void>(Routes.bleGatt))
                      : busy || remoteId == null
                      ? null
                      : () => unawaited(_configureGatt()),
                  icon: Icon(
                    connected
                        ? Icons.account_tree_outlined
                        : Icons.tune_rounded,
                  ),
                  label: Text(connected ? '查看 GATT 服务' : '手动配置 GATT UUID'),
                ),
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

class _BleGattConfigSheet extends StatefulWidget {
  const _BleGattConfigSheet({required this.initial});

  final BleConfig initial;

  @override
  State<_BleGattConfigSheet> createState() => _BleGattConfigSheetState();
}

class _BleGattConfigSheetState extends State<_BleGattConfigSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _serviceController;
  late final TextEditingController _writeController;
  late final TextEditingController _notifyController;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(
      text: widget.initial.serviceUuid,
    );
    _writeController = TextEditingController(
      text: widget.initial.writeCharacteristicUuid,
    );
    _notifyController = TextEditingController(
      text: widget.initial.notifyCharacteristicUuid,
    );
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _writeController.dispose();
    _notifyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    try {
      final config = BleConfig(
        remoteId: widget.initial.remoteId,
        serviceUuid: _optional(_serviceController.text),
        writeCharacteristicUuid: _optional(_writeController.text),
        notifyCharacteristicUuid: _optional(_notifyController.text),
      );
      Navigator.of(context).pop(config);
    } on ArgumentError catch (error) {
      setState(() {
        _validationError = error.message?.toString() ?? 'GATT UUID 格式无效';
      });
    }
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'GATT UUID 配置',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                widget.initial.remoteId,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey<String>('ble-service-uuid'),
                controller: _serviceController,
                decoration: const InputDecoration(
                  labelText: 'Service UUID（可选）',
                  hintText: '例如 6E400001-B5A3-F393-E0A9-E50E24DCCA9E',
                ),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey<String>('ble-write-uuid'),
                controller: _writeController,
                decoration: const InputDecoration(
                  labelText: 'Write Characteristic UUID（可选）',
                ),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey<String>('ble-notify-uuid'),
                controller: _notifyController,
                decoration: const InputDecoration(
                  labelText: 'Notify Characteristic UUID（可选）',
                ),
                autocorrect: false,
              ),
              if (_validationError != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _validationError!,
                  style: TextStyle(color: colors.warning, fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '留空时连接后自动选择可写特征，并在可用时自动启用通知。',
                style: TextStyle(color: colors.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded),
                label: const Text('应用配置'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
