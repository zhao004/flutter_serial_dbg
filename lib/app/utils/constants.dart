/// 协议与输入缓冲的共享上限。
abstract final class ProtocolLimits {
  /// 单次原始发送或接收输入的字节上限。
  static const int maxPayloadBytes = 64 * 1024;

  /// 增量帧解析器允许暂存的最大字节数。
  static const int maxFrameBufferBytes = 64 * 1024;

  /// 临时 AA55 profile 的单字节长度字段上限。
  static const int maxAa55PayloadBytes = 0xFF;
}

/// 协议层常用字节序列。
abstract final class ByteConstants {
  /// 回车与换行符，按顺序追加到文本或 HEX 负载。
  static const List<int> crlf = <int>[0x0D, 0x0A];
}

/// WiFi 传输与诊断的共享参数。
abstract final class NetworkDefaults {
  /// TCP/UDP 建连和监听操作的最长等待时间。
  static const Duration connectTimeout = Duration(seconds: 10);

  /// 单个 UDP 数据报允许发送的最大负载。
  static const int maxUdpPayloadBytes = 65507;

  /// Ping 默认超时时间。
  static const Duration pingTimeout = Duration(seconds: 3);
}

/// 内存日志缓冲上限。
abstract final class LogLimits {
  /// 内存中保留的最大日志条数。
  static const int maxEntries = 5000;

  /// 内存中保留的最大日志字节数。
  static const int maxBytes = 4 * 1024 * 1024;

  /// 单条日志在界面中渲染的最大字符数。
  static const int maxRenderedCharacters = 8192;
}

/// BLE 扫描与连接参数。
abstract final class BleDefaults {
  /// 单次扫描持续时间。
  static const Duration scanTimeout = Duration(seconds: 10);

  /// GATT 连接和服务发现超时时间。
  static const Duration connectTimeout = Duration(seconds: 15);

  /// 连续扫描超过该时间未出现的设备会被移除。
  static const Duration staleDeviceTimeout = Duration(seconds: 10);
}

/// USB 串口枚举、权限确认和参数边界。
abstract final class UsbSerialDefaults {
  /// 系统 USB 权限确认和串口初始化的最长等待时间。
  static const Duration connectTimeout = Duration(seconds: 30);

  /// 单次 USB 串口写入等待设备接收的最长时间。
  static const Duration writeTimeout = Duration(seconds: 5);

  /// 允许输入的波特率下限。
  static const int minBaudRate = 50;

  /// 允许输入的波特率上限。
  static const int maxBaudRate = 4000000;

  /// 常用波特率快捷值。
  static const List<int> commonBaudRates = <int>[
    9600,
    19200,
    38400,
    57600,
    115200,
    230400,
    460800,
    921600,
  ];
}
