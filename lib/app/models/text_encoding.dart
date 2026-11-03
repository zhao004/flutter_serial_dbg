/// 文本负载和文本日志当前支持的编码方式。
enum TextEncoding {
  utf8('UTF-8'),
  ascii('ASCII');

  const TextEncoding(this.label);

  /// 设置菜单和状态展示使用的名称。
  final String label;
}
