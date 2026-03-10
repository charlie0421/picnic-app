import 'package:mockito/mockito.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:picnic_lib/data/repositories/qa_repository.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/data/repositories/popup_repository.dart';

/// 투표 아이템 요청 리포지토리 Mock
class MockVoteItemRequestRepository extends Mock
    implements VoteItemRequestRepository {}

/// Q&A 리포지토리 Mock
class MockQaRepository extends Mock implements QaRepository {}

/// QnA 리포지토리 Mock
class MockQnaRepository extends Mock implements QnaRepository {}

/// 팝업 리포지토리 Mock
class MockPopupRepository extends Mock implements PopupRepository {}
