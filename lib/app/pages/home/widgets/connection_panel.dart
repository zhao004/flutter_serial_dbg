import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';

import '../../../models/connection_config.dart';
import '../../../models/connection_mode.dart';
import '../../../models/connection_state.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/validators.dart';
import '../../../widgets/app_surface_card.dart';
import '../../../widgets/gradient_primary_button.dart';
import '../home_controller.dart';
import 'connection_panel_header.dart';

/// WiFi 连接参数和生命周期操作面板。
class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({
    super.key,
    required this.controller,
    required this.mode,
  });

  final HomeController controller;
  final ConnectionMode mode;

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hostController.addListener(_handleHostChanged);
    unawaited(_loadSavedConfig(widget.mode));
  }

  @override
  void didUpdateWidget(covariant ConnectionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode) {
      return;
    }
    if (widget.mode.isServer && _hostController.text.trim().isEmpty) {
      _hostController.text = '0.0.0.0';
    } else if (!widget.mode.isServer &&
        _hostController.text.trim() == '0.0.0.0') {
      _hostController.clear();
    }
    unawaited(_loadSavedConfig(widget.mode));
  }

  @override
  void dispose() {
    _hostController
      ..removeListener(_handleHostChanged)
      ..dispose();
    _portController.dispose();
    super.dispose();
  }

  void _handleHostChanged() {
    setState(() {});
  }

  Future<void> _loadSavedConfig(ConnectionMode mode) async {
    final config = await widget.controller.loadSavedConfig(mode);
    if (!mounted ||
        config == null ||
        widget.controller.selectedMode.value != mode) {
      return;
    }
    switch (config) {
      case TcpClientConfig():
        _hostController.text = config.host;
        _portController.text = '${config.port}';
      case TcpServerConfig():
        _hostController.text = config.bindAddress;
        _portController.text = '${config.port}';
      case UdpClientConfig():
        _hostController.text = config.host;
        _portController.text = '${config.port}';
      case UdpServerConfig():
        _hostController.text = config.bindAddress;
        _portController.text = '${config.port}';
      case BleConfig() || UsbSerialConfig():
        return;
    }
  }

  Future<void> _connect(ConnectionMode mode) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final host = _hostController.text.trim();
    final port = parsePortInput(_portController.text);
    if (port == null) {
      return;
    }
    final config = switch (mode) {
      ConnectionMode.tcpClient => TcpClientConfig(host: host, port: port),
      ConnectionMode.tcpServer => TcpServerConfig(
        bindAddress: host,
        port: port,
      ),
      ConnectionMode.udpClient => UdpClientConfig(host: host, port: port),
      ConnectionMode.udpServer => UdpServerConfig(
        bindAddress: host,
        port: port,
      ),
      ConnectionMode.ble || ConnectionMode.usbSerial => null,
    };
    if (config == null) {
      return;
    }
    await widget.controller.connect(config);
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final colors = context.appColors;
        final mode = widget.mode;
        final snapshot = widget.controller.connectionState.value;
        final isConnected = snapshot.status == TransportStatus.connected;
        final isBusy = snapshot.status.isBusy;
        final formLocked = isConnected || isBusy;
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
                _NetworkModeSelector(
                  selected: mode,
                  enabled: !formLocked,
                  onSelected: (selected) {
                    unawaited(widget.controller.selectMode(selected));
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _LabeledField(
                        label: mode.isServer ? '监听地址' : '主机 / IP',
                        child: TextFormField(
                          controller: _hostController,
                          enabled: !formLocked,
                          validator: validateHostInput,
                          decoration: const InputDecoration(
                            hintText: '192.168.1.100',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 104,
                      child: _LabeledField(
                        label: '端口',
                        child: TextFormField(
                          controller: _portController,
                          enabled: !formLocked,
                          validator: validatePortInput,
                          decoration: const InputDecoration(hintText: '8080'),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                    ),
                  ],
                ),
                if (mode.isServer &&
                    _hostController.text.trim() == '0.0.0.0') ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: colors.warning,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '监听 0.0.0.0 将接受所有网卡连接',
                          style: TextStyle(color: colors.warning, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
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
                GradientPrimaryButton(
                  label: isConnected ? '断开' : (mode.isServer ? '开始监听' : '连接'),
                  icon: isConnected
                      ? Icons.link_off_rounded
                      : Icons.link_rounded,
                  isLoading: actionLoading,
                  onPressed: isBusy
                      ? null
                      : isConnected
                      ? () => unawaited(widget.controller.disconnect())
                      : () => unawaited(_connect(mode)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NetworkModeSelector extends StatelessWidget {
  const _NetworkModeSelector({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ConnectionMode selected;
  final bool enabled;
  final ValueChanged<ConnectionMode> onSelected;

  static const List<ConnectionMode> _modes = <ConnectionMode>[
    ConnectionMode.tcpClient,
    ConnectionMode.tcpServer,
    ConnectionMode.udpClient,
    ConnectionMode.udpServer,
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ConnectionMode>(
      key: const ValueKey<String>('network-mode-dropdown'),
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: '连接模式',
        prefixIcon: Icon(Icons.swap_horiz_rounded, size: 20),
      ),
      items: _modes
          .map(
            (mode) => DropdownMenuItem<ConnectionMode>(
              key: ValueKey<String>('network-mode-option-${mode.name}'),
              value: mode,
              child: Text(_label(mode)),
            ),
          )
          .toList(growable: false),
      onChanged: enabled
          ? (mode) {
              if (mode != null) {
                onSelected(mode);
              }
            }
          : null,
    );
  }

  String _label(ConnectionMode mode) {
    return switch (mode) {
      ConnectionMode.tcpClient => 'TCP 客户端',
      ConnectionMode.tcpServer => 'TCP 服务端',
      ConnectionMode.udpClient => 'UDP 客户端',
      ConnectionMode.udpServer => 'UDP 服务端',
      ConnectionMode.ble || ConnectionMode.usbSerial => '',
    };
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

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
