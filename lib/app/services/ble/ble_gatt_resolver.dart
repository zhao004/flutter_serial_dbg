import '../../models/connection_config.dart';
import '../../utils/ble_uuid.dart';
import '../transport/transport.dart';

/// BLE GATT 特征选择所需的平台无关信息。
final class BleGattCharacteristicCandidate<T> {
  const BleGattCharacteristicCandidate({
    required this.value,
    required this.uuid,
    required this.writable,
    required this.notifiable,
  });

  final T value;
  final String uuid;
  final bool writable;
  final bool notifiable;
}

/// BLE GATT 服务及其特征候选集合。
final class BleGattServiceCandidate<S, C> {
  const BleGattServiceCandidate({
    required this.value,
    required this.uuid,
    required this.characteristics,
  });

  final S value;
  final String uuid;
  final List<BleGattCharacteristicCandidate<C>> characteristics;
}

/// GATT 选择结果；只发送模式下通知特征可为空。
final class BleGattSelection<S, C> {
  const BleGattSelection({
    required this.service,
    required this.write,
    required this.notify,
  });

  final BleGattServiceCandidate<S, C> service;
  final BleGattCharacteristicCandidate<C> write;
  final BleGattCharacteristicCandidate<C>? notify;
}

/// 从已发现服务中选择可写特征，并在可用时选择通知特征。
///
/// 通知特征不是发送消息的必要条件。若配置显式指定通知 UUID，则该特征
/// 必须存在，避免静默忽略用户配置。优先返回同时具备写入和通知能力的服务。
/// Generic Access(0x1800) 与 Generic Attribute(0x1801) 不承载应用数据，
/// 自动选择时会排除；历史保存的这两个服务配置也会重新执行自动发现。
BleGattSelection<S, C> resolveBleGatt<S, C>({
  required Iterable<BleGattServiceCandidate<S, C>> services,
  required BleConfig config,
}) {
  final hasStaleInternalService =
      config.serviceUuid != null && _isGattInternalService(config.serviceUuid!);
  final requestedServiceUuid = hasStaleInternalService
      ? null
      : config.serviceUuid;
  final requestedWriteUuid = hasStaleInternalService
      ? null
      : config.writeCharacteristicUuid;
  final requestedNotifyUuid = hasStaleInternalService
      ? null
      : config.notifyCharacteristicUuid;
  final hasExplicitService = requestedServiceUuid != null;
  final filteredServices = services
      .where((service) {
        if (!bleUuidMatches(requestedServiceUuid, service.uuid)) {
          return false;
        }
        return hasExplicitService || !_isGattInternalService(service.uuid);
      })
      .toList(growable: false);
  if (filteredServices.isEmpty) {
    throw const TransportException(
      TransportErrorKind.connection,
      '未找到指定 BLE 服务',
    );
  }

  BleGattSelection<S, C>? firstWritableSelection;
  for (final service in filteredServices) {
    BleGattCharacteristicCandidate<C>? write;
    BleGattCharacteristicCandidate<C>? notify;

    for (final characteristic in service.characteristics) {
      if (write == null &&
          characteristic.writable &&
          bleUuidMatches(requestedWriteUuid, characteristic.uuid)) {
        write = characteristic;
      }
      if (notify == null &&
          characteristic.notifiable &&
          bleUuidMatches(requestedNotifyUuid, characteristic.uuid)) {
        notify = characteristic;
      }
    }

    if (write == null) {
      continue;
    }

    final selection = BleGattSelection<S, C>(
      service: service,
      write: write,
      notify: notify,
    );
    if (notify != null) {
      return selection;
    }
    firstWritableSelection ??= selection;
  }

  if (firstWritableSelection == null) {
    throw const TransportException(
      TransportErrorKind.connection,
      '未找到可写 BLE 特征',
    );
  }
  if (requestedNotifyUuid != null) {
    throw const TransportException(
      TransportErrorKind.connection,
      '未找到通知或指示 BLE 特征',
    );
  }
  return firstWritableSelection;
}

bool _isGattInternalService(String uuid) {
  return bleUuidMatches('1800', uuid) || bleUuidMatches('1801', uuid);
}
