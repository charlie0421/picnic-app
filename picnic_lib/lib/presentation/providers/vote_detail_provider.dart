// ignore_for_file: strict_top_level_inference

import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'vote_list_provider.dart';

part '../../generated/providers/vote_detail_provider.g.dart';

@riverpod
class AsyncVoteDetail extends _$AsyncVoteDetail {
  @override
  Future<VoteModel?> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) async {
    return fetch(voteId: voteId, votePortal: votePortal);
  }

  Future<VoteModel?> fetch({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) async {
    final voteTable = votePortal == VotePortal.vote ? 'vote' : 'pic_vote';
    final voteItemTable = votePortal == VotePortal.vote
        ? 'vote_item'
        : 'pic_vote_item';

    try {
      final startedAt = DateTime.now();
      logger.d('[VoteDetail] fetch start voteId=$voteId portal=$votePortal');
      final response = await supabase
          .from(voteTable)
          .select(
            'id, main_image, title, start_at, stop_at, visible_at, vote_category, is_partnership, partner, $voteItemTable(*, artist(*, artist_group(*)), artist_group(*)), reward(*)',
          )
          .eq('id', voteId)
          .single();

      final now = DateTime.now().toUtc();

      // Add a new field to indicate if the current time is after end_at
      response['is_ended'] = now.isAfter(DateTime.parse(response['stop_at']));
      response['is_upcoming'] = now.isBefore(
        DateTime.parse(response['start_at']),
      );

      final result = VoteModel.fromJson(response);
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      logger.d(
        '[VoteDetail] fetch success voteId=$voteId portal=$votePortal in ${elapsedMs}ms',
      );
      return result;
    } catch (e, s) {
      final elapsedMs = DateTime.now()
          .difference(DateTime.now())
          .inMilliseconds;
      logger.e(
        '[VoteDetail] fetch error voteId=$voteId portal=$votePortal in ${elapsedMs}ms',
        error: e,
        stackTrace: s,
      );
      Sentry.captureException(e, stackTrace: s);
    }
    return null;
  }
}

@riverpod
class AsyncVoteItemList extends _$AsyncVoteItemList {
  @override
  FutureOr<List<VoteItemModel?>> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) async {
    return fetch(voteId: voteId, votePortal: votePortal);
  }

  FutureOr<List<VoteItemModel?>> fetch({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) async {
    final voteItemTable = votePortal == VotePortal.vote
        ? 'vote_item'
        : 'pic_vote_item';
    try {
      final startedAt = DateTime.now();
      // logger.d('[VoteItems] fetch start voteId=$voteId portal=$votePortal');
      final response = await supabase
          .from(voteItemTable)
          .select(
            'id, vote_id, vote_total, artist(*,artist_group(*)), artist_group(*)',
          )
          .eq('vote_id', voteId)
          .filter('deleted_at', 'is', null)
          .order('vote_total', ascending: false);

      List<VoteItemModel> voteItemList = List<VoteItemModel>.from(
        response.map((e) => VoteItemModel.fromJson(e)),
      );

      // async 작업 후 provider가 dispose되었는지 확인
      if (!ref.mounted) return voteItemList;

      state = AsyncValue.data(voteItemList);
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      logger.d(
        '[VoteItems] fetch success voteId=$voteId count=${voteItemList.length} portal=$votePortal in ${elapsedMs}ms',
      );
      return voteItemList;
    } catch (e, s) {
      logger.e(
        '[VoteItems] fetch error voteId=$voteId portal=$votePortal',
        error: e,
        stackTrace: s,
      );
      Sentry.captureException(e, stackTrace: s);

      return [];
    }
  }

  setVoteItem({required int id, required int voteTotal}) async {
    try {
      if (!ref.mounted) return;

      if (state.value != null) {
        final updatedList = state.value!.map<VoteItemModel>((item) {
          if (item != null && item.id == id) {
            item = item.copyWith(voteTotal: voteTotal);
          }
          return item!;
        }).toList();

        if (!ref.mounted) return;
        state = AsyncValue.data(updatedList);

        //sort by total_vote
        if (!ref.mounted) return;
        state = AsyncValue.data(
          state.value!.toList()
            ..sort((a, b) => b!.voteTotal!.compareTo(a!.voteTotal!)),
        );

        logger.i('Updated vote item in state: $id with voteTotal: $voteTotal');
      }
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      rethrow;
    }
  }
}

@riverpod
Future<List<VoteAchieve>?> fetchVoteAchieve(ref, {required int voteId}) async {
  try {
    final response = await supabase
        .from('vote_achieve')
        .select('id, vote_id, reward_id, order, amount, reward(*), vote(*)')
        .eq('vote_id', voteId)
        .order('order', ascending: true);

    return response.map<VoteAchieve>((e) => VoteAchieve.fromJson(e)).toList();
  } catch (e, s) {
    logger.e(s, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);

    return null;
  }
}
