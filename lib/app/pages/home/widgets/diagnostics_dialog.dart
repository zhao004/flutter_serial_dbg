import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../models/ping_result.dart';
import '../../../services/diagnostics/network_diagnostics.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/gradient_primary_button.dart';
import '../home_controller.dart';

/// 本机 IP 和 Ping 网络诊断对话框。
class NetworkDiagnosticsDialog extends StatefulWidget {
  const NetworkDiagnosticsDialog({super.key, required this.controller});

  final HomeController controller;

  @override
  State<NetworkDiagnosticsDialog> createState() =>
      _NetworkDiagnosticsDialogState();
}

class _NetworkDiagnosticsDialogState extends State<NetworkDiagnosticsDialog> {
  final TextEditingController _targetController = TextEditingController();
  List<String> _addresses = const <String>[];
  PingResult? _pingResult;
  bool _loadingAddresses = true;
  bool _pinging = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAddresses());
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loadingAddresses = true;
    });
    try {
      final addresses = await widget.controller.loadLocalIpv4Addresses();
      if (!mounted) {
        return;
      }
      setState(() {
        _addresses = addresses;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(context, _displayError(error));
    } finally {
      if (mounted) {
        setState(() {
          _loadingAddresses = false;
        });
      }
    }
  }

  Future<void> _ping() async {
    final target = _targetController.text.trim();
    if (target.isEmpty) {
      AppToast.warning(context, '请输入 Ping 目标');
      return;
    }
    setState(() {
      _pinging = true;
      _pingResult = null;
    });
    try {
      final result = await widget.controller.ping(target);
      if (!mounted) {
        return;
      }
      setState(() {
        _pingResult = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(context, _displayError(error));
    } finally {
      if (mounted) {
        setState(() {
          _pinging = false;
        });
      }
    }
  }

  String _displayError(Object error) {
    return switch (error) {
      NetworkDiagnosticsException() => error.message,
      _ => '诊断操作失败',
    };
  }

  void _useAddress(String address) {
    setState(() {
      _pingResult = null;
    });
    _targetController.value = TextEditingValue(
      text: address,
      selection: TextSelection.collapsed(offset: address.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        16,
        18,
        MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.network_check_rounded,
                    size: 21,
                    color: colors.primaryDeep,
                  ),
                ),
                const SizedBox(width: 10),
                Text('网络诊断', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '本机 IPv4',
              style: TextStyle(
                color: colors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            if (_loadingAddresses)
              const LinearProgressIndicator(minHeight: 2)
            else if (_addresses.isEmpty)
              Builder(
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceMuted,
                      border: Border.all(color: colors.outline),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '未发现可用地址',
                      style: TextStyle(color: colors.inkMuted),
                    ),
                  );
                },
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _addresses
                    .map(
                      (address) => Semantics(
                        button: true,
                        label: '使用本机地址 $address',
                        child: Material(
                          color: colors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: ValueKey<String>('local-address-$address'),
                            onTap: () => _useAddress(address),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              child: Text(
                                address,
                                style: TextStyle(
                                  color: colors.primaryDeep,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            const Divider(height: 30),
            Text(
              '连通性测试',
              style: TextStyle(
                color: colors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            TextField(
              controller: _targetController,
              decoration: const InputDecoration(
                hintText: '输入 IP 或域名',
                prefixIcon: Icon(Icons.language_rounded, size: 19),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => unawaited(_ping()),
            ),
            const SizedBox(height: 12),
            GradientPrimaryButton(
              label: 'Ping',
              icon: Icons.network_ping_rounded,
              isLoading: _pinging,
              onPressed: _pinging ? null : () => unawaited(_ping()),
            ),
            if (_pingResult case final result?) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.status == PingStatus.success
                      ? colors.successSoft
                      : colors.errorSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      result.status == PingStatus.success
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      color: result.status == PingStatus.success
                          ? colors.success
                          : colors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_pingLabel(result.status)} · '
                      '${result.duration.inMilliseconds} ms',
                      style: TextStyle(
                        color: result.status == PingStatus.success
                            ? colors.success
                            : colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _pingLabel(PingStatus status) {
    return switch (status) {
      PingStatus.success => '可达',
      PingStatus.timeout => '超时',
      PingStatus.unreachable => '不可达',
      PingStatus.error => '失败',
    };
  }
}
