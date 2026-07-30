import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';

class WalletSummaryPanel extends ConsumerWidget {
  const WalletSummaryPanel({
    super.key,
    this.compact = false,
    this.alignment = MainAxisAlignment.start,
  });

  final bool compact;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    return ref
        .watch(walletSummaryProvider)
        .when(
          // 백그라운드 재조회(구매/광고 정산 뒤) 중에는 마지막으로 확인된
          // 잔액을 계속 보여준다 — `skipLoadingOnRefresh` 기본값 그대로.
          loading: () => WalletSummarySkeleton(compact: compact),
          // 실패는 **회복 가능한 상태**여야 한다. 이 카드가 실패를 막다른 문구
          // 하나로만 알리던 동안 사용자에게 남은 수단은 앱 강제 종료뿐이었다.
          error: (error, stackTrace) => _WalletSummaryError(
            message: localizations.wallet_load_failed,
            retryLabel: localizations.common_retry_label,
            onRetry: () => ref.read(walletSummaryProvider.notifier).refresh(),
          ),
          data: (wallet) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WalletCurrencySegment(
                      key: const Key('wallet-star-card'),
                      asset: 'assets/icons/store/currency_star_candy.png',
                      label: localizations.wallet_star_candy,
                      amount: wallet.star,
                      compact: compact,
                      contentAlignment: _contentAlignment,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: WalletCurrencySegment(
                      key: const Key('wallet-bonus-card'),
                      asset: 'assets/icons/store/currency_bonus_star_candy.png',
                      label: localizations.wallet_bonus_star_candy,
                      amount: wallet.bonus,
                      compact: compact,
                      contentAlignment: _contentAlignment,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: WalletCurrencySegment(
                      key: const Key('wallet-cotton-card'),
                      asset: 'assets/icons/store/currency_cotton_candy.png',
                      label: localizations.wallet_cotton_candy,
                      amount: wallet.cotton,
                      highlighted: true,
                      compact: compact,
                      contentAlignment: _contentAlignment,
                    ),
                  ),
                ],
              ),
              if (buildCottonExpiryText(context, wallet) case final expiry?)
                Container(
                  key: const Key('wallet-cotton-expiry'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    expiry,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Color(0xFFD94B86),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
  }

  CrossAxisAlignment get _contentAlignment {
    if (!compact) return CrossAxisAlignment.start;
    return switch (alignment) {
      MainAxisAlignment.center => CrossAxisAlignment.center,
      MainAxisAlignment.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
  }
}

/// 파우치의 실패 상태. 문구 + 재시도.
///
/// 재시도는 `WalletSummary.refresh()` — 스토어 헤더의 새로고침, 구매/광고 정산
/// 뒤의 재조회와 같은 경로다. 그 경로는 [kWalletSummaryReadTimeout] 으로 상한이
/// 걸려 있으므로 재시도가 다시 무한 로딩으로 돌아갈 수 없다.
class _WalletSummaryError extends StatelessWidget {
  const _WalletSummaryError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('wallet-summary-error'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF514A58),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            key: const Key('wallet-summary-retry'),
            behavior: HitTestBehavior.opaque,
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF9A7BFA)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 14, color: Color(0xFF7C58E8)),
                  const SizedBox(width: 4),
                  Text(
                    retryLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C58E8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? buildCottonExpiryText(BuildContext context, WalletSummaryModel wallet) {
  final localizations = AppLocalizations.of(context);
  final values = <String>[];
  if (wallet.cottonExpiringAmount > BigInt.zero) {
    values.add(
      localizations.wallet_cotton_expires_today(
        formatWalletAmount(wallet.cottonExpiringAmount),
      ),
    );
  }
  if (wallet.cottonNextExpiresAt != null) {
    values.add(
      localizations.wallet_cotton_next_expiry(
        DateFormat.yMd(
          Localizations.localeOf(context).toString(),
        ).add_Hm().format(wallet.cottonNextExpiresAt!.toLocal()),
      ),
    );
  }
  return values.isEmpty ? null : values.join('\n');
}

class WalletCurrencySegment extends StatelessWidget {
  const WalletCurrencySegment({
    super.key,
    required this.asset,
    required this.label,
    required this.amount,
    this.secondary,
    this.highlighted = false,
    this.compact = false,
    this.contentAlignment = CrossAxisAlignment.start,
  });

  final String asset;
  final String label;
  final BigInt amount;
  final String? secondary;
  final bool highlighted;
  final bool compact;
  final CrossAxisAlignment contentAlignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFFFFF7FB)
              : const Color(0xFFFBFAFD),
          border: Border.all(
            color: highlighted
                ? const Color(0xFFF3BAD2)
                : const Color(0xFFEDE8F1),
          ),
          borderRadius: BorderRadius.circular(17),
        ),
        padding: EdgeInsets.fromLTRB(8, compact ? 9 : 12, 6, compact ? 10 : 13),
        child: Column(
          crossAxisAlignment: contentAlignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              package: 'picnic_lib',
              width: compact ? 38 : 48,
              height: compact ? 38 : 48,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF514A58),
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: switch (contentAlignment) {
                CrossAxisAlignment.center => Alignment.center,
                CrossAxisAlignment.end => Alignment.centerRight,
                _ => Alignment.centerLeft,
              },
              child: SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: switch (contentAlignment) {
                    CrossAxisAlignment.center => Alignment.center,
                    CrossAxisAlignment.end => Alignment.centerRight,
                    _ => Alignment.centerLeft,
                  },
                  child: Text(
                    formatWalletAmount(amount),
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: compact ? 18 : 22,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: highlighted
                          ? const Color(0xFFD94B86)
                          : const Color(0xFF27222B),
                    ),
                  ),
                ),
              ),
            ),
            if (secondary != null && !compact)
              Text(secondary!, textAlign: TextAlign.left),
          ],
        ),
      ),
    );
  }
}
