import 'dart:typed_data';

import 'package:signals/signals.dart';

import '../../database/app_repository.dart';
import '../../models/log_entry.dart';
import '../../models/protocol_observation.dart';
import '../../models/protocol_profile.dart';
import '../../services/protocol/serial_protocol.dart';

/// 协议 Profile 管理、实时解析和命令帧编码状态。
class ProtocolController {
  ProtocolController(this._repository);

  final AppRepository _repository;

  /// 用户保存的自定义 Profile。
  final Signal<List<ProtocolProfile>> profiles = signal<List<ProtocolProfile>>(
    <ProtocolProfile>[],
  );

  /// 当前选中 Profile；null 表示尚未选择自定义 Profile。
  final Signal<ProtocolProfile?> selectedProfile = signal<ProtocolProfile?>(
    null,
  );

  /// 最近一次连接会话中的解析结果。
  final Signal<List<ProtocolObservation>> observations =
      signal<List<ProtocolObservation>>(<ProtocolObservation>[]);

  /// 是否正在加载 Profile。
  final Signal<bool> isLoading = signal(false);

  /// 最近一次协议配置或解析错误。
  final Signal<String?> lastError = signal<String?>(null);

  SerialProtocol? _protocol;
  Future<void>? _initialization;
  bool _disposed = false;

  /// 加载自定义 Profile；重复调用复用同一初始化过程。
  Future<void> initialize() {
    return _initialization ??= _load();
  }

  /// 选择 Profile 并重置解析状态。
  void selectProfile(ProtocolProfile? profile) {
    selectedProfile.value = profile;
    _protocol = profile == null
        ? null
        : Aa55SerialProtocol(profile: profile.toFrameProfile());
    observations.value = const <ProtocolObservation>[];
    lastError.value = null;
  }

  /// 根据自定义 Profile 主键选择；null 表示清除当前选择。
  void selectProfileId(int? profileId) {
    if (profileId == null) {
      selectProfile(null);
      return;
    }
    if (profileId <= 0) {
      return;
    }
    for (final profile in profiles.value) {
      if (profile.id == profileId) {
        selectProfile(profile);
        return;
      }
    }
  }

  /// 写入接收字节并累积协议观察结果。
  void addChunk(Uint8List chunk) {
    final protocol = _protocol;
    if (protocol == null || chunk.isEmpty) {
      return;
    }
    try {
      final events = protocol.decode(chunk);
      if (events.isEmpty || _disposed) {
        return;
      }
      final now = DateTime.now();
      final next = <ProtocolObservation>[
        ...observations.value,
        ...events.map(
          (event) => ProtocolObservation(occurredAt: now, event: event),
        ),
      ];
      observations.value = List<ProtocolObservation>.unmodifiable(
        next.length <= 200 ? next : next.sublist(next.length - 200),
      );
    } catch (_) {
      lastError.value = '协议解析失败';
    }
  }

  /// 编码当前 Profile 的命令帧；未选择 Profile 时返回 null。
  Uint8List? encode({required int command, required Uint8List payload}) {
    final protocol = _protocol;
    if (protocol == null) {
      lastError.value = '请先选择协议 Profile';
      return null;
    }
    try {
      final encoded = protocol.encode(command: command, payload: payload);
      lastError.value = null;
      return encoded;
    } catch (error) {
      lastError.value = error is ArgumentError
          ? error.message?.toString() ?? '协议帧参数无效'
          : '协议帧编码失败';
      return null;
    }
  }

  /// 用指定 Profile 重放历史中的接收日志。
  List<ProtocolObservation> decodeEntries(
    Iterable<LogEntry> entries,
    ProtocolProfile profile,
  ) {
    final protocol = Aa55SerialProtocol(profile: profile.toFrameProfile());
    final result = <ProtocolObservation>[];
    for (final entry in entries) {
      if (entry.direction != LogDirection.received) {
        continue;
      }
      for (final event in protocol.decode(entry.copyBytes())) {
        result.add(
          ProtocolObservation(occurredAt: entry.timestamp, event: event),
        );
      }
    }
    return result;
  }

  /// 新增或更新自定义 Profile。
  Future<ProtocolProfile?> saveProfile(ProtocolProfile profile) async {
    try {
      final saved = await _repository.saveProtocolProfile(profile);
      await _reloadProfiles();
      selectProfile(saved);
      return saved;
    } catch (_) {
      lastError.value = '保存协议 Profile 失败';
      return null;
    }
  }

  /// 删除指定自定义 Profile。
  Future<bool> deleteProfile(int profileId) async {
    try {
      await _repository.deleteProtocolProfile(profileId);
      if (selectedProfile.value?.id == profileId) {
        selectProfile(null);
      }
      await _reloadProfiles();
      return true;
    } catch (_) {
      lastError.value = '删除协议 Profile 失败';
      return false;
    }
  }

  /// 清空当前连接会话的解析结果和未完成帧。
  void resetSession() {
    resetParser();
    if (!_disposed) {
      observations.value = const <ProtocolObservation>[];
    }
  }

  /// 丢弃未完成帧，但保留已经解析出的当前会话观察结果。
  void resetParser() {
    _protocol?.reset();
  }

  /// 清除错误。
  void dismissError() {
    lastError.value = null;
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      await _reloadProfiles();
    } finally {
      if (!_disposed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _reloadProfiles() async {
    final loaded = await _repository.loadProtocolProfiles();
    if (_disposed) {
      return;
    }
    profiles.value = List<ProtocolProfile>.unmodifiable(loaded);
    final selectedId = selectedProfile.value?.id;
    ProtocolProfile? replacement;
    if (selectedId != null) {
      for (final profile in loaded) {
        if (profile.id == selectedId) {
          replacement = profile;
          break;
        }
      }
    }
    selectProfile(replacement ?? (loaded.isEmpty ? null : loaded.first));
  }

  /// 释放响应式信号。
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    profiles.dispose();
    selectedProfile.dispose();
    observations.dispose();
    isLoading.dispose();
    lastError.dispose();
  }
}
