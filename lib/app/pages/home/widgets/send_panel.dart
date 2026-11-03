import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../../models/connection_state.dart';
import '../../../models/log_entry.dart';
import '../../../theme/app_theme.dart';
import '../home_controller.dart';

/// 原始负载输入、发送格式和发送操作面板。
class SendPanel extends StatefulWidget {
  const SendPanel({super.key, required this.controller});

  final HomeController controller;

  @override
  State<SendPanel> createState() => _SendPanelState();
}

class _SendPanelState extends State<SendPanel> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final input = _inputController.text;
    final sent = await widget.controller.sendInput(input);
    if (sent) {
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final colors = context.appColors;
        final format = widget.controller.payloadFormat.value;
        final isSending = widget.controller.isSending.value;
        final isConnected =
            widget.controller.connectionState.value.status ==
            TransportStatus.connected;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: '输入发送内容...',
                  prefixIcon: Icon(
                    Icons.attach_file_rounded,
                    size: 20,
                    color: colors.ink,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 42,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            _SendFormatMenu(
              format: format,
              onSelected: widget.controller.setPayloadFormat,
            ),
            const SizedBox(width: 7),
            _SquareActionButton(
              tooltip: '发送',
              onPressed: isConnected && !isSending
                  ? () => unawaited(_send())
                  : null,
              icon: Icons.send_rounded,
              isLoading: isSending,
              filled: true,
            ),
          ],
        );
      },
    );
  }
}

class _SendFormatMenu extends StatelessWidget {
  const _SendFormatMenu({required this.format, required this.onSelected});

  final PayloadFormat format;
  final ValueChanged<PayloadFormat> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopupMenuButton<PayloadFormat>(
      tooltip: '发送格式',
      initialValue: format,
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) => const <PopupMenuEntry<PayloadFormat>>[
        PopupMenuItem<PayloadFormat>(
          value: PayloadFormat.text,
          child: Text('文本发送'),
        ),
        PopupMenuItem<PayloadFormat>(
          value: PayloadFormat.hex,
          child: Text('HEX 发送'),
        ),
      ],
      child: Container(
        key: const ValueKey<String>('send-format-menu'),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          format == PayloadFormat.text ? 'TXT' : 'HEX',
          style: TextStyle(
            color: colors.primaryDeep,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.filled,
    this.isLoading = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool filled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: filled && enabled ? colors.primaryGradient : null,
            color: filled
                ? enabled
                      ? null
                      : colors.disabledFill
                : colors.surface,
            border: filled ? null : Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Center(
              child: isLoading
                  ? SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 22,
                      color: filled
                          ? enabled
                                ? colors.onPrimary
                                : colors.inkMuted
                          : colors.primary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
