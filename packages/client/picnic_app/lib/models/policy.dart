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
//
// @reflector
// @freezed
// class PolicyItemModel with _$PolicyItemModel {
//   factory PolicyItemModel({
//     required String content,
//     required String version,
//   }) = _PolicyItemModel;
//
//   factory PolicyItemModel.fromJson(Map<String, dynamic> json) =>
//       _$PolicyItemModelFromJson(json);
// }

@reflector
@freezed
class PolicyModel with _$PolicyModel {
  const factory PolicyModel({
    required PrivacyModel privacy_en,
    required TermsModel terms_en,
    required PrivacyModel privacy_ko,
    required TermsModel terms_ko,
  }) = _PolicyModel;

  factory PolicyModel.fromJson(Map<String, dynamic> json) =>
      _$PolicyModelFromJson(json);
}

@reflector
@freezed
class PrivacyModel with _$PrivacyModel {
  const factory PrivacyModel({
    required String content,
    required String version,
  }) = _PrivacyModel;

  factory PrivacyModel.fromJson(Map<String, dynamic> json) =>
      _$PrivacyModelFromJson(json);
}

@reflector
@freezed
class TermsModel with _$TermsModel {
  const factory TermsModel({
    required String content,
    required String version,
  }) = _TermsModel;

  factory TermsModel.fromJson(Map<String, dynamic> json) =>
      _$TermsModelFromJson(json);
}
