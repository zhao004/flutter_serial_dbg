import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';

import '../../../models/connection_config.dart';
import '../../../models/connection_mode.dart';
import '../../../models/connection_state.dart';
import '../../../models/usb_serial_device_info.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/constants.dart';
import '../../../utils/validators.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/app_surface_card.dart';
import '../../../widgets/gradient_primary_button.dart';
import '../home_controller.dart';
import 'connection_panel_header.dart';

/// USB 串口设备、通信参数和连接生命周期面板。
class UsbConnectionPanel extends StatefulWidget {
  const UsbConnectionPanel({super.key, required this.controller});

  final HomeController controller;

  @override
  State<UsbConnectionPanel> createState() => _UsbConnectionPanelState();
}

class _UsbConnectionPanelState extends State<UsbConnectionPanel> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _baudRateController = TextEditingController(
    text: '115200',
  );

  int _dataBits = 8;
  UsbStopBits _stopBits = UsbStopBits.one;
  UsbParity _parity = UsbParity.none;
  UsbSerialConfig? _savedConfig;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _baudRateController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final config = await widget.controller.loadSavedConfig(
      ConnectionMode.usbSerial,
    );
    if (!mounted) {
      return;
    }
    if (config is UsbSerialConfig) {
      setState(() {
        _savedConfig = config;
        _baudRateController.text = '${config.baudRate}';
        _dataBits = config.dataBits;
        _stopBits = config.stopBits;
        _parity = config.parity;
      });
    }

    await widget.controller.refreshUsbDevices();
    if (!mounted || widget.controller.selectedUsbDevice.value != null) {
      return;
    }
    final devices = widget.controller.usbDevices.value;
    final saved = _savedConfig;
    if (saved != null) {
      for (final device in devices) {
        if (device.deviceId == saved.deviceId) {
          widget.controller.selectUsbDevice(device);
          return;
        }
      }
    }
    if (devices.length == 1) {
      widget.controller.selectUsbDevice(devices.single);
    }
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final device = widget.controller.selectedUsbDevice.value;
    final baudRate = parseUsbBaudRateInput(_baudRateController.text);
    if (device == null || baudRate == null) {
      return;
    }
    await widget.controller.connect(
      UsbSerialConfig(
        deviceId: device.deviceId,
        baudRate: baudRate,
        dataBits: _dataBits,
        stopBits: _stopBits,
        parity: _parity,
      ),
    );
  }

  Future<void> _openDevicePicker() async {
    final devices = widget.controller.usbDevices.value;
    if (devices.isEmpty) {
      await widget.controller.refreshUsbDevices();
      if (!mounted) {
        return;
      }
      if (widget.controller.usbDevices.value.isEmpty) {
        AppToast.warning(context, '未发现 USB 串口设备');
        return;
      }
    }
    if (!mounted) {
      return;
    }
    final colors = context.appColors;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      barrierColor: colors.barrier,
      builder: (context) => _UsbDevicePicker(
        devices: widget.controller.usbDevices.value,
        selected: widget.controller.selectedUsbDevice.value,
        onSelected: widget.controller.selectUsbDevice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final snapshot = widget.controller.connectionState.value;
        final devices = widget.controller.usbDevices.value;
        final selected = widget.controller.selectedUsbDevice.value;
        final refreshing = widget.controller.isUsbRefreshing.value;
        final connected = snapshot.status == TransportStatus.connected;
        final locked =
            connected ||
            snapshot.status == TransportStatus.connecting ||
            snapshot.status == TransportStatus.disconnecting;
        final selectedId =
            devices.any((device) => device.deviceId == selected?.deviceId)
            ? selected?.deviceId
            : null;
        final actionLoading =
            snapshot.status == TransportStatus.connecting ||
            snapshot.status == TransportStatus.disconnecting;

        return AppSurfaceCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ConnectionPanelHeader(status: snapshot.status),
                const SizedBox(height: 14),
                _UsbDeviceRow(
                  device: selected,
                  refreshing: refreshing,
                  enabled: !locked,
                  onTap: () => unawaited(_openDevicePicker()),
                  onRefresh: () =>
                      unawaited(widget.controller.refreshUsbDevices()),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _SerialField(
                        label: '波特率',
                        child: TextFormField(
                          controller: _baudRateController,
                          enabled: !locked,
                          validator: validateUsbBaudRateInput,
                          decoration: InputDecoration(
                            hintText: '115200',
                            suffixIcon: PopupMenuButton<int>(
                              tooltip: '常用波特率',
                              enabled: !locked,
                              onSelected: (value) {
                                _baudRateController.text = '$value';
                              },
                              itemBuilder: (context) {
                                return UsbSerialDefaults.commonBaudRates
                                    .map(
                                      (value) => PopupMenuItem<int>(
                                        value: value,
                                        child: Text('$value'),
                                      ),
                                    )
                                    .toList(growable: false);
                              },
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SerialField(
                        label: '数据位',
                        child: DropdownButtonFormField<int>(
                          initialValue: _dataBits,
                          decoration: const InputDecoration(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: const <DropdownMenuItem<int>>[
                            DropdownMenuItem(value: 5, child: Text('5')),
                            DropdownMenuItem(value: 6, child: Text('6')),
                            DropdownMenuItem(value: 7, child: Text('7')),
                            DropdownMenuItem(value: 8, child: Text('8')),
                          ],
                          onChanged: locked
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _dataBits = value);
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _SerialField(
                        label: '停止位',
                        child: DropdownButtonFormField<UsbStopBits>(
                          initialValue: _stopBits,
                          decoration: const InputDecoration(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: const <DropdownMenuItem<UsbStopBits>>[
                            DropdownMenuItem(
                              value: UsbStopBits.one,
                              child: Text('1'),
                            ),
                            DropdownMenuItem(
                              value: UsbStopBits.onePointFive,
                              child: Text('1.5'),
                            ),
                            DropdownMenuItem(
                              value: UsbStopBits.two,
                              child: Text('2'),
                            ),
                          ],
                          onChanged: locked
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _stopBits = value);
                                  }
                                },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SerialField(
                        label: '校验位',
                        child: DropdownButtonFormField<UsbParity>(
                          initialValue: _parity,
                          decoration: const InputDecoration(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: const <DropdownMenuItem<UsbParity>>[
                            DropdownMenuItem(
                              value: UsbParity.none,
                              child: Text('无'),
                            ),
                            DropdownMenuItem(
                              value: UsbParity.odd,
                              child: Text('奇'),
                            ),
                            DropdownMenuItem(
                              value: UsbParity.even,
                              child: Text('偶'),
                            ),
                            DropdownMenuItem(
                              value: UsbParity.mark,
                              child: Text('标记'),
                            ),
                            DropdownMenuItem(
                              value: UsbParity.space,
                              child: Text('空格'),
                            ),
                          ],
                          onChanged: locked
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _parity = value);
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                ),
                if (selected != null && !locked) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    selected.hardwareId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ],
                const SizedBox(height: 14),
                GradientPrimaryButton(
                  label: connected ? '断开' : '连接',
                  icon: connected ? Icons.link_off_rounded : Icons.usb_rounded,
                  isLoading: actionLoading,
                  onPressed:
                      snapshot.status.isBusy ||
                          refreshing ||
                          (!connected && selectedId == null)
                      ? null
                      : connected
                      ? () => unawaited(widget.controller.disconnect())
                      : () => unawaited(_connect()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UsbDeviceRow extends StatelessWidget {
  const _UsbDeviceRow({
    required this.device,
    required this.refreshing,
    required this.enabled,
    required this.onTap,
    required this.onRefresh,
  });

  final UsbSerialDeviceInfo? device;
  final bool refreshing;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final title = device?.displayName ?? 'USB 串口';
    final subtitle = device == null ? '自动识别并连接 USB 串口设备' : device!.deviceName;
    return Material(
      color: colors.surfaceMuted,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && !refreshing ? onTap : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
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
                child: Icon(Icons.usb_rounded, color: colors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
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
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.inkMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: '刷新 USB 设备',
                onPressed: enabled && !refreshing ? onRefresh : null,
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface,
                  side: BorderSide(color: colors.outline),
                ),
                icon: refreshing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 21),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SerialField extends StatelessWidget {
  const _SerialField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: colors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _UsbDevicePicker extends StatelessWidget {
  const _UsbDevicePicker({
    required this.devices,
    required this.selected,
    required this.onSelected,
  });

  final List<UsbSerialDeviceInfo> devices;
  final UsbSerialDeviceInfo? selected;
  final ValueChanged<UsbSerialDeviceInfo> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        16,
        18,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('选择 USB 串口', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final device = devices[index];
                final isSelected = selected?.deviceId == device.deviceId;
                return Material(
                  color: isSelected ? colors.primarySoft : colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      onSelected(device);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? colors.selectedBorder
                              : colors.outline,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.usb_rounded, color: colors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  device.deviceName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: colors.primaryDeep,
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
      ),
    );
  }
}
