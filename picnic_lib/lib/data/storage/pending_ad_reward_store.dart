import 'dart:convert';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

enum PendingAdRewardLocalState { pendingDisplay, ackPending }

class StoredAdRewardReference {
  const StoredAdRewardReference({required this.reference, required this.state});
  final AdRewardReference reference;
  final PendingAdRewardLocalState state;
  Map<String, dynamic> toJson() => {
    'reference': reference.toJson(),
    'state': state.name,
  };
  factory StoredAdRewardReference.fromJson(Map<String, dynamic> json) {
    try {
      requireExactContractKeys(json, {'reference', 'state'});
      return StoredAdRewardReference(
        reference: AdRewardReference.fromJson(
          Map<String, dynamic>.from(json['reference'] as Map),
        ),
        state: PendingAdRewardLocalState.values.byName(json['state'] as String),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid stored ad reward reference', error);
    }
  }
}

/// 한 사용자당 보관하는 표시 대기/확인 대기 기록 수 상한.
///
/// 예전에는 시작·복귀 복구가 이 목록을 훑으면서 확인이 끝난 항목을 지웠고,
/// 그래서 목록은 스스로 줄어들었다. 그 복구를 걷어낸 지금 남는 기록은
/// **확인(ACK)이 끝내 실패한 건**뿐이고, 그것을 다시 읽어 정리해 줄 경로는
/// 없다. 상한이 없으면 그 잔여물이 기기에 영원히 쌓인다.
///
/// 오래된 항목을 버려도 잃는 것은 앱 로컬 표시 상태뿐이다. 서버 보상과 원장,
/// 이미 저장된 적립 통계는 이 목록과 무관하게 그대로 남는다.
const kPendingAdRewardMaxRecords = 100;

class PendingAdRewardStore {
  PendingAdRewardStore(
    this.storage, {
    this.maxRecords = kPendingAdRewardMaxRecords,
  }) : assert(maxRecords > 0);
  final LocalStorage storage;

  /// 사용자당 보관 상한. 넘치면 **가장 오래 전에 기록된 것부터** 버린다.
  final int maxRecords;

  Future<void> _writeTail = Future<void>.value();
  String _key(String userId) => 'pending_ad_rewards_v1:$userId';
  String _identity(AdRewardReference value) => '${value.type.name}:${value.id}';
  Future<void> _serialize(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }

  Future<List<StoredAdRewardReference>> readAll(String userId) async {
    final raw = await storage.loadData(_key(userId), '[]') ?? '[]';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Pending rewards must be a list');
      }
      return decoded
          .map(
            (value) => StoredAdRewardReference.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList();
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid pending ad rewards', error);
    }
  }

  Future<void> _save(String userId, Iterable<StoredAdRewardReference> values) {
    final all = values.toList(growable: false);
    // 최신 기록이 뒤에 오므로 앞쪽(가장 오래된 것)을 잘라낸다. 방금 쓴 항목은
    // 항상 살아남는다.
    final kept = all.length <= maxRecords
        ? all
        : all.sublist(all.length - maxRecords);
    return storage.saveData(
      _key(userId),
      jsonEncode(kept.map((value) => value.toJson()).toList()),
    );
  }

  Future<void> add(String userId, AdRewardReference reference) =>
      _serialize(() async {
        final values = await readAll(userId);
        final byKey = {
          for (final value in values) _identity(value.reference): value,
        };
        byKey.putIfAbsent(
          _identity(reference),
          () => StoredAdRewardReference(
            reference: reference,
            state: PendingAdRewardLocalState.pendingDisplay,
          ),
        );
        await _save(userId, byKey.values);
      });
  Future<void> markAckPending(String userId, AdRewardReference reference) =>
      _serialize(() async {
        final values = await readAll(userId);
        final byKey = {
          for (final value in values) _identity(value.reference): value,
        };
        // 목록 맨 뒤로 옮긴다. 확인은 "지금" 진행 중인 건이므로 상한을 넘겼을 때
        // 잘려 나가야 하는 쪽이 아니다.
        byKey.remove(_identity(reference));
        byKey[_identity(reference)] = StoredAdRewardReference(
          reference: reference,
          state: PendingAdRewardLocalState.ackPending,
        );
        await _save(userId, byKey.values);
      });
  Future<void> remove(String userId, AdRewardReference reference) =>
      _serialize(() async {
        final values = await readAll(userId)
          ..removeWhere((value) => value.reference == reference);
        await _save(userId, values);
      });
}
