import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../di/injector.dart';
import '../../models/protocol_profile.dart';
import '../../services/protocol/hex_codec.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_surface_card.dart';
import '../../widgets/app_toast.dart';
import 'protocol_controller.dart';

/// 用户自定义协议 Profile 的增删改页面。
class ProtocolProfilesPage extends StatefulWidget {
  const ProtocolProfilesPage({super.key});

  @override
  State<ProtocolProfilesPage> createState() => _ProtocolProfilesPageState();
}

class _ProtocolProfilesPageState extends State<ProtocolProfilesPage> {
  late final ProtocolController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ProtocolController>();
    unawaited(_controller.initialize());
  }

  Future<void> _openEditor([ProtocolProfile? profile]) async {
    final colors = context.appColors;
    final saved = await showModalBottomSheet<ProtocolProfile>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      barrierColor: colors.barrier,
      builder: (context) => _ProtocolProfileEditor(initial: profile),
    );
    if (saved == null || !mounted) {
      return;
    }
    final result = await _controller.saveProfile(saved);
    if (!mounted) {
      return;
    }
    if (result == null) {
      AppToast.error(context, '保存协议 Profile 失败');
    } else {
      AppToast.success(context, '协议 Profile 已保存');
    }
  }

  Future<void> _delete(ProtocolProfile profile) async {
    final id = profile.id;
    if (id == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除协议 Profile'),
        content: Text('确定删除“${profile.name}”吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final deleted = await _controller.deleteProfile(id);
    if (!mounted) {
      return;
    }
    if (deleted) {
      AppToast.success(context, '协议 Profile 已删除');
    } else {
      AppToast.error(context, '删除协议 Profile 失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SignalBuilder(
      builder: (context) {
        final profiles = _controller.profiles.value;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: '返回',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: const Text('协议 Profile'),
            actions: <Widget>[
              IconButton(
                tooltip: '新增协议 Profile',
                onPressed: () => unawaited(_openEditor()),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: colors.pageGradient),
            child: SafeArea(
              top: false,
              child: Column(
                children: <Widget>[
                  ErrorToastListener(
                    readError: () => _controller.lastError.value,
                    onShown: _controller.dismissError,
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        24 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      children: <Widget>[
                        if (profiles.isEmpty)
                          AppSurfaceCard(
                            child: Column(
                              children: <Widget>[
                                Icon(
                                  Icons.rule_folder_outlined,
                                  size: 48,
                                  color: colors.mutedIcon,
                                ),
                                const SizedBox(height: 10),
                                const Text('暂无自定义协议 Profile'),
                                const SizedBox(height: 6),
                                Text(
                                  '新增后可在首页解析接收帧并组装发送帧。',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colors.inkMuted),
                                ),
                              ],
                            ),
                          )
                        else
                          for (final profile in profiles) ...<Widget>[
                            _CustomProfileTile(
                              profile: profile,
                              onEdit: () => unawaited(_openEditor(profile)),
                              onDelete: () => unawaited(_delete(profile)),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomProfileTile extends StatelessWidget {
  const _CustomProfileTile({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  final ProtocolProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _ProfileTile(
      profile: profile,
      badge: '自定义',
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.badge,
    required this.onEdit,
    required this.onDelete,
  });

  final ProtocolProfile profile;
  final String badge;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppSurfaceCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.data_object_rounded, color: colors.primaryDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.name,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$badge · 帧头 ${HexCodec.format(profile.header)} · '
                  'XOR 校验',
                  style: TextStyle(color: colors.inkMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: '编辑',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: '删除',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
    );
  }
}

class _ProtocolProfileEditor extends StatefulWidget {
  const _ProtocolProfileEditor({this.initial});

  final ProtocolProfile? initial;

  @override
  State<_ProtocolProfileEditor> createState() => _ProtocolProfileEditorState();
}

class _ProtocolProfileEditorState extends State<_ProtocolProfileEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _headerController;
  late final TextEditingController _commandController;
  late final TextEditingController _lengthController;
  late final TextEditingController _payloadController;
  late final TextEditingController _checksumController;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '自定义协议');
    _headerController = TextEditingController(
      text: HexCodec.format(initial?.header ?? const <int>[0xAA, 0x55]),
    );
    _commandController = TextEditingController(
      text: '${initial?.commandOffset ?? 2}',
    );
    _lengthController = TextEditingController(
      text: '${initial?.lengthOffset ?? 3}',
    );
    _payloadController = TextEditingController(
      text: '${initial?.payloadOffset ?? 4}',
    );
    _checksumController = TextEditingController(
      text: '${initial?.checksumStartOffset ?? 2}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headerController.dispose();
    _commandController.dispose();
    _lengthController.dispose();
    _payloadController.dispose();
    _checksumController.dispose();
    super.dispose();
  }

  int? _parseOffset(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed == null || parsed < 0 ? null : parsed;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final commandOffset = _parseOffset(_commandController.text);
    final lengthOffset = _parseOffset(_lengthController.text);
    final payloadOffset = _parseOffset(_payloadController.text);
    final checksumOffset = _parseOffset(_checksumController.text);
    if (commandOffset == null ||
        lengthOffset == null ||
        payloadOffset == null ||
        checksumOffset == null) {
      setState(() => _validationError = '偏移必须是非负整数');
      return;
    }
    try {
      final profile = ProtocolProfile(
        id: widget.initial?.id,
        name: _nameController.text,
        header: HexCodec.decode(_headerController.text),
        commandOffset: commandOffset,
        lengthOffset: lengthOffset,
        payloadOffset: payloadOffset,
        checksumStartOffset: checksumOffset,
      );
      Navigator.of(context).pop(profile);
    } on PayloadFormatException catch (error) {
      setState(() => _validationError = error.message);
    } on ArgumentError catch (error) {
      setState(() {
        _validationError = error.message?.toString() ?? '协议配置无效';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    widget.initial == null ? '新增协议 Profile' : '编辑协议 Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey<String>('protocol-profile-name'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名称'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? '请输入名称' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey<String>('protocol-profile-header'),
                controller: _headerController,
                decoration: const InputDecoration(
                  labelText: '帧头 HEX',
                  hintText: 'AA 55',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _OffsetField(
                      label: '命令偏移',
                      controller: _commandController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OffsetField(
                      label: '长度偏移',
                      controller: _lengthController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _OffsetField(
                      label: '负载偏移',
                      controller: _payloadController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OffsetField(
                      label: '校验起始',
                      controller: _checksumController,
                    ),
                  ),
                ],
              ),
              if (_validationError != null) ...<Widget>[
                const SizedBox(height: 9),
                Text(
                  _validationError!,
                  style: TextStyle(color: colors.warning, fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                '当前版本支持单字节长度字段和 XOR 校验；长度字段必须紧邻负载。',
                style: TextStyle(color: colors.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存 Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OffsetField extends StatelessWidget {
  const _OffsetField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        return parsed == null || parsed < 0 ? '请输入非负整数' : null;
      },
    );
  }
}
