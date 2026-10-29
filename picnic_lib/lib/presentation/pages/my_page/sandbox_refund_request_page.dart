import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/services/sandbox_refund_candidate_store.dart';
import 'package:picnic_lib/core/services/storekit_refund_request_channel.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

/// Admin test tool: asks Apple to refund a sandbox (TestFlight) purchase.
///
/// The list holds only purchases whose StoreKit 2 JWS Apple signed for the
/// sandbox, so the sheet never opens a real App Store refund request. In the
/// sandbox, Apple approves a submitted request and sends a REFUND server
/// notification; the server then takes back the purchase's stars.
class SandboxRefundRequestPage extends ConsumerStatefulWidget {
  const SandboxRefundRequestPage({
    super.key,
    this.candidates,
    this.refundRequests,
  });

  final SandboxRefundCandidateStore? candidates;
  final StoreKitRefundRequestChannel? refundRequests;

  @override
  ConsumerState<SandboxRefundRequestPage> createState() =>
      _SandboxRefundRequestPageState();
}

class _SandboxRefundRequestPageState
    extends ConsumerState<SandboxRefundRequestPage> {
  static final DateFormat _purchasedAtFormat = DateFormat('yyyy.MM.dd HH:mm');

  late final SandboxRefundCandidateStore _candidates;
  late final StoreKitRefundRequestChannel _refundRequests;
  List<SandboxRefundCandidate>? _loaded;
  bool _requestInProgress = false;

  @override
  void initState() {
    super.initState();
    _candidates = widget.candidates ?? SandboxRefundCandidateStore();
    _refundRequests =
        widget.refundRequests ?? const StoreKitRefundRequestChannel();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(navigationInfoProvider.notifier)
          .setMyPageTitle(pageTitle: '테스트 환불 요청');
    });
  }

  Future<void> _reload() async {
    final loaded = await _candidates.load();
    if (!mounted) return;
    setState(() => _loaded = loaded);
  }

  @override
  Widget build(BuildContext context) {
    final hasAdminAccess =
        ref.watch(
          userInfoProvider.select((state) => state.value?.hasAdminAccess),
        ) ??
        false;
    if (!hasAdminAccess) {
      return const Center(child: Text('접근 권한이 없습니다.'));
    }

    final loaded = _loaded;
    if (loaded == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // AdminMenuPage 와 같이 Scaffold 로 감싼다 - SnackbarUtil 의 결과 안내가
    // 이 화면 위에 표시되려면 Scaffold 가 필요하다.
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '이 기기에서 정산된 sandbox(TestFlight) 구매만 보입니다. '
              'Apple 환불 화면에서 사유를 고르고 제출하면 sandbox 가 바로 승인하고, '
              '서버가 그 구매의 별사탕을 회수합니다.\n'
              '거절을 시험하려면 사유를 기타로 고르고 DECLINE 을 입력하세요.',
            ),
          ),
          if (loaded.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('이 기기에 기록된 sandbox 구매가 없습니다.')),
            ),
          for (final candidate in loaded)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(candidate.productId),
              subtitle: Text(
                '${_purchasedAtFormat.format(candidate.purchasedAt.toLocal())}'
                ' · 거래 …${_lastDigits(candidate.transactionId)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              enabled: !_requestInProgress,
              onTap: () => _confirmAndRequest(candidate),
            ),
        ],
      ),
    );
  }

  static String _lastDigits(String transactionId) =>
      transactionId.substring(transactionId.length - 4);

  Future<void> _confirmAndRequest(SandboxRefundCandidate candidate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('환불 요청'),
        content: Text(
          '${candidate.productId} 구매의 Apple 환불 화면을 엽니다. '
          '승인되면 서버가 이 구매의 별사탕을 회수합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('열기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // 확인 창이 떠 있는 동안 권한이 바뀌었을 수 있다(로그아웃·권한 회수).
    // 화면만 바뀌고 창은 남으므로, 요청 직전에 다시 확인한다.
    final stillAdmin =
        ref.read(userInfoProvider).value?.hasAdminAccess ?? false;
    if (!stillAdmin) return;

    setState(() => _requestInProgress = true);
    final outcome = await _refundRequests.begin(candidate.transactionId);
    if (outcome == StoreKitRefundRequestOutcome.success ||
        outcome == StoreKitRefundRequestOutcome.duplicateRequest) {
      await _candidates.remove(candidate.transactionId);
    }
    if (!mounted) return;
    setState(() => _requestInProgress = false);
    await _reload();
    if (!mounted || !context.mounted) return;

    switch (outcome) {
      case StoreKitRefundRequestOutcome.success:
        SnackbarUtil().success(
          '환불 요청을 보냈습니다. 서버 반영까지 몇 분 걸릴 수 있습니다.',
          context: context,
        );
      case StoreKitRefundRequestOutcome.userCancelled:
        SnackbarUtil().info('환불 요청을 취소했습니다.', context: context);
      case StoreKitRefundRequestOutcome.duplicateRequest:
        SnackbarUtil().info('이미 환불을 요청한 구매입니다.', context: context);
      case StoreKitRefundRequestOutcome.failed:
        SnackbarUtil().error(
          '환불 화면을 열지 못했습니다. 잠시 뒤 다시 시도하세요.',
          context: context,
        );
      case StoreKitRefundRequestOutcome.unsupported:
        SnackbarUtil().error('이 앱 빌드는 환불 요청을 지원하지 않습니다.', context: context);
    }
  }
}
