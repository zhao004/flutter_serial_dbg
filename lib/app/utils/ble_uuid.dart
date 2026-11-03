/// 比较短 UUID、32 位 UUID 与完整 128 位 BLE UUID。
bool bleUuidMatches(String? requested, String actual) {
  if (requested == null) {
    return true;
  }
  return normalizeBleUuid(requested) == normalizeBleUuid(actual);
}

/// 将 BLE UUID 归一化为 32 位大写十六进制字符串。
String normalizeBleUuid(String value) {
  var normalized = value
      .trim()
      .toUpperCase()
      .replaceAll('0X', '')
      .replaceAll('-', '');
  if (normalized.length == 4) {
    normalized = '0000${normalized}00001000800000805F9B34FB';
  } else if (normalized.length == 8) {
    normalized = '${normalized}00001000800000805F9B34FB';
  }
  return normalized;
}
