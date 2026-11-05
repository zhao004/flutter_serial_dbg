import 'dart:async';
import 'dart:typed_data';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../di/injector.dart';
import '../../models/ble_gatt.dart';
import '../../models/log_entry.dart';
import '../../models/text_encoding.dart';
import '../../services/protocol/hex_codec.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_surface_card.dart';
import '../../widgets/app_toast.dart';
import 'ble_gatt_controller.dart';

/// 当前 BLE 连接的服务与特征浏览页面。
class BleGattPage extends StatefulWidget {
  const BleGattPage({super.key});

  @override
  State<BleGattPage> createState() => _BleGattPageState();
}

class _BleGattPageState extends State<BleGattPage> {
  late final BleGattController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<BleGattController>();
  }

  Future<void> _openCharacteristic(BleGattCharacteristicInfo characteristic) {
    final colors = context.appColors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      barrierColor: colors.barrier,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: _GattCharacteristicSheet(
          controller: _controller,
          characteristic: characteristic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SignalBuilder(
      builder: (context) {
        final services = _controller.services.value;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: '返回',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('BLE GATT'),
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: colors.pageGradient),
            child: SafeArea(
              top: false,
              child: Column(
                children: <Widget>[
                  ErrorToastListener(
                    readError: () => _controller.lastError.value,
                    onShown: _controller.dismissError,
                  ),
                  Expanded(
                    child: services.isEmpty
                        ? _EmptyGattState(controller: _controller)
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              12,
                              12,
                              24 + MediaQuery.viewPaddingOf(context).bottom,
                            ),
                            itemCount: services.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final service = services[index];
                              return _ServiceCard(
                                service: service,
                                controller: _controller,
                                onOpen: (characteristic) => unawaited(
                                  _openCharacteristic(characteristic),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.controller,
    required this.onOpen,
  });

  final BleGattServiceInfo service;
  final BleGattController controller;
  final ValueChanged<BleGattCharacteristicInfo> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey<String>('gatt-service-${service.uuid}'),
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: true,
        leading: Icon(Icons.hub_outlined, color: colors.primaryDeep),
        title: Text(
          '服务',
          style: TextStyle(color: colors.ink, fontWeight: FontWeight.w700),
        ),
        subtitle: SelectableText(
          service.uuid,
          style: TextStyle(
            color: colors.inkMuted,
            fontFamily: 'monospace',
            fontSize: 11,
          ),
        ),
        children: <Widget>[
          for (final characteristic in service.characteristics)
            _CharacteristicTile(
              characteristic: characteristic,
              value: controller.valueFor(service.uuid, characteristic.uuid),
              onTap: () => onOpen(characteristic),
            ),
        ],
      ),
    );
  }
}

class _CharacteristicTile extends StatelessWidget {
  const _CharacteristicTile({
    required this.characteristic,
    required this.value,
    required this.onTap,
  });

  final BleGattCharacteristicInfo characteristic;
  final BleGattValue? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: <Widget>[
              Icon(Icons.memory_rounded, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      characteristic.properties
                          .map((property) => property.label)
                          .join(' · '),
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      characteristic.uuid,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.inkMuted,
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                      ),
                    ),
                    if (value != null) ...<Widget>[
                      const SizedBox(height: 5),
                      Text(
                        HexCodec.format(value!.copyBytes()),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.receive,
                          fontFamily: 'monospace',
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGattState extends StatelessWidget {
  const _EmptyGattState({required this.controller});

  final BleGattController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: AppSurfaceCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled_rounded,
              size: 52,
              color: colors.mutedIcon,
            ),
            const SizedBox(height: 10),
            Text(
              controller.isBound ? '未发现 GATT 服务' : 'BLE 尚未连接',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 7),
            Text(
              controller.isBound
                  ? '设备没有返回可浏览的服务与特征。'
                  : '返回首页连接 BLE 设备后再打开 GATT 工作台。',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _GattCharacteristicSheet extends StatefulWidget {
  const _GattCharacteristicSheet({
    required this.controller,
    required this.characteristic,
  });

  final BleGattController controller;
  final BleGattCharacteristicInfo characteristic;

  @override
  State<_GattCharacteristicSheet> createState() =>
      _GattCharacteristicSheetState();
}

class _GattCharacteristicSheetState extends State<_GattCharacteristicSheet> {
  final TextEditingController _payloadController = TextEditingController();
  PayloadFormat _format = PayloadFormat.text;
  bool _withResponse = true;

  String get _key => characteristicKey(
    widget.characteristic.serviceUuid,
    widget.characteristic.uuid,
  );

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    final value = await widget.controller.read(
      serviceUuid: widget.characteristic.serviceUuid,
      characteristicUuid: widget.characteristic.uuid,
    );
    if (!mounted || value == null) {
      return;
    }
    AppToast.success(context, '特征读取完成');
  }

  Future<void> _write() async {
    final Uint8List data;
    try {
      data = PayloadCodec.encode(
        _payloadController.text,
        format: _format,
        textEncoding: TextEncoding.utf8,
        appendCrlf: false,
      );
    } on PayloadFormatException catch (error) {
      AppToast.warning(context, error.message);
      return;
    }
    final written = await widget.controller.write(
      serviceUuid: widget.characteristic.serviceUuid,
      characteristicUuid: widget.characteristic.uuid,
      data: data,
      withResponse:
          _withResponse &&
          widget.characteristic.properties.contains(BleGattProperty.write),
    );
    if (!mounted || !written) {
      return;
    }
    AppToast.success(context, '特征写入完成');
  }

  Future<void> _toggleNotify(bool enabled) async {
    final changed = await widget.controller.setNotify(
      serviceUuid: widget.characteristic.serviceUuid,
      characteristicUuid: widget.characteristic.uuid,
      enabled: enabled,
    );
    if (!mounted || !changed) {
      return;
    }
    AppToast.success(context, enabled ? '已开启通知' : '已关闭通知');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SignalBuilder(
      builder: (context) {
        final working = widget.controller.isWorking.value;
        final notified = widget.controller.notifiedKeys.value.contains(_key);
        final value = widget.controller.valueFor(
          widget.characteristic.serviceUuid,
          widget.characteristic.uuid,
        );
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '特征操作',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: <Widget>[
                  _UuidBlock(
                    label: 'Service',
                    value: widget.characteristic.serviceUuid,
                  ),
                  const SizedBox(height: 9),
                  _UuidBlock(
                    label: 'Characteristic',
                    value: widget.characteristic.uuid,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: widget.characteristic.properties
                        .map(
                          (property) => Chip(
                            label: Text(property.label),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<PayloadFormat>(
                                initialValue: _format,
                                decoration: const InputDecoration(
                                  labelText: '写入格式',
                                ),
                                items: const <DropdownMenuItem<PayloadFormat>>[
                                  DropdownMenuItem(
                                    value: PayloadFormat.text,
                                    child: Text('文本'),
                                  ),
                                  DropdownMenuItem(
                                    value: PayloadFormat.hex,
                                    child: Text('HEX'),
                                  ),
                                ],
                                onChanged: (format) {
                                  if (format != null) {
                                    setState(() => _format = format);
                                  }
                                },
                              ),
                            ),
                            if (widget.characteristic.properties.contains(
                              BleGattProperty.write,
                            )) ...<Widget>[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('带响应'),
                                    value: _withResponse,
                                    onChanged: working
                                        ? null
                                        : (value) {
                                            setState(
                                              () => _withResponse = value,
                                            );
                                          },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey<String>('gatt-write-payload'),
                          controller: _payloadController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: '写入内容',
                            hintText: '输入文本或 HEX 数据',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: working || !widget.characteristic.canWrite
                              ? null
                              : () => unawaited(_write()),
                          icon: const Icon(Icons.upload_rounded),
                          label: const Text('写入特征'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: working || !widget.characteristic.canRead
                              ? null
                              : () => unawaited(_read()),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('读取特征'),
                        ),
                        if (widget.characteristic.canNotify)
                          Material(
                            color: Colors.transparent,
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('订阅通知 / 指示'),
                              value: notified,
                              onChanged: working
                                  ? null
                                  : (enabled) =>
                                        unawaited(_toggleNotify(enabled)),
                            ),
                          ),
                        const Divider(),
                        Text(
                          '最近值',
                          style: TextStyle(
                            color: colors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        SelectableText(
                          value == null
                              ? '暂无数据'
                              : '${formatLogTimestamp(value.receivedAt)}\n'
                                    '${HexCodec.format(value.copyBytes())}',
                          style: TextStyle(
                            color: value == null
                                ? colors.inkMuted
                                : colors.receive,
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UuidBlock extends StatelessWidget {
  const _UuidBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: colors.inkMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            value,
            style: TextStyle(
              color: colors.ink,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
