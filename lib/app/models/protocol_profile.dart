import 'dart:collection';

import '../services/protocol/serial_protocol.dart';

/// 可配置的单字节长度、XOR 校验协议帧描述。
final class ProtocolProfile {
  ProtocolProfile({
    this.id,
    required String name,
    required List<int> header,
    this.commandOffset = 2,
    this.lengthOffset = 3,
    this.payloadOffset = 4,
    this.checksumStartOffset = 2,
    this.maxPayloadBytes = 255,
  }) : name = _validateName(name),
       header = UnmodifiableListView<int>(List<int>.from(header)) {
    if (id != null && id! <= 0) {
      throw ArgumentError.value(id, 'id', '必须大于 0');
    }
    if (this.header.isEmpty || this.header.length > 32) {
      throw ArgumentError.value(header, 'header', '长度必须位于 1 到 32 字节');
    }
    if (this.header.any((byte) => byte < 0 || byte > 0xFF)) {
      throw ArgumentError.value(header, 'header', '必须由单字节值组成');
    }
    if (commandOffset < this.header.length ||
        lengthOffset < this.header.length ||
        payloadOffset < this.header.length) {
      throw ArgumentError('命令、长度和负载偏移必须位于帧头之后');
    }
    if (commandOffset == lengthOffset || payloadOffset != lengthOffset + 1) {
      throw ArgumentError('长度字段必须紧邻负载，且不能与命令字段重叠');
    }
    if (checksumStartOffset < 0 || checksumStartOffset >= payloadOffset) {
      throw ArgumentError.value(
        checksumStartOffset,
        'checksumStartOffset',
        '校验起始位置无效',
      );
    }
    if (maxPayloadBytes <= 0 || maxPayloadBytes > 0xFF) {
      throw ArgumentError.value(
        maxPayloadBytes,
        'maxPayloadBytes',
        '必须位于 1 到 255 之间',
      );
    }
  }

  final int? id;
  final String name;
  final UnmodifiableListView<int> header;
  final int commandOffset;
  final int lengthOffset;
  final int payloadOffset;
  final int checksumStartOffset;
  final int maxPayloadBytes;

  /// 转换为现有增量帧解析器配置。
  Aa55FrameProfile toFrameProfile() {
    return Aa55FrameProfile(
      header: header,
      commandOffset: commandOffset,
      lengthOffset: lengthOffset,
      payloadOffset: payloadOffset,
      checksumStartOffset: checksumStartOffset,
      maxPayloadBytes: maxPayloadBytes,
    );
  }

  /// 返回带数据库主键的副本。
  ProtocolProfile withId(int value) {
    return ProtocolProfile(
      id: value,
      name: name,
      header: header,
      commandOffset: commandOffset,
      lengthOffset: lengthOffset,
      payloadOffset: payloadOffset,
      checksumStartOffset: checksumStartOffset,
      maxPayloadBytes: maxPayloadBytes,
    );
  }
}

String _validateName(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'name', '不能为空');
  }
  if (normalized.length > 40) {
    throw ArgumentError.value(value, 'name', '不能超过 40 个字符');
  }
  return normalized;
}
