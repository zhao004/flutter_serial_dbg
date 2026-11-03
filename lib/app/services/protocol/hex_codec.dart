import 'dart:convert';
import 'dart:typed_data';

import '../../models/log_entry.dart';
import '../../models/text_encoding.dart';
import '../../utils/constants.dart';

/// 负载格式校验失败的稳定错误码。
enum PayloadFormatError {
  empty,
  oddHexLength,
  invalidHexCharacter,
  inputTooLarge,
  invalidTextEncoding,
}

/// 供控制器映射为本地化提示的负载格式异常。
final class PayloadFormatException extends FormatException {
  PayloadFormatException(this.error, String message) : super(message);

  final PayloadFormatError error;
}

/// 严格 HEX 字节编解码工具。
abstract final class HexCodec {
  /// 将忽略 ASCII 空白后的 HEX 字符串解码为字节。
  static Uint8List decode(String input) {
    final normalized = _stripAsciiWhitespace(input);
    if (normalized.isEmpty) {
      throw PayloadFormatException(PayloadFormatError.empty, 'HEX 负载不能为空');
    }
    if (normalized.length.isOdd) {
      throw PayloadFormatException(
        PayloadFormatError.oddHexLength,
        'HEX 负载必须包含偶数个字符',
      );
    }
    if (normalized.length ~/ 2 > ProtocolLimits.maxPayloadBytes) {
      throw PayloadFormatException(
        PayloadFormatError.inputTooLarge,
        'HEX 负载超过 ${ProtocolLimits.maxPayloadBytes} 字节限制',
      );
    }

    final result = Uint8List(normalized.length ~/ 2);
    for (var index = 0; index < result.length; index++) {
      final high = _hexValue(normalized.codeUnitAt(index * 2));
      final low = _hexValue(normalized.codeUnitAt(index * 2 + 1));
      if (high == null || low == null) {
        throw PayloadFormatException(
          PayloadFormatError.invalidHexCharacter,
          'HEX 负载包含非法字符',
        );
      }
      result[index] = (high << 4) | low;
    }
    return result;
  }

  /// 将字节格式化为大写、空格分隔的 HEX 字符串。
  static String format(List<int> bytes) {
    return bytes
        .map((byte) {
          if (byte < 0 || byte > 0xFF) {
            throw ArgumentError.value(byte, 'bytes', '必须位于 0 到 255 之间');
          }
          return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
        })
        .join(' ');
  }
}

/// 文本与 HEX 发送负载的共享编解码入口。
abstract final class PayloadCodec {
  /// 按指定格式编码输入，并可选追加 CRLF。
  static Uint8List encode(
    String input, {
    required PayloadFormat format,
    TextEncoding textEncoding = TextEncoding.utf8,
    bool appendCrlf = false,
  }) {
    final payload = switch (format) {
      PayloadFormat.text => _encodeText(input, textEncoding),
      PayloadFormat.hex => HexCodec.decode(input),
    };
    final resultLength =
        payload.length + (appendCrlf ? ByteConstants.crlf.length : 0);
    if (resultLength > ProtocolLimits.maxPayloadBytes) {
      throw PayloadFormatException(
        PayloadFormatError.inputTooLarge,
        '负载超过 ${ProtocolLimits.maxPayloadBytes} 字节限制',
      );
    }
    if (!appendCrlf) {
      return payload;
    }

    final result = Uint8List(resultLength)
      ..setRange(0, payload.length, payload)
      ..setRange(payload.length, resultLength, ByteConstants.crlf);
    return result;
  }

  /// 将字节转换为页面展示文本。
  static String format(
    Uint8List bytes, {
    required PayloadFormat format,
    TextEncoding textEncoding = TextEncoding.utf8,
  }) {
    return switch (format) {
      PayloadFormat.text => switch (textEncoding) {
        TextEncoding.utf8 => utf8.decode(bytes, allowMalformed: true),
        TextEncoding.ascii => ascii.decode(bytes, allowInvalid: true),
      },
      PayloadFormat.hex => HexCodec.format(bytes),
    };
  }
}

Uint8List _encodeText(String input, TextEncoding encoding) {
  return switch (encoding) {
    TextEncoding.utf8 => _encodeUtf8(input),
    TextEncoding.ascii => _encodeAscii(input),
  };
}

Uint8List _encodeUtf8(String input) {
  if (input.isEmpty) {
    throw PayloadFormatException(PayloadFormatError.empty, '文本负载不能为空');
  }
  try {
    final result = Uint8List.fromList(utf8.encode(input));
    if (result.length > ProtocolLimits.maxPayloadBytes) {
      throw PayloadFormatException(
        PayloadFormatError.inputTooLarge,
        '负载超过 ${ProtocolLimits.maxPayloadBytes} 字节限制',
      );
    }
    return result;
  } on ArgumentError {
    throw PayloadFormatException(
      PayloadFormatError.invalidTextEncoding,
      '文本包含无法编码的字符',
    );
  }
}

Uint8List _encodeAscii(String input) {
  if (input.isEmpty) {
    throw PayloadFormatException(PayloadFormatError.empty, '文本负载不能为空');
  }
  if (input.codeUnits.any((codeUnit) => codeUnit > 0x7F)) {
    throw PayloadFormatException(
      PayloadFormatError.invalidTextEncoding,
      'ASCII 编码不支持当前字符',
    );
  }
  final result = Uint8List.fromList(input.codeUnits);
  if (result.length > ProtocolLimits.maxPayloadBytes) {
    throw PayloadFormatException(
      PayloadFormatError.inputTooLarge,
      '负载超过 ${ProtocolLimits.maxPayloadBytes} 字节限制',
    );
  }
  return result;
}

String _stripAsciiWhitespace(String input) {
  final buffer = StringBuffer();
  for (final codeUnit in input.codeUnits) {
    if (!_isAsciiWhitespace(codeUnit)) {
      buffer.writeCharCode(codeUnit);
    }
  }
  return buffer.toString();
}

bool _isAsciiWhitespace(int codeUnit) {
  return codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0D;
}

int? _hexValue(int codeUnit) {
  if (codeUnit >= 0x30 && codeUnit <= 0x39) {
    return codeUnit - 0x30;
  }
  if (codeUnit >= 0x41 && codeUnit <= 0x46) {
    return codeUnit - 0x41 + 10;
  }
  if (codeUnit >= 0x61 && codeUnit <= 0x66) {
    return codeUnit - 0x61 + 10;
  }
  return null;
}
