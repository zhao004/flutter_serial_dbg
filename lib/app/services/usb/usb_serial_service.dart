import 'dart:async';
import 'dart:typed_data';

import 'package:skio_usb_serial/skio_usb_serial.dart';

import '../../models/connection_config.dart';
import '../../models/usb_serial_device_info.dart';
import '../../utils/constants.dart';

/// USB 设备插拔事件类型。
enum UsbSerialDeviceEventType { attached, detached }

/// 已插入或已拔出的 USB 串口设备摘要。
final class UsbSerialDeviceEvent {
  const UsbSerialDeviceEvent({required this.type, required this.device});

  final UsbSerialDeviceEventType type;
  final UsbSerialDeviceInfo device;
}

/// 不向传输层暴露插件异常细节的 USB 串口错误。
final class UsbSerialException implements Exception {
  const UsbSerialException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 已打开的 USB 串口连接。
abstract interface class UsbSerialConnection {
  /// 不包含设备序列号的连接摘要。
  String get endpoint;

  /// 串口接收字节流。
  Stream<Uint8List> get inputStream;

  /// 写入一段原始字节。
  Future<void> write(Uint8List data);

  /// 幂等关闭底层串口句柄。
  Future<void> close();
}

/// USB 串口枚举、权限申请和端口创建边界。
abstract interface class UsbSerialService {
  /// USB 设备插拔事件流。
  Stream<UsbSerialDeviceEvent> get events;

  /// 枚举当前连接的 USB 串口。
  Future<List<UsbSerialDeviceInfo>> listDevices();

  /// 申请设备权限并创建串口。
  Future<UsbSerialConnection> open(UsbSerialConfig config);

  /// 释放服务资源。
  Future<void> dispose();
}

/// 基于 skio_usb_serial 的 Android USB Host 实现。
final class FlutterUsbSerialService implements UsbSerialService {
  FlutterUsbSerialService()
    : _events = UsbSerialPort.events.map(_mapDeviceEvent).asBroadcastStream();

  final Stream<UsbSerialDeviceEvent> _events;

  @override
  Stream<UsbSerialDeviceEvent> get events => _events;

  @override
  Future<List<UsbSerialDeviceInfo>> listDevices() async {
    try {
      final devices = await UsbSerialPort.list();
      final mapped = devices.map(_mapDevice).toList(growable: false)
        ..sort((left, right) {
          final nameResult = left.displayName.compareTo(right.displayName);
          return nameResult != 0
              ? nameResult
              : left.deviceId.compareTo(right.deviceId);
        });
      return mapped;
    } on HardwareException catch (error) {
      throw UsbSerialException(_mapHardwareError(error));
    } catch (_) {
      throw const UsbSerialException('读取 USB 设备列表失败');
    }
  }

  @override
  Future<UsbSerialConnection> open(UsbSerialConfig config) async {
    final opening = _openPort(config);
    try {
      return await opening.timeout(UsbSerialDefaults.connectTimeout);
    } on TimeoutException {
      unawaited(_closeLateConnection(opening));
      throw const UsbSerialException('USB 权限确认或串口打开超时');
    } on UsbSerialException {
      rethrow;
    } on HardwareException catch (error) {
      throw UsbSerialException(_mapHardwareError(error));
    } catch (_) {
      throw const UsbSerialException('USB 串口打开失败');
    }
  }

  Future<UsbSerialConnection> _openPort(UsbSerialConfig config) async {
    DeviceHandle? selected;
    for (final device in await UsbSerialPort.list()) {
      if (device.id == config.deviceId) {
        selected = device;
        break;
      }
    }
    if (selected == null) {
      throw const UsbSerialException('USB 串口设备已断开，请重新选择');
    }

    var access = await UsbSerialPort.access.checkAccess(selected);
    if (!access.isUsable) {
      access = await UsbSerialPort.access.requestAccess(selected);
    }
    if (!access.isUsable) {
      throw UsbSerialException(_mapAccessStatus(access.status));
    }

    final port = await UsbSerialPort.open(
      selected,
      config: SerialConfig(
        baudRate: config.baudRate,
        dataBits: config.dataBits,
        parity: mapUsbParity(config.parity),
        stopBits: mapUsbStopBits(config.stopBits),
      ),
      writeTimeout: UsbSerialDefaults.writeTimeout,
    );
    return _SkioUsbSerialConnection(port: port, device: _mapDevice(selected));
  }

