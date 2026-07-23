import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/auth/edge_auth_retry.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  WalletSummaryModel wallet({
    String star = '0',
    String bonus = '0',
    String cotton = '0',
  }) => WalletSummaryModel(
    contractVersion: 'wallet.v1',
    star: BigInt.parse(star),
    bonus: BigInt.parse(bonus),
    cotton: BigInt.parse(cotton),
    cottonExpiringAmount: BigInt.zero,
    cottonNextExpiresAt: null,
    snapshotAt: DateTime.utc(2026, 7, 21),
  );

  group('VotingDialogHelper', () {
    group('invokeVotingWithAuthRecovery', () {
      test('refreshes after the first auth 401 and retries once', () async {
        var invokes = 0;
        var refreshes = 0;
        final events = <VotingAuthRecoveryEvent>[];

        final result = await VotingDialogHelper.invokeVotingWithAuthRecovery(
          invoke: () async {
            invokes++;
            if (invokes == 1) {
              throw const FunctionException(
                status: 401,
                details: 'Invalid JWT',
              );
            }
            return 'ok';
          },
          refresh: () async {
            refreshes++;
            return true;
          },
          onRecovery: events.add,
        );

        expect(result, 'ok');
        expect(invokes, 2);
        expect(refreshes, 1);
        expect(events.map((event) => event.phase), [
          VotingAuthRecoveryPhase.refreshStarted,
          VotingAuthRecoveryPhase.refreshSucceeded,
        ]);
        expect(events.map((event) => event.status), everyElement(401));
      });

      test('stops after the retried request is also unauthorized', () async {
        var invokes = 0;
        final events = <VotingAuthRecoveryEvent>[];

        await expectLater(
          VotingDialogHelper.invokeVotingWithAuthRecovery<void>(
            invoke: () async {
              invokes++;
              throw const FunctionException(
                status: 401,
                details: 'Invalid JWT',
              );
            },
            refresh: () async => true,
            onRecovery: events.add,
          ),
          throwsA(
            isA<EdgeAuthRecoveryException>().having(
              (error) => error.reason,
              'reason',
              EdgeAuthRecoveryFailureReason.retryUnauthorized,
            ),
          ),
        );

        expect(invokes, 2);
        expect(events.last.phase, VotingAuthRecoveryPhase.retryFailed);
        expect(events.last.status, 401);
      });

      for (final status in [400, 403, 500]) {
        test('does not refresh for FunctionException $status', () async {
          var refreshes = 0;

          await expectLater(
            VotingDialogHelper.invokeVotingWithAuthRecovery<void>(
              invoke: () async => throw FunctionException(status: status),
              refresh: () async {
                refreshes++;
                return true;
              },
            ),
            throwsA(
              isA<FunctionException>().having(
                (error) => error.status,
                'status',
                status,
              ),
            ),
          );

          expect(refreshes, 0);
        });
      }

      test(
        'reports retry_failed with safe 429 status and preserves error',
        () async {
          var invokes = 0;
          final retryError = const FunctionException(
            status: 429,
            details: 'sensitive request details',
          );
          final events = <VotingAuthRecoveryEvent>[];

          await expectLater(
            VotingDialogHelper.invokeVotingWithAuthRecovery<void>(
              invoke: () async {
                invokes++;
                if (invokes == 1) {
                  throw const FunctionException(status: 401);
                }
                throw retryError;
              },
              refresh: () async => true,
              onRecovery: events.add,
            ),
            throwsA(same(retryError)),
          );

          expect(events.last.phase, VotingAuthRecoveryPhase.retryFailed);
          expect(events.last.status, 429);
        },
      );

      test('keeps 429 backoff inside the post-refresh invoke', () async {
        var authInvokes = 0;
        var transportInvokes = 0;
        var backoffs = 0;
        final events = <VotingAuthRecoveryEvent>[];

        Future<String> invokeWith429Backoff() async {
          authInvokes++;
          if (authInvokes == 1) {
            throw const FunctionException(status: 401);
          }
          while (true) {
            try {
              transportInvokes++;
              if (transportInvokes == 1) {
                throw const FunctionException(status: 429);
              }
              return 'ok';
            } on FunctionException catch (error) {
              if (error.status != 429) rethrow;
              backoffs++;
            }
          }
        }

        final result = await VotingDialogHelper.invokeVotingWithAuthRecovery(
          invoke: invokeWith429Backoff,
          refresh: () async => true,
          onRecovery: events.add,
        );

        expect(result, 'ok');
        expect(authInvokes, 2);
        expect(transportInvokes, 2);
        expect(backoffs, 1);
        expect(
          events.map((event) => event.phase),
          isNot(contains(VotingAuthRecoveryPhase.retryFailed)),
        );
      });

      test('builds only the agreed low-cardinality Sentry tags', () {
        final tags = VotingDialogHelper.authRecoveryTags(
          portal: 'pic',
          event: const VotingAuthRecoveryEvent(
            VotingAuthRecoveryPhase.retryFailed,
            status: 500,
          ),
        );

        expect(tags, {
          'portal': 'pic',
          'phase': 'retry_failed',
          'status': '500',
        });
      });

      test('reports refresh failure without exposing its cause', () async {
        final events = <VotingAuthRecoveryEvent>[];

        await expectLater(
          VotingDialogHelper.invokeVotingWithAuthRecovery<void>(
            invoke: () async => throw const FunctionException(
              status: 401,
              details: 'Invalid JWT',
            ),
            refresh: () async => false,
            onRecovery: events.add,
          ),
          throwsA(isA<EdgeAuthRecoveryException>()),
        );

        expect(events.last.phase, VotingAuthRecoveryPhase.refreshFailed);
        expect(events.last.status, 401);
      });
    });

    // -------------------------------------------------------------------------
    // resolveArtistImageUrl
    // -------------------------------------------------------------------------
    group('resolveArtistImageUrl', () {
      test('returns artist image when artistId is non-zero', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: 42,
            artistImage: 'https://img/artist.png',
            artistGroupImage: 'https://img/group.png',
          ),
          'https://img/artist.png',
        );
      });

      test('returns group image when artistId is 0', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: 0,
            artistImage: 'https://img/artist.png',
            artistGroupImage: 'https://img/group.png',
          ),
          'https://img/group.png',
        );
      });

      test('returns group image when artistId is null', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: null,
            artistImage: 'https://img/artist.png',
            artistGroupImage: 'https://img/group.png',
          ),
          'https://img/group.png',
        );
      });

      test('returns null when both images are null and artistId is 0', () {
        expect(
          VotingDialogHelper.resolveArtistImageUrl(
            artistId: 0,
            artistImage: null,
            artistGroupImage: null,
          ),
          isNull,
        );
      });

      test(
        'returns null artist image when artistId is non-zero but image is null',
        () {
          expect(
            VotingDialogHelper.resolveArtistImageUrl(
              artistId: 1,
              artistImage: null,
              artistGroupImage: 'https://img/group.png',
            ),
            isNull,
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // shouldUseJmaDialog
    // -------------------------------------------------------------------------
    group('shouldUseJmaDialog', () {
      test('returns true for jma partner on non-PIC portal', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: 'jma',
          ),
          isTrue,
        );
      });

      test('returns true for JMA partner (case insensitive)', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: 'JMA',
          ),
          isTrue,
        );
      });

      test('normalizes whitespace and case', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: '  JmA  ',
          ),
          isTrue,
        );
      });

      test('returns false for PIC portal even with jma partner', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: true,
            partner: 'jma',
          ),
          isFalse,
        );
      });

      test('returns false when partner is null', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: null,
          ),
          isFalse,
        );
      });

      test('returns false for non-jma partner', () {
        expect(
          VotingDialogHelper.shouldUseJmaDialog(
            isPicPortal: false,
            partner: 'other',
          ),
          isFalse,
        );
      });
    });

    group('general wallet balance', () {
      test('includes Cotton and remains exact above JS safe integer', () {
        final summary = wallet(star: '9007199254740993', cotton: '5');
        expect(
          VotingDialogHelper.hasGeneralVoteBalance(
            summary,
            BigInt.parse('9007199254740998'),
          ),
          isTrue,
        );
      });

      test('caps use-all at server maximum', () {
        expect(
          VotingDialogHelper.cappedGeneralVoteBalance(
            wallet(star: '9007199254740993'),
          ),
          BigInt.from(2147483647),
        );
      });
    });

    // -------------------------------------------------------------------------
    // getVotingFunctionName
    // -------------------------------------------------------------------------
    group('getVotingFunctionName', () {
      test('returns pic-voting-v2 for PIC portal', () {
        expect(
          VotingDialogHelper.getVotingFunctionName(isPicPortal: true),
          'pic-voting-v2',
        );
      });

      test('returns voting-v2 for non-PIC portal', () {
        expect(
          VotingDialogHelper.getVotingFunctionName(isPicPortal: false),
          'voting-v2',
        );
      });
    });

    // -------------------------------------------------------------------------
    // determineVoteButtonState
    // -------------------------------------------------------------------------
    group('determineVoteButtonState', () {
      test('returns loading when isVoting is true', () {
        expect(
          VotingDialogHelper.determineVoteButtonState(
            canVote: true,
            isVoting: true,
          ),
          VoteButtonState.loading,
        );
      });

      test('returns enabled when canVote is true and not voting', () {
        expect(
          VotingDialogHelper.determineVoteButtonState(
            canVote: true,
            isVoting: false,
          ),
          VoteButtonState.enabled,
        );
      });

      test('returns disabled when canVote is false and not voting', () {
        expect(
          VotingDialogHelper.determineVoteButtonState(
            canVote: false,
            isVoting: false,
          ),
          VoteButtonState.disabled,
        );
      });

      test('returns loading over disabled when isVoting but cannot vote', () {
        expect(
          VotingDialogHelper.determineVoteButtonState(
            canVote: false,
            isVoting: true,
          ),
          VoteButtonState.loading,
        );
      });
    });

    // -------------------------------------------------------------------------
    // shouldShowErrorMessage
    // -------------------------------------------------------------------------
    group('shouldShowErrorMessage', () {
      test('returns true when cannot vote but has value', () {
        expect(
          VotingDialogHelper.shouldShowErrorMessage(
            canVote: false,
            hasValue: true,
          ),
          isTrue,
        );
      });

      test('returns false when can vote', () {
        expect(
          VotingDialogHelper.shouldShowErrorMessage(
            canVote: true,
            hasValue: true,
          ),
          isFalse,
        );
      });

      test('returns false when no value entered', () {
        expect(
          VotingDialogHelper.shouldShowErrorMessage(
            canVote: false,
            hasValue: false,
          ),
          isFalse,
        );
      });
    });

    // -------------------------------------------------------------------------
    // formatVoteInput
    // -------------------------------------------------------------------------
    group('formatVoteInput', () {
      test('formats a simple number with commas', () {
        expect(VotingDialogHelper.formatVoteInput('1234567'), '1,234,567');
      });

      test('strips leading zeros', () {
        expect(VotingDialogHelper.formatVoteInput('00123'), '123');
      });

      test('returns null for empty string', () {
        expect(VotingDialogHelper.formatVoteInput(''), isNull);
      });

      test('returns null for all zeros', () {
        expect(VotingDialogHelper.formatVoteInput('000'), isNull);
      });

      test('returns null for zero', () {
        expect(VotingDialogHelper.formatVoteInput('0'), isNull);
      });

      test('handles single digit', () {
        expect(VotingDialogHelper.formatVoteInput('5'), '5');
      });

      test('handles three digits without comma', () {
        expect(VotingDialogHelper.formatVoteInput('999'), '999');
      });

      test('handles four digits with comma', () {
        expect(VotingDialogHelper.formatVoteInput('1000'), '1,000');
      });

      test('strips existing commas before formatting', () {
        expect(VotingDialogHelper.formatVoteInput('1,234'), '1,234');
      });
    });

    // -------------------------------------------------------------------------
    // computeCheckAllToggle
    // -------------------------------------------------------------------------
    group('computeCheckAllToggle', () {
      String testFormat(dynamic v) => v.toString();

      test('toggles on: sets checkAll, hasValue, and formatted amount', () {
        final result = VotingDialogHelper.computeCheckAllToggle(
          currentCheckAll: false,
          availableStarCandy: 5000,
          formatNumber: testFormat,
        );
        expect(result.checkAll, isTrue);
        expect(result.hasValue, isTrue);
        expect(result.formattedAmount, '5000');
      });

      test('toggles off: clears checkAll and hasValue', () {
        final result = VotingDialogHelper.computeCheckAllToggle(
          currentCheckAll: true,
          availableStarCandy: 5000,
          formatNumber: testFormat,
        );
        expect(result.checkAll, isFalse);
        expect(result.hasValue, isFalse);
        expect(result.formattedAmount, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // computeTotalStarCandy
    // -------------------------------------------------------------------------
    group('computeTotalStarCandy', () {
      test('sums regular and bonus', () {
        expect(
          VotingDialogHelper.computeTotalStarCandy(
            starCandy: 100,
            starCandyBonus: 50,
          ),
          150,
        );
      });

      test('returns zero when both are zero', () {
        expect(
          VotingDialogHelper.computeTotalStarCandy(
            starCandy: 0,
            starCandyBonus: 0,
          ),
          0,
        );
      });
    });

    // -------------------------------------------------------------------------
    // preCheckVote
    // -------------------------------------------------------------------------
    group('preCheckVote', () {
      test('returns null for valid vote', () {
        expect(
          VotingDialogHelper.preCheckVote(
            voteAmount: 100,
            availableStarCandy: 200,
          ),
          isNull,
        );
      });

      test('returns zeroAmount when vote is 0', () {
        expect(
          VotingDialogHelper.preCheckVote(
            voteAmount: 0,
            availableStarCandy: 200,
          ),
          VoteFailReason.zeroAmount,
        );
      });

      test('returns insufficientBalance when vote exceeds balance', () {
        expect(
          VotingDialogHelper.preCheckVote(
            voteAmount: 300,
            availableStarCandy: 200,
          ),
          VoteFailReason.insufficientBalance,
        );
      });

      test('returns null when vote equals balance exactly', () {
        expect(
          VotingDialogHelper.preCheckVote(
            voteAmount: 200,
            availableStarCandy: 200,
          ),
          isNull,
        );
      });
    });

    // -------------------------------------------------------------------------
    // hasPartnerLogo
    // -------------------------------------------------------------------------
    group('hasPartnerLogo', () {
      test('returns true when partnership is active with partner name', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(
            isPartnership: true,
            partner: 'jma',
          ),
          isTrue,
        );
      });

      test('returns false when isPartnership is false', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(
            isPartnership: false,
            partner: 'jma',
          ),
          isFalse,
        );
      });

      test('returns false when isPartnership is null', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(
            isPartnership: null,
            partner: 'jma',
          ),
          isFalse,
        );
      });

      test('returns false when partner is null', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(isPartnership: true, partner: null),
          isFalse,
        );
      });

      test('returns false when partner is empty', () {
        expect(
          VotingDialogHelper.hasPartnerLogo(isPartnership: true, partner: ''),
          isFalse,
        );
      });
    });
  });
}
