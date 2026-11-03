import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../di/injector.dart';
import '../../models/connection_mode.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/connection_mode_selector.dart';
import '../update/update_controller.dart';
import '../update/update_dialog.dart';
import 'home_controller.dart';
import 'widgets/ble_connection_panel.dart';
import 'widgets/connection_panel.dart';
import 'widgets/diagnostics_dialog.dart';
import 'widgets/terminal_panel.dart';
import 'widgets/usb_connection_panel.dart';

/// 串口、网络与无线设备共用的通信工作台首页。
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController _controller;
  late final UpdateController _updateController;

  @override
  void initState() {
    super.initState();
    _controller = getIt<HomeController>();
    _updateController = getIt<UpdateController>();
    unawaited(_controller.initialize());
    unawaited(_updateController.initialize());
    if (!kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_checkForStartupUpdate());
      });
    }
  }

  Future<void> _checkForStartupUpdate() async {
    final result = await _updateController.checkAtStartup();
    if (!mounted || result?.hasUpdate != true) {
      return;
    }
    await showUpdateDialog(context: context, controller: _updateController);
  }

  Future<void> _selectMode(ConnectionMode mode) {
    return _controller.selectMode(mode);
  }

  void _openDiagnostics() {
    final colors = context.appColors;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: colors.barrier,
      builder: (context) {
        final dialogColors = context.appColors;
        return Dialog(
          backgroundColor: dialogColors.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.sizeOf(context).height * 0.84,
            ),
            child: NetworkDiagnosticsDialog(controller: _controller),
          ),
        );
      },
    );
  }

  void _openSettings() {
    unawaited(context.push<void>(Routes.settings));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyle(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: colors.pageGradient),
          child: CustomPaint(
            painter: _LavenderFieldPainter(colors: colors),
            child: SafeArea(
              bottom: false,
              child: SignalBuilder(
                builder: (context) {
                  final mode = _controller.selectedMode.value;
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      16 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            ErrorToastListener(
                              readError: () => _controller.lastError.value,
                              onShown: _controller.dismissError,
                            ),
                            _WorkspaceHeader(
                              onDiagnostics: _openDiagnostics,
                              onSettings: _openSettings,
                            ),
                            const SizedBox(height: 16),
                            ConnectionModeSelector(
                              selected: mode,
                              onSelected: (selected) {
                                unawaited(_selectMode(selected));
                              },
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: switch (mode) {
                                ConnectionMode.ble => BleConnectionPanel(
                                  key: const ValueKey<String>('ble-panel'),
                                  controller: _controller,
                                ),
                                ConnectionMode.usbSerial => UsbConnectionPanel(
                                  key: const ValueKey<String>('usb-panel'),
                                  controller: _controller,
                                ),
                                _ => ConnectionPanel(
                                  key: ValueKey<String>(
                                    'network-panel-${mode.name}',
                                  ),
                                  controller: _controller,
                                  mode: mode,
                                ),
                              },
                            ),
                            const SizedBox(height: 12),
                            TerminalPanel(controller: _controller),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.onDiagnostics,
    required this.onSettings,
  });

  final VoidCallback onDiagnostics;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: colors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _PulseGlyphPainter(color: colors.onPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '串口调试助手',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 3),
              Text(
                '多协议 · 多连接 · 设备调试工具',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(color: colors.inkMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _HeaderAction(
          tooltip: '网络诊断',
          icon: Icons.network_check_rounded,
          onPressed: onDiagnostics,
        ),
        const SizedBox(width: 8),
        _HeaderAction(
          tooltip: '设置',
          icon: Icons.settings_rounded,
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.headerSurface,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 23, color: colors.ink),
          ),
        ),
      ),
    );
  }
}

class _LavenderFieldPainter extends CustomPainter {
  const _LavenderFieldPainter({required this.colors});

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final topWash = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              colors.decorationPrimary,
              colors.decorationPrimary.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.92, size.height * 0.03),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.03),
      size.width * 0.7,
      topWash,
    );

    final leftWash = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              colors.decorationLight,
              colors.decorationLight.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.02, size.height * 0.5),
              radius: size.width * 0.75,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.02, size.height * 0.5),
      size.width * 0.75,
      leftWash,
    );

    final curve = Path()
      ..moveTo(size.width * 0.42, 0)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.035,
        size.width * 0.86,
        size.height * 0.105,
        size.width,
        size.height * 0.12,
      );
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = colors.decorationLine,
    );
  }

  @override
  bool shouldRepaint(covariant _LavenderFieldPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class _PulseGlyphPainter extends CustomPainter {
  const _PulseGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final centerY = size.height / 2;
    path
      ..moveTo(size.width * 0.18, centerY)
      ..lineTo(size.width * 0.34, centerY)
      ..lineTo(size.width * 0.42, size.height * 0.31)
      ..lineTo(size.width * 0.52, size.height * 0.72)
      ..lineTo(size.width * 0.62, centerY)
      ..lineTo(size.width * 0.82, centerY);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.18, centerY),
      2.4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _PulseGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
