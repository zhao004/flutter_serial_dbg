import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/database/app_repository.dart';
import 'package:flutter_serial_dbg/app/di/injector.dart';
import 'package:flutter_serial_dbg/app/models/appearance_preferences.dart';
import 'package:flutter_serial_dbg/app/models/app_preferences.dart';
import 'package:flutter_serial_dbg/app/models/app_update.dart';
import 'package:flutter_serial_dbg/app/models/ble_device_info.dart';
import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/connection_mode.dart';
import 'package:flutter_serial_dbg/app/models/log_entry.dart';
import 'package:flutter_serial_dbg/app/models/ping_result.dart';
import 'package:flutter_serial_dbg/app/models/text_encoding.dart';
import 'package:flutter_serial_dbg/app/models/usb_serial_device_info.dart';
import 'package:flutter_serial_dbg/app/pages/home/home_controller.dart';
import 'package:flutter_serial_dbg/app/pages/settings/appearance_controller.dart';
import 'package:flutter_serial_dbg/app/pages/update/update_controller.dart';
import 'package:flutter_serial_dbg/app/services/diagnostics/network_diagnostics.dart';
import 'package:flutter_serial_dbg/app/services/ble/ble_permission_service.dart';
import 'package:flutter_serial_dbg/app/services/ble/ble_scanner.dart';
import 'package:flutter_serial_dbg/app/services/logging/log_exporter.dart';
import 'package:flutter_serial_dbg/app/services/update/app_update_service.dart';
import 'package:flutter_serial_dbg/app/services/usb/usb_serial_service.dart';
import 'package:flutter_serial_dbg/app/theme/app_theme.dart';
import 'package:flutter_serial_dbg/app/widgets/app_toast.dart';
import 'package:flutter_serial_dbg/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pub_semver/pub_semver.dart';

const _appDisplayName = '串口调试助手';

