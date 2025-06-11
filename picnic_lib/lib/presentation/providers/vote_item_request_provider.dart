import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/vote_item_request_provider.g.dart';

/// VoteItemRequestRepository 인스턴스를 제공하는 provider
@Riverpod(keepAlive: true)
VoteItemRequestRepository voteItemRequestRepository(Ref ref) {
  return VoteItemRequestRepository();
}
