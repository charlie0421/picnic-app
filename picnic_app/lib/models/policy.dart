import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'policy.freezed.dart';
part 'policy.g.dart';

enum PolicyType {
  privacy,
  terms,
  withdraw,
}

enum PolicyLanguage {
  en,
  ko,
}

@reflector
@freezed
class PolicyItemModel with _$PolicyItemModel {
  factory PolicyItemModel({
    required String content,
    required String version,
  }) = _PolicyItemModel;

  factory PolicyItemModel.fromJson(Map<String, dynamic> json) =>
      _$PolicyItemModelFromJson(json);
}