  @override
  Future<void> dispose() async {}

  Future<void> _closeLateConnection(
    Future<UsbSerialConnection> connection,
  ) async {
    try {
      final lateConnection = await connection;
      await lateConnection.close();
    } catch (_) {
      // 超时后的插件操作失败或成功都不应覆盖原始超时提示。
    }
  }
}

/// 将停止位映射为 skio 串口参数。
StopBits mapUsbStopBits(UsbStopBits value) {
  return switch (value) {
    UsbStopBits.one => StopBits.one,
    UsbStopBits.onePointFive => StopBits.onePointFive,
    UsbStopBits.two => StopBits.two,
  };
}

/// 将校验位映射为 skio 串口参数。
Parity mapUsbParity(UsbParity value) {
  return switch (value) {
    UsbParity.none => Parity.none,
    UsbParity.odd => Parity.odd,
    UsbParity.even => Parity.even,
    UsbParity.mark => Parity.mark,
    UsbParity.space => Parity.space,
  };
}

UsbSerialDeviceEvent _mapDeviceEvent(DeviceEvent event) {
  return UsbSerialDeviceEvent(
    type: switch (event) {
      DeviceAttached() => UsbSerialDeviceEventType.attached,
      DeviceDetached() => UsbSerialDeviceEventType.detached,
    },
    device: _mapDevice(event.device),
  );
}

UsbSerialDeviceInfo _mapDevice(DeviceHandle device) {
  return UsbSerialDeviceInfo(
    deviceId: device.id,
    deviceName: device.id,
    vendorId: device.vendorId,
    productId: device.productId,
    productName: device.name,
    interfaceCount: device.interfaceClasses.isEmpty
        ? null
        : device.interfaceClasses.length,
  );
}

String _mapAccessStatus(AccessStatus status) {
  return switch (status) {
    AccessStatus.granted || AccessStatus.notRequired => 'USB 串口权限不可用',
    AccessStatus.denied => 'USB 权限被拒绝，无法打开串口',
    AccessStatus.permanentlyDenied => 'USB 权限已被永久拒绝，请在系统设置中授权',
    AccessStatus.restricted => 'USB 串口权限受系统策略限制',
    AccessStatus.unsupported => '当前设备或系统不支持 USB 串口',
  };
}

String _mapHardwareError(HardwareException error) {
  return switch (error) {
    AccessDenied() => 'USB 权限被拒绝，无法打开串口',
    DeviceBusy() => '串口打开失败，设备可能被其他应用占用',
    DeviceNotFound() || Disconnected() => 'USB 串口设备已断开，请重新选择',
    OperationTimeout() => 'USB 串口操作超时',
    Unsupported() => '当前 USB 串口或系统不支持所选参数',
    ProtocolError() => 'USB 串口通信协议错误',
  };
}

final class _SkioUsbSerialConnection implements UsbSerialConnection {
  _SkioUsbSerialConnection({
    required this._port,
    required UsbSerialDeviceInfo device,
  }) : _endpoint = '${device.displayName} (${device.hardwareId})';

  final UsbSerialPort _port;
  final String _endpoint;
  bool _closed = false;

  @override
  String get endpoint => _endpoint;

  @override
  Stream<Uint8List> get inputStream => _port.input;

  @override
  Future<void> write(Uint8List data) async {
    try {
      await _port.write(data);
    } on HardwareException catch (error) {
      throw UsbSerialException(_mapHardwareError(error));
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await _port.close();
    } catch (_) {
      // 设备拔出后插件关闭可能失败，但本地句柄仍需视为已释放。
    }
  }
}
