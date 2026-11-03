import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../models/ble_device_info.dart';
import '../../utils/constants.dart';

/// BLE 扫描和适配器状态边界。
abstract interface class BleScanner {
  /// 当前扫描结果流。
  Stream<List<BleDeviceInfo>> get results;

  /// 扫描状态流。
  Stream<bool> get isScanning;

  /// 蓝牙适配器是否已开启。
  Future<bool> isAdapterOn();

  /// 开始一次限时扫描。
  Future<void> start({Duration timeout = BleDefaults.scanTimeout});

  /// 停止当前扫描。
  Future<void> stop();

  /// 释放扫描资源。
  Future<void> dispose();
}

/// 基于 FlutterBluePlus 的扫描实现。
final class FlutterBluePlusBleScanner implements BleScanner {
  const FlutterBluePlusBleScanner();

  @override
  Stream<List<BleDeviceInfo>> get results {
    return FlutterBluePlus.scanResults.map(_mapResults);
  }

  @override
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  @override
  Future<bool> isAdapterOn() async {
    final state = await FlutterBluePlus.adapterState.first.timeout(
      BleDefaults.connectTimeout,
    );
    return state == BluetoothAdapterState.on;
  }

  @override
  Future<void> start({Duration timeout = BleDefaults.scanTimeout}) {
    return FlutterBluePlus.startScan(
      timeout: timeout,
      continuousUpdates: true,
      removeIfGone: BleDefaults.staleDeviceTimeout,
      androidUsesFineLocation: false,
    );
  }

  @override
  Future<void> stop() => FlutterBluePlus.stopScan();

  @override
  Future<void> dispose() => stop();

  List<BleDeviceInfo> _mapResults(List<ScanResult> results) {
    final devices = <String, BleDeviceInfo>{};
    for (final result in results) {
      final remoteId = result.device.remoteId.str;
      final advertisedName = result.advertisementData.advName.trim();
      final platformName = result.device.platformName.trim();
      final name = platformName.isNotEmpty ? platformName : advertisedName;
      final candidate = BleDeviceInfo(
        remoteId: remoteId,
        name: name,
        rssi: result.rssi,
      );
      final existing = devices[remoteId];
      if (existing == null || candidate.rssi >= existing.rssi) {
        devices[remoteId] = candidate;
      }
    }
    final sorted = devices.values.toList()
      ..sort((left, right) => right.rssi.compareTo(left.rssi));
    return sorted;
  }
}
