import 'dart:io';
import 'factories/vote_factory.dart';
import 'factories/artist_factory.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/supabase_options.dart';

const detailLongCopy =
    'Long translated inquiry and reward information for a foldable screen';

QnaThread detailThread({String status = 'IN_PROGRESS'}) => QnaThread(
  id: 7,
  userId: 'test-user-id',
  title: detailLongCopy,
  createdAt: DateTime.utc(2026, 10, 29),
  updatedAt: DateTime.utc(2026, 10, 29),
  status: status,
);

class DetailQnaRepository extends QnaRepository {
  DetailQnaRepository({
    this.status = 'IN_PROGRESS',
    this.failFirst = false,
    this.messageCount = 1,
  }) : super(client: testSupabaseClient);
  final String status;
  final bool failFirst;
  final int messageCount;
  static int sendAttempts = 0;
  int loads = 0;
  @override
  Future<QaThreadWithMessages> getQaThreadById(int threadId) async {
    if (failFirst && loads++ == 0) {
      throw StateError('local fixture load failure');
    }
    return QaThreadWithMessages(
      thread: detailThread(status: status),
      categoryLabel: detailLongCopy,
      messages: [
        for (var i = 0; i < messageCount; i++)
          QnaMessage(
            id: i + 1,
            threadId: 7,
            userId: 'support',
            content: '$detailLongCopy\n$detailLongCopy',
            createdAt: DateTime.utc(2026, 10, 29).add(Duration(minutes: i)),
            isAdminMessage: true,
          ),
      ],
    );
  }

  @override
  Future<QnaMessage> createQaMessage({
    required int threadId,
    required String userId,
    required String content,
    List<File>? attachments,
  }) {
    sendAttempts++;
    throw StateError('UI audit must not submit a customer inquiry');
  }

  @override
  String getPublicUrl(String path) => 'https://fixture.invalid/$path';
}

Widget detailQnaPage({DetailQnaRepository? repository}) => QnaThreadDetailPage(
  thread: detailThread(status: repository?.status ?? 'IN_PROGRESS'),
  repository: repository ?? DetailQnaRepository(),
  syncNavigation: false,
  statusSubscriber: ({required threadId, required onStatusChanged}) => () {},
);

final detailVoteItem = VoteItemFactory.create(
  voteTotal: 0,
  artist: ArtistFactory.create(
    name: const {
      'ko': detailLongCopy,
      'en': detailLongCopy,
      'es': detailLongCopy,
    },
    image: null,
  ),
);
final detailPartnerVote = VoteFactory.create(
  isPartnership: true,
  partner: 'partner-fixture',
  title: const {
    'ko': detailLongCopy,
    'en': detailLongCopy,
    'es': detailLongCopy,
  },
  voteItem: [detailVoteItem],
);
Map<String, dynamic> detailVoteFixtures() {
  final vote = VoteFactory.create(
    voteCategory: 'achieve',
    title: const {
      'ko': detailLongCopy,
      'en': detailLongCopy,
      'es': detailLongCopy,
    },
    voteItem: [detailVoteItem],
  );
  return {
    'vote': [vote.toJson()],
    'vote_item': [detailVoteItem.toJson()],
    'vote_achieve': [
      VoteAchieveFactory.create(
        vote: vote,
        amount: 123456789,
        reward: RewardFactory.create(
          title: const {
            'ko': detailLongCopy,
            'en': detailLongCopy,
            'es': detailLongCopy,
          },
        ),
      ).toJson(),
    ],
    'banner': [],
    'reward': [],
  };
}
