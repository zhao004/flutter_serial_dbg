import 'dart:async';
import 'dart:typed_data';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../../di/injector.dart';
import '../../../models/connection_state.dart';
import '../../../models/log_entry.dart';
import '../../../models/protocol_event.dart';
import '../../../models/protocol_observation.dart';
import '../../../models/text_encoding.dart';
import '../../../routes/app_routes.dart';
import '../../../services/protocol/hex_codec.dart';
import '../../../theme/app_theme.dart';
import '../home_controller.dart';
import '../protocol_controller.dart';

/// 首页协议选择、实时解析结果和命令帧发送区。
class ProtocolPanel extends StatefulWidget {
  const ProtocolPanel({super.key, required this.homeController});

  final HomeController homeController;

  @override
  State<ProtocolPanel> createState() => _ProtocolPanelState();
}

class _ProtocolPanelState extends State<ProtocolPanel> {
  late final ProtocolController _protocolController;
  final TextEditingController _commandController = TextEditingController(
    text: '01',
  );
  final TextEditingController _payloadController = TextEditingController();
  PayloadFormat _payloadFormat = PayloadFormat.text;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _protocolController = getIt<ProtocolController>();
    _payloadController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _payloadController
      ..removeListener(_refreshPreview)
      ..dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  int? _parseCommand(String value) {
    var normalized = value.trim();
    if (normalized.toLowerCase().startsWith('0x')) {
      normalized = normalized.substring(2);
    }
    if (normalized.isEmpty || normalized.length > 2) {
      return null;
    }
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null || parsed < 0 || parsed > 0xFF ? null : parsed;
  }

  Uint8List? _encodeCurrentFrame() {
    final command = _parseCommand(_commandController.text);
    if (command == null) {
      return null;
    }
    try {
      final payload = PayloadCodec.encode(
        _payloadController.text,
        format: _payloadFormat,
        textEncoding: TextEncoding.utf8,
        appendCrlf: false,
      );
      return _protocolController.encode(command: command, payload: payload);
    } on PayloadFormatException {
      return null;
    }
  }

  Future<void> _sendFrame() async {
    final frame = _encodeCurrentFrame();
    if (frame == null) {
      return;
    }
    setState(() => _sending = true);
    final sent = await widget.homeController.sendBytes(
      frame,
      format: PayloadFormat.hex,
    );
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    if (sent) {
      _payloadController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SignalBuilder(
      builder: (context) {
        final profile = _protocolController.selectedProfile.value;
        final profiles = _protocolController.profiles.value;
        final observations = _protocolController.observations.value;
        final connected =
            widget.homeController.connectionState.value.status ==
            TransportStatus.connected;
        final preview = profile == null ? null : _encodeCurrentFrame();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Divider(height: 22),
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.account_tree_outlined,
                    size: 17,
                    color: colors.primaryDeep,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: profiles.isEmpty
                      ? Text(
                          '暂无协议 Profile',
                          style: Theme.of(context).textTheme.titleSmall,
                        )
                      : PopupMenuButton<int>(
                          tooltip: '选择协议 Profile',
                          initialValue: profile?.id,
                          onSelected: _protocolController.selectProfileId,
                          itemBuilder: (context) => <PopupMenuEntry<int>>[
                            for (final item in profiles)
                              PopupMenuItem<int>(
                                value: item.id,
                                child: Text(item.name),
                              ),
                          ],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  profile?.name ?? '选择协议 Profile',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: colors.inkMuted,
                              ),
                            ],
                          ),
                        ),
                ),
                IconButton(
                  tooltip: '管理协议 Profile',
                  onPressed: () =>
                      unawaited(context.push<void>(Routes.protocolProfiles)),
                  icon: const Icon(Icons.tune_rounded, size: 20),
                ),
              ],
            ),
            if (profiles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '新增协议 Profile 后可解析接收帧并组装发送帧。',
                  style: TextStyle(color: colors.inkMuted, fontSize: 11.5),
                ),
              )
            else if (profile == null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '请选择一个协议 Profile。',
                  style: TextStyle(color: colors.inkMuted, fontSize: 11.5),
                ),
              )
            else ...<Widget>[
              if (observations.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Container(
                  height: 82,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    border: Border.all(color: colors.outline),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: observations.length,
                    itemBuilder: (context, index) {
                      final observation =
                          observations[observations.length - index - 1];
                      return _ObservationRow(observation: observation);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 68,
                    child: TextField(
                      key: const ValueKey<String>('protocol-command'),
                      controller: _commandController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: '命令',
                        hintText: '01',
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const ValueKey<String>('protocol-payload'),
                      controller: _payloadController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '负载',
                        hintText: '文本或 HEX',
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  SizedBox(
                    height: 56,
                    child: PopupMenuButton<PayloadFormat>(
                      tooltip: '负载格式',
                      initialValue: _payloadFormat,
                      onSelected: (format) {
                        setState(() => _payloadFormat = format);
                      },
                      itemBuilder: (context) =>
                          const <PopupMenuEntry<PayloadFormat>>[
                            PopupMenuItem(
                              value: PayloadFormat.text,
                              child: Text('文本'),
                            ),
                            PopupMenuItem(
                              value: PayloadFormat.hex,
                              child: Text('HEX'),
                            ),
                          ],
                      child: Container(
                        width: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border.all(color: colors.outline),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _payloadFormat == PayloadFormat.text ? 'TXT' : 'HEX',
                          style: TextStyle(
                            color: colors.primaryDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      preview == null ? '命令或负载格式无效' : HexCodec.format(preview),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: preview == null
                            ? colors.warning
                            : colors.receive,
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const ValueKey<String>('protocol-send'),
                    onPressed: connected && !_sending && preview != null
                        ? () => unawaited(_sendFrame())
                        : null,
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('发送帧'),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ObservationRow extends StatelessWidget {
  const _ObservationRow({required this.observation});

  final ProtocolObservation observation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (icon, text, color) = switch (observation.event) {
      ProtocolFrameReceived(:final command, :final payload) => (
        Icons.check_circle_outline_rounded,
        '命令 0x${command.toRadixString(16).padLeft(2, '0').toUpperCase()}'
            ' · 负载 ${payload.length} 字节',
        colors.receive,
      ),
      ProtocolFrameRejected(:final reason, :final discardedBytes) => (
        Icons.warning_amber_rounded,
        '${_rejectionLabel(reason)} · 丢弃 ${discardedBytes.length} 字节',
        colors.warning,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _rejectionLabel(FrameRejectionReason reason) {
  return switch (reason) {
    FrameRejectionReason.invalidLength => '非法长度',
    FrameRejectionReason.checksumMismatch => '校验失败',
    FrameRejectionReason.invalidFrame => '非法帧',
    FrameRejectionReason.bufferOverflow => '缓冲溢出',
  };
}