void main() {
  setUp(() async {
    await getIt.reset();
    Injector.registerAll();
    await getIt.unregister<NetworkDiagnostics>();
    getIt.registerLazySingleton<NetworkDiagnostics>(
      _FakeNetworkDiagnostics.new,
    );
    await getIt.unregister<AppRepository>();
    getIt.registerLazySingleton<AppRepository>(_FakeAppRepository.new);
    await getIt.unregister<LogExporter>();
    getIt.registerLazySingleton<LogExporter>(_FakeLogExporter.new);
    await getIt.unregister<BleScanner>();
    final scanner = _FakeBleScanner();
    getIt.registerLazySingleton<BleScanner>(() => scanner);
    addTearDown(scanner.dispose);
    await getIt.unregister<BlePermissionService>();
    getIt.registerLazySingleton<BlePermissionService>(
      _FakeBlePermissionService.new,
    );
    await getIt.unregister<UsbSerialService>();
    final usbSerialService = _FakeUsbSerialService();
    getIt.registerLazySingleton<UsbSerialService>(() => usbSerialService);
    addTearDown(usbSerialService.dispose);
    await getIt.unregister<AppUpdateService>();
    final appUpdateService = _FakeAppUpdateService();
    getIt.registerLazySingleton<AppUpdateService>(() => appUpdateService);
    addTearDown(appUpdateService.dispose);
    await getIt.unregister<UpdateController>();
    final updateController = UpdateController(appUpdateService);
    getIt.registerLazySingleton<UpdateController>(
      () => updateController,
      dispose: (controller) => controller.dispose(),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('renders the empty communication workspace at phone size', (
    tester,
  ) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pump();

    expect(find.text(_appDisplayName), findsOneWidget);
    expect(find.text('未连接'), findsOneWidget);
    expect(
      getIt<HomeController>().selectedMode.value,
      ConnectionMode.usbSerial,
    );
    expect(find.text('串口通信'), findsOneWidget);
    expect(find.text('网络通信'), findsOneWidget);
    expect(find.text('无线设备'), findsOneWidget);
    final disconnectedBadge = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('未连接'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final badgeDecoration = disconnectedBadge.decoration as BoxDecoration;
    final colors = tester.element(find.text('未连接')).appColors;
    expect(badgeDecoration.color, colors.surfaceMuted);
    expect(tester.widget<Text>(find.text('未连接')).style?.color, colors.inkMuted);
    expect(find.text('CH340 透传模块'), findsOneWidget);
    expect(find.text('波特率'), findsOneWidget);
    expect(find.text('数据位'), findsOneWidget);
    expect(find.text('停止位'), findsOneWidget);
    expect(find.text('校验位'), findsOneWidget);
    expect(find.text('TCP / UDP'), findsNothing);
    expect(find.text('暂无通信日志'), findsOneWidget);
    expect(find.byTooltip('发送'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens network diagnostics in a dialog', (tester) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(const SerialDebugApp());
    final diagnosticsButton = find.byTooltip('网络诊断');
    expect(
      find.descendant(
        of: diagnosticsButton,
        matching: find.byIcon(Icons.network_check_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(diagnosticsButton);
    await tester.pumpAndSettle();

    expect(find.text('网络诊断'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(
      getIt<HomeController>().selectedMode.value,
      ConnectionMode.usbSerial,
    );
    expect(find.text('本机 IPv4'), findsOneWidget);
    expect(find.text('连通性测试'), findsOneWidget);
    expect(find.text('Ping'), findsOneWidget);
    final targetField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '输入 IP 或域名',
    );
    await tester.tap(find.text('192.0.2.10'));
    await tester.pump();
    expect(
      tester.widget<TextField>(targetField).controller?.text,
      '192.0.2.10',
    );
    await tester.enterText(targetField, '');
    await tester.tap(find.text('Ping'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('请输入 Ping 目标'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches to the BLE connection panel', (tester) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.tap(find.byKey(const ValueKey<String>('mode-wireless')));
    await _settleModeChange(tester);

    expect(find.text('选择 BLE 设备'), findsOneWidget);
    expect(find.text('扫描设备'), findsOneWidget);
    expect(find.byTooltip('权限设置'), findsNothing);
    expect(tester.getSize(find.text('扫描设备')).height, lessThan(24));
    await tester.tap(find.text('扫描设备'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('附近 BLE 设备'), findsOneWidget);
    final scanner = getIt<BleScanner>() as _FakeBleScanner;
    scanner.emitDevices(<BleDeviceInfo>[
      BleDeviceInfo(remoteId: 'AA:BB:CC:DD:EE:01', name: '温湿度计', rssi: -42),
      BleDeviceInfo(remoteId: 'AA:BB:CC:DD:EE:02', name: '', rssi: -68),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('温湿度计'), findsOneWidget);
    expect(find.text('未命名 BLE 设备'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('ble-filter-named')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('温湿度计'), findsOneWidget);
    expect(find.text('未命名 BLE 设备'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('ble-filter-unnamed')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('温湿度计'), findsNothing);
    expect(find.text('未命名 BLE 设备'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('ble-filter-all')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('温湿度计'), findsOneWidget);
    expect(find.text('未命名 BLE 设备'), findsOneWidget);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches to the USB serial panel at phone size', (tester) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(const SerialDebugApp());
    final networkMode = find.byKey(const ValueKey<String>('mode-network'));
    await tester.tap(networkMode);
    await _settleModeChange(tester);
    expect(
      getIt<HomeController>().selectedMode.value,
      ConnectionMode.tcpClient,
    );
    expect(find.text('TCP 客户端'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('mode-serial')));
    await _settleModeChange(tester);

    expect(find.text('CH340 透传模块'), findsOneWidget);
    expect(find.text('波特率'), findsOneWidget);
    expect(find.text('数据位'), findsOneWidget);
    expect(find.text('停止位'), findsOneWidget);
    expect(find.text('校验位'), findsOneWidget);
    expect(find.byTooltip('刷新 USB 设备'), findsOneWidget);
    await tester.tap(find.text('CH340 透传模块'));
    await tester.pumpAndSettle();
    expect(find.text('选择 USB 串口'), findsOneWidget);
    expect(find.text('CH340 透传模块'), findsNWidgets(2));
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects network transports from the dropdown', (tester) async {
    _setViewport(tester, const Size(426, 923));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('mode-network')));
    await _settleModeChange(tester);

    expect(
      getIt<HomeController>().selectedMode.value,
      ConnectionMode.tcpClient,
    );
    expect(find.text('TCP 客户端'), findsOneWidget);
    final dropdown = find.byKey(
      const ValueKey<String>('network-mode-dropdown'),
    );
    expect(dropdown, findsOneWidget);

    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    expect(find.text('TCP 客户端'), findsWidgets);
    expect(find.text('TCP 服务端'), findsOneWidget);
    expect(find.text('UDP 客户端'), findsOneWidget);
    expect(find.text('UDP 服务端'), findsOneWidget);

    await tester.tap(find.text('UDP 服务端').last);
    await _settleModeChange(tester);
    expect(
      getIt<HomeController>().selectedMode.value,
      ConnectionMode.udpServer,
    );
    expect(find.text('UDP 服务端'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens appearance settings from the header', (tester) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.byTooltip('返回'), findsOneWidget);
    expect(find.text('主题模式'), findsOneWidget);
    expect(find.text('主题配色'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('靛蓝'), findsOneWidget);
    expect(find.text('版本更新'), findsOneWidget);
    expect(find.text('当前 1.0.0 (1)'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text(_appDisplayName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes theme mode and preset from settings', (tester) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('settings-theme-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('theme-mode-dark')));
    await tester.pumpAndSettle();

    final controller = getIt<AppearanceController>();
    expect(controller.themeMode.value, AppThemeMode.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('设置'))).brightness,
      Brightness.dark,
    );
    expect(find.text('深色'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('settings-theme-color')),
    );
    await tester.pumpAndSettle();
    expect(find.text('主题配色'), findsOneWidget);
    final searchField = find.byKey(
      const ValueKey<String>('theme-color-search'),
    );
    await tester.enterText(searchField, '暖橙');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('theme-indigoM3')), findsNothing);
    final orangePreset = find.byKey(const ValueKey<String>('theme-orangeM3'));
    expect(orangePreset, findsOneWidget);
    await tester.tap(orangePreset);
    await tester.pumpAndSettle();

    expect(controller.themePreset.value, AppThemePreset.orangeM3);
    expect(
      Theme.of(tester.element(find.text('主题配色'))).colorScheme.primary,
      AppTheme.dark(AppThemePreset.orangeM3).colorScheme.primary,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text(_appDisplayName), findsOneWidget);
  });

  testWidgets('shows available update details from settings', (tester) async {
    _setViewport(tester, const Size(375, 812));
    final service = getIt<AppUpdateService>() as _FakeAppUpdateService;
    service.checkResult = _availableUpdateResult();
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    final updateTile = find.byKey(
      const ValueKey<String>('settings-update-check'),
    );
    await tester.ensureVisible(updateTile);
    await tester.tap(updateTile);
    await tester.pumpAndSettle();

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('v1.1.0'), findsWidgets);
    expect(find.text('修复连接问题'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('update-install')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('update-later')));
    await tester.pumpAndSettle();
    expect(find.text('发现新版本'), findsNothing);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text(_appDisplayName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows update download progress and closes for installation', (
    tester,
  ) async {
    _setViewport(tester, const Size(375, 812));
    final service = getIt<AppUpdateService>() as _FakeAppUpdateService;
    service.checkResult = _availableUpdateResult();
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    final updateTile = find.byKey(
      const ValueKey<String>('settings-update-check'),
    );
    await tester.ensureVisible(updateTile);
    await tester.tap(updateTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('update-install')));
    await tester.pump();

    expect(find.text('正在下载 0%'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('update-cancel-download')),
      findsOneWidget,
    );

    service.installEvents.add(const ApkInstallEvent.downloading(0.5));
    await tester.pump();
    expect(find.text('正在下载 50%'), findsOneWidget);

    service.installEvents.add(const ApkInstallEvent.installing());
    await tester.pumpAndSettle();
    expect(find.text('发现新版本'), findsNothing);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text(_appDisplayName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('follows system brightness in system theme mode', (tester) async {
    _setViewport(tester, const Size(375, 812));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text(_appDisplayName))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters logs by all received and sent directions', (
    tester,
  ) async {
    _setViewport(tester, const Size(426, 923));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    getIt<HomeController>().logs.value = <LogEntry>[
      LogEntry(
        timestamp: DateTime.utc(2026, 11, 2, 12),
        direction: LogDirection.received,
        format: PayloadFormat.text,
        channel: 'usb',
        bytes: Uint8List.fromList('RX-ONLY'.codeUnits),
      ),
      LogEntry(
        timestamp: DateTime.utc(2026, 11, 2, 12, 1),
        direction: LogDirection.sent,
        format: PayloadFormat.text,
        channel: 'usb',
        bytes: Uint8List.fromList('TX-ONLY'.codeUnits),
      ),
      LogEntry(
        timestamp: DateTime.utc(2026, 11, 2, 12, 2),
        direction: LogDirection.system,
        format: PayloadFormat.text,
        channel: 'system',
        bytes: Uint8List.fromList('SYSTEM-ONLY'.codeUnits),
      ),
    ];
    await tester.pumpAndSettle();

    final filterButton = find.byTooltip('筛选日志');
    await tester.ensureVisible(filterButton);
    await tester.pumpAndSettle();
    await tester.tap(filterButton);
    await tester.pumpAndSettle();

    expect(find.text('全部'), findsOneWidget);
    expect(find.text('接收'), findsOneWidget);
    expect(find.text('发送'), findsOneWidget);

    await tester.tap(find.text('接收'));
    await tester.pumpAndSettle();
    expect(find.text('RX-ONLY'), findsOneWidget);
    expect(find.text('TX-ONLY'), findsNothing);
    expect(find.text('SYSTEM-ONLY'), findsNothing);

    await tester.tap(filterButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('发送'));
    await tester.pumpAndSettle();
    expect(find.text('RX-ONLY'), findsNothing);
    expect(find.text('TX-ONLY'), findsOneWidget);
    expect(find.text('SYSTEM-ONLY'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows search only in the full screen log viewer', (
    tester,
  ) async {
    _setViewport(tester, const Size(426, 923));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    getIt<HomeController>().logs.value = <LogEntry>[
      LogEntry(
        timestamp: DateTime.utc(2026, 11, 2, 12),
        direction: LogDirection.sent,
        format: PayloadFormat.text,
        channel: 'usb',
        bytes: Uint8List.fromList('HELLO'.codeUnits),
      ),
    ];
    await tester.pumpAndSettle();

    expect(find.text('通信日志'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('log-count')), findsOneWidget);
    expect(find.byTooltip('搜索日志'), findsNothing);
    final viewport = find.byKey(const ValueKey<String>('log-viewport'));
    final exportButton = find.byTooltip('导出日志');
    final clearButton = find.byTooltip('清空日志');
    await tester.ensureVisible(exportButton);
    await tester.pumpAndSettle();
    final textFormat = find.byKey(
      const ValueKey<String>('receive-format-text'),
    );
    final hexFormat = find.byKey(const ValueKey<String>('receive-format-hex'));
    final encodingMenu = find.byKey(const ValueKey<String>('encoding-menu'));
    final crlfControl = find.byKey(const ValueKey<String>('crlf-control'));
    final formatToggle = find.byKey(
      const ValueKey<String>('receive-format-toggle'),
    );
    expect(
      tester.getSize(encodingMenu).height,
      tester.getSize(formatToggle).height,
    );
    final toolbarCenterY = tester.getCenter(exportButton).dy;
    for (final control in <Finder>[
      textFormat,
      hexFormat,
      encodingMenu,
      crlfControl,
      clearButton,
    ]) {
      expect(tester.getCenter(control).dy, closeTo(toolbarCenterY, 1.5));
    }
    final orderedControls = <Finder>[
      textFormat,
      hexFormat,
      encodingMenu,
      crlfControl,
      exportButton,
      clearButton,
    ];
    for (var index = 1; index < orderedControls.length; index++) {
      expect(
        tester.getCenter(orderedControls[index]).dx,
        greaterThan(tester.getCenter(orderedControls[index - 1]).dx),
      );
    }
    final actionGap =
        tester.getCenter(clearButton).dx -
        tester.getCenter(exportButton).dx -
        (tester.getSize(exportButton).width +
                tester.getSize(clearButton).width) /
            2;
    expect(actionGap, greaterThanOrEqualTo(5.5));
    expect(
      tester.getCenter(exportButton).dx,
      greaterThan(tester.getCenter(viewport).dx),
    );
    expect(
      tester.getCenter(clearButton).dx,
      greaterThan(tester.getCenter(viewport).dx),
    );
    expect(
      tester.getCenter(exportButton).dy,
      greaterThan(tester.getBottomLeft(viewport).dy),
    );

    final fullScreenButton = find.byTooltip('全屏查看日志');
    await tester.ensureVisible(fullScreenButton);
    await tester.tap(fullScreenButton);
    await tester.pumpAndSettle();

    expect(find.byTooltip('关闭全屏日志'), findsOneWidget);
    final searchButton = find.byTooltip('搜索日志');
    expect(searchButton, findsOneWidget);
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '搜索日志内容',
    );
    await tester.enterText(searchField, 'missing');
    await tester.pump();
    expect(find.text('未找到匹配日志'), findsOneWidget);

    await tester.enterText(searchField, 'hello');
    await tester.pump();
    expect(find.text('HELLO'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows transient feedback as a toast', (tester) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    getIt<HomeController>().logs.value = <LogEntry>[
      LogEntry(
        timestamp: DateTime.utc(2026, 11, 2, 12),
        direction: LogDirection.sent,
        format: PayloadFormat.text,
        channel: 'usb',
        bytes: Uint8List.fromList('TOAST'.codeUnits),
      ),
    ];
    await tester.pumpAndSettle();

    final exportButton = find.byTooltip('导出日志');
    await tester.ensureVisible(exportButton);
    await tester.pumpAndSettle();
    await tester.tap(exportButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('日志已导出'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps only the latest three toasts', (tester) async {
    _setViewport(tester, const Size(375, 812));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.text(_appDisplayName));
    for (var index = 1; index <= 4; index++) {
      AppToast.info(context, '提示$index');
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('提示1'), findsNothing);
    expect(find.text('提示2'), findsOneWidget);
    expect(find.text('提示3'), findsOneWidget);
    expect(find.text('提示4'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps send format independent from receive display format', (
    tester,
  ) async {
    _setViewport(tester, const Size(426, 923));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    final controller = getIt<HomeController>();
    expect(controller.payloadFormat.value, PayloadFormat.text);
    expect(find.text('TXT'), findsOneWidget);
    final sendFormatButton = find.byTooltip('发送格式');
    final sendFormatMenu = find.byKey(
      const ValueKey<String>('send-format-menu'),
    );
    final sendButton = find.byTooltip('发送');
    await tester.ensureVisible(sendFormatButton);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(sendFormatMenu).height,
      tester.getSize(sendButton).height,
    );
    await tester.tap(sendFormatButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('HEX 发送'));
    await tester.pumpAndSettle();

    expect(controller.payloadFormat.value, PayloadFormat.hex);
    expect(controller.receiveFormat.value, PayloadFormat.text);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches receive format without grey tap states', (
    tester,
  ) async {
    _setViewport(tester, const Size(426, 923));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    final controller = getIt<HomeController>();
    final hexOption = find.byKey(const ValueKey<String>('receive-format-hex'));
    final textOption = find.byKey(
      const ValueKey<String>('receive-format-text'),
    );
    await tester.ensureVisible(hexOption);
    await tester.tap(hexOption);
    await tester.pumpAndSettle();

    expect(controller.receiveFormat.value, PayloadFormat.hex);
    final hexBackground =
        tester
                .widget<Container>(
                  find.descendant(
                    of: hexOption,
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration;
    final textBackground =
        tester
                .widget<Container>(
                  find.descendant(
                    of: textOption,
                    matching: find.byType(Container),
                  ),
                )
                .decoration
            as BoxDecoration;
    final colors = tester.element(hexOption).appColors;
    expect(hexBackground.color, colors.primarySoft);
    expect(textBackground.color, colors.surface);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes the active text encoding from the encoding menu', (
    tester,
  ) async {
    _setViewport(tester, const Size(426, 923));
    await tester.pumpWidget(const SerialDebugApp());
    await tester.pumpAndSettle();

    final controller = getIt<HomeController>();
    final encodingMenu = find.byTooltip('选择编码');
    await tester.ensureVisible(encodingMenu);
    await tester.tap(encodingMenu);
    await tester.pumpAndSettle();

    expect(find.text('UTF-8'), findsNWidgets(2));
    expect(find.text('ASCII'), findsOneWidget);
    await tester.tap(find.text('ASCII'));
    await tester.pumpAndSettle();

    expect(controller.textEncoding.value, TextEncoding.ascii);
    expect(find.text('ASCII'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _settleModeChange(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
}

final class _FakeBleScanner implements BleScanner {
  final StreamController<List<BleDeviceInfo>> _results =
      StreamController<List<BleDeviceInfo>>.broadcast();
  final StreamController<bool> _scanning = StreamController<bool>.broadcast();

  @override
  Stream<bool> get isScanning => _scanning.stream;

  @override
  Stream<List<BleDeviceInfo>> get results => _results.stream;

  @override
  Future<bool> isAdapterOn() async => true;

  @override
  Future<void> start({Duration timeout = const Duration(seconds: 10)}) async {
    _scanning.add(true);
  }

  void emitDevices(List<BleDeviceInfo> devices) {
    _results.add(devices);
  }

  @override
  Future<void> stop() async {
    if (!_scanning.isClosed) {
      _scanning.add(false);
    }
  }

  @override
  Future<void> dispose() async {
    await _results.close();
    await _scanning.close();
  }
}

final class _FakeBlePermissionService implements BlePermissionService {
  @override
  Future<BlePermissionOutcome> request() async {
    return BlePermissionOutcome.granted;
  }

  @override
  Future<bool> openSettings() async => true;
}

final class _FakeUsbSerialService implements UsbSerialService {
  final StreamController<UsbSerialDeviceEvent> _events =
      StreamController<UsbSerialDeviceEvent>.broadcast();
  bool _disposed = false;

  @override
  Stream<UsbSerialDeviceEvent> get events => _events.stream;

  @override
  Future<List<UsbSerialDeviceInfo>> listDevices() async {
    return <UsbSerialDeviceInfo>[
      UsbSerialDeviceInfo(
        deviceId: '/dev/bus/usb/001/012',
        deviceName: '/dev/bus/usb/001/012',
        vendorId: 0x1A86,
        productId: 0x7523,
        productName: 'CH340 透传模块',
      ),
    ];
  }

  @override
  Future<UsbSerialConnection> open(UsbSerialConfig config) async {
    throw const UsbSerialException('测试未配置串口连接');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _events.close();
  }
}

final class _FakeAppRepository implements AppRepository {
  AppearancePreferences appearance = const AppearancePreferences();

  @override
  Future<void> appendLogEntries(
    int sessionId,
    Iterable<LogEntry> entries,
  ) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> endLogSession(int sessionId, DateTime endedAt) async {}

  @override
  Future<ConnectionConfig?> loadConnectionConfig(ConnectionMode mode) async {
    return null;
  }

  @override
  Future<AppPreferences> loadPreferences() async {
    return const AppPreferences();
  }

  @override
  Future<AppearancePreferences> loadAppearancePreferences() async {
    return appearance;
  }

  @override
  Future<List<LogEntry>> loadSessionEntries(int sessionId) async {
    return const <LogEntry>[];
  }

  @override
  Future<void> saveConnectionConfig(ConnectionConfig config) async {}

  @override
  Future<void> savePreferences(AppPreferences preferences) async {}

  @override
  Future<void> saveAppearancePreferences(
    AppearancePreferences preferences,
  ) async {
    appearance = preferences;
  }

  @override
  Future<int> startLogSession(ConnectionMode mode, DateTime startedAt) async {
    return 1;
  }

  @override
  Future<void> trimLogSessions({int keep = 20}) async {}
}

final class _FakeLogExporter implements LogExporter {
  @override
  Future<String?> export(
    List<LogEntry> entries, {
    required PayloadFormat format,
  }) async {
    return '/tmp/serial-debug.log';
  }
}

final class _FakeNetworkDiagnostics implements NetworkDiagnostics {
  @override
  Future<List<String>> localIpv4Addresses() async {
    return const <String>['192.0.2.10'];
  }

  @override
  Future<PingResult> ping(
    String host, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    return PingResult(
      target: host,
      status: PingStatus.success,
      duration: const Duration(milliseconds: 10),
    );
  }
}

UpdateCheckResult _availableUpdateResult() {
  const installed = InstalledAppInfo(
    version: '1.0.0',
    buildNumber: '1',
    packageName: 'com.zhao.serial.dbg',
  );
  return UpdateCheckResult(
    installed: installed,
    update: AvailableUpdate(
      version: Version.parse('1.1.0'),
      tagName: 'v1.1.0',
      releaseNotes: '修复连接问题',
      asset: UpdateAsset(
        abi: 'arm64-v8a',
        fileName: 'serialdbg-v1.1.0-arm64-v8a.apk',
        downloadUri: Uri.parse(
          'https://github.com/zhao004/flutter_serial_dbg/releases/download/v1.1.0/serialdbg-v1.1.0-arm64-v8a.apk',
        ),
        sizeBytes: 8 * 1024 * 1024,
        sha256: 'a' * 64,
      ),
    ),
  );
}

final class _FakeAppUpdateService implements AppUpdateService {
  UpdateCheckResult? checkResult;
  final StreamController<ApkInstallEvent> installEvents =
      StreamController<ApkInstallEvent>();

  @override
  Future<InstalledAppInfo> installedInfo() async {
    return const InstalledAppInfo(
      version: '1.0.0',
      buildNumber: '1',
      packageName: 'com.zhao.serial.dbg',
    );
  }

  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    return checkResult ??
        const UpdateCheckResult(
          installed: InstalledAppInfo(
            version: '1.0.0',
            buildNumber: '1',
            packageName: 'com.zhao.serial.dbg',
          ),
        );
  }

  @override
  Stream<ApkInstallEvent> install(AvailableUpdate update) {
    return installEvents.stream;
  }

  @override
  Future<void> cancelDownload() async {}

  @override
  Future<bool> canRequestPackageInstalls() async => true;

  @override
  Future<bool> openInstallPermissionSettings() async => true;

  void dispose() {
    unawaited(installEvents.close());
  }
}
