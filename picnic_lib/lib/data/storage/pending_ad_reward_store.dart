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

class PendingAdRewardStore {
  PendingAdRewardStore(this.storage);
  final LocalStorage storage;
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

  Future<void> _save(String userId, Iterable<StoredAdRewardReference> values) =>
      storage.saveData(
        _key(userId),
        jsonEncode(values.map((value) => value.toJson()).toList()),
      );
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
