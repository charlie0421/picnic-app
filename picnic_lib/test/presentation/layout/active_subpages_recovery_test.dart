import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_list_page.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/faq_page.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/wallet/wallet_summary_panel.dart';
import '../../helpers/extended_ui_fixtures.dart';
import '../../helpers/foldable_test_app.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_environment.dart';
import 'active_subpages_foldable_test.dart' show showPage, frames;

class _RecoverableWallet extends LayoutWallet {
  int retries = 0;
  @override
  Future<WalletSummaryModel> build() async =>
      throw StateError('Offline fixture');
  @override
  Future<void> refresh() async {
    retries++;
    state = AsyncData(await super.build());
  }
}

class _QnaList extends QnaRepository {
  _QnaList({required this.failFirst}) : super(client: testSupabaseClient);
  final bool failFirst;
  int calls = 0;
  @override
  Future<List<QnaThread>> getQaThreadList({
    required String userId,
    int? lastId,
    DateTime? lastCreatedAt,
    int limit = 20,
  }) async {
    if (calls++ == 0 && failFirst) throw StateError('Offline fixture');
    return failFirst
        ? []
        : [
            QnaThread(
              id: 1,
              userId: userId,
              title: extendedLongCopy,
              createdAt: DateTime.utc(2026, 10, 29),
              updatedAt: DateTime.utc(2026, 10, 29),
              status: 'IN_PROGRESS',
            ),
          ];
  }
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() async {
    initTestColors();
    resetFoldableTestPlugins();
    await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
  });
  tearDown(tearDownMockSupabase);
  for (final size in [const Size(320, 600), const Size(600, 400)]) {
    for (final language in ['ko', 'en', 'es']) {
      for (final failFirst in [false, true]) {
        testWidgets('QnA list long/empty retry=$failFirst $size $language', (
          tester,
        ) async {
          final repo = _QnaList(failFirst: failFirst);
          await showPage(
            tester,
            QnaThreadListPage(userId: 'test-user-id', repository: repo),
            size,
            2.6,
            language,
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(QnaThreadListPage)),
          );
          if (failFirst) {
            final retry = find.text(l10n.retry);
            await tester.ensureVisible(retry);
            await frames(tester);
            expect(retry.hitTestable(), findsOneWidget);
            await tester.tap(retry);
            await frames(tester);
            expect(repo.calls, 2);
            expect(find.text(l10n.qna_no_inquiries), findsOneWidget);
          } else {
            expect(find.text(extendedLongCopy), findsOneWidget);
          }
          final create = find.byKey(const Key('qna-create-action'));
          await tester.ensureVisible(create);
          await frames(tester);
          expect(create.hitTestable(), findsOneWidget);
        });
      }

      for (final faq in [false, true]) {
        testWidgets(
          '${faq ? 'FAQ' : 'notice'} error retry empty $size $language',
          (tester) async {
            var calls = 0;
            final page = faq
                ? FAQPage(
                    loadContent: () async {
                      if (calls++ == 0) throw StateError('Offline fixture');
                      return const FAQContent(faqs: [], categories: []);
                    },
                  )
                : NoticePage(
                    loadNotices: () async {
                      if (calls++ == 0) throw StateError('Offline fixture');
                      return [];
                    },
                  );
            await showPage(tester, page, size, 2.6, language);
            final l10n = AppLocalizations.of(
              tester.element(find.byWidget(page)),
            );
            final retry = find.text(l10n.label_retry);
            await tester.ensureVisible(retry);
            await frames(tester);
            expect(retry.hitTestable(), findsOneWidget);
            await tester.tap(retry);
            await frames(tester);
            expect(calls, 2);
            expect(
              find.byKey(ValueKey(faq ? 'faq-retry' : 'notice-retry')),
              findsNothing,
            );
            expect(
              find.text(l10n.common_text_no_search_result),
              findsOneWidget,
            );
          },
        );
      }
      testWidgets('wallet localized retry recovers $size $language', (
        tester,
      ) async {
        final wallet = _RecoverableWallet();
        await showPage(
          tester,
          const SingleChildScrollView(child: WalletSummaryPanel()),
          size,
          2.6,
          language,
          overrides: [walletSummaryProvider.overrideWith(() => wallet)],
        );
        final retry = find.byKey(const Key('wallet-summary-retry'));
        await tester.ensureVisible(retry);
        await frames(tester);
        expect(retry.hitTestable(), findsOneWidget);
        await tester.tap(retry);
        await frames(tester);
        expect(wallet.retries, 1);
        expect(find.byKey(const Key('wallet-summary-error')), findsNothing);
        expect(find.text('123,456,789'), findsNWidgets(2));
      });
    }
  }
}
