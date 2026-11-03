import 'package:material_ui/material_ui.dart';

import '../models/connection_mode.dart';
import '../theme/app_theme.dart';
import 'app_surface_card.dart';

/// 三类传输方式的主模式选择器。
///
/// 网络族内部的具体 TCP/UDP 模式由连接配置面板维护，切换同一族不会重置
/// 用户已经选择的网络子模式。
class ConnectionModeSelector extends StatelessWidget {
  const ConnectionModeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// 当前连接模式。
  final ConnectionMode selected;

  /// 用户切换传输族时的回调。
  final ValueChanged<ConnectionMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final family = _ModeFamily.fromMode(selected);
    return AppSurfaceCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 17,
      showShadow: false,
      child: Row(
        children: _ModeFamily.values
            .map((item) {
              return Expanded(
                child: _ModeSegment(
                  family: item,
                  selected: family == item,
                  onTap: () {
                    if (family == item) {
                      return;
                    }
                    onSelected(item.mode);
                  },
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

enum _ModeFamily {
  serial(
    label: '串口通信',
    icon: Icons.usb_rounded,
    mode: ConnectionMode.usbSerial,
  ),
  network(
    label: '网络通信',
    icon: Icons.wifi_rounded,
    mode: ConnectionMode.tcpClient,
  ),
  wireless(
    label: '无线设备',
    icon: Icons.bluetooth_rounded,
    mode: ConnectionMode.ble,
  );

  const _ModeFamily({
    required this.label,
    required this.icon,
    required this.mode,
  });

  factory _ModeFamily.fromMode(ConnectionMode mode) {
    return switch (mode) {
      ConnectionMode.usbSerial => serial,
      ConnectionMode.ble => wireless,
      _ => network,
    };
  }

  final String label;
  final IconData icon;
  final ConnectionMode mode;
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final _ModeFamily family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label: family.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey<String>('mode-${family.name}'),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 46,
            decoration: BoxDecoration(
              gradient: selected ? colors.primaryGradient : null,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  family.icon,
                  size: 20,
                  color: selected ? colors.onPrimary : colors.ink,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    family.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: selected ? colors.onPrimary : colors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
