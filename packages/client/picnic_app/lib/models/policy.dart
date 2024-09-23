import 'package:freezed_annotation/freezed_annotation.dart';

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
//
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

@freezed
class PrivacyModel with _$PrivacyModel {
  const factory PrivacyModel({
    required String content,
    required String version,
  }) = _PrivacyModel;

  factory PrivacyModel.fromJson(Map<String, dynamic> json) =>
      _$PrivacyModelFromJson(json);
}

@freezed
class TermsModel with _$TermsModel {
  const factory TermsModel({
    required String content,
    required String version,
  }) = _TermsModel;

  factory TermsModel.fromJson(Map<String, dynamic> json) =>
      _$TermsModelFromJson(json);
}
