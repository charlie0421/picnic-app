import 'package:freezed_annotation/freezed_annotation.dart';

part 'policy.freezed.dart';
part 'policy.g.dart';

@freezed
class PolicyModel with _$PolicyModel {
  const factory PolicyModel({
    @JsonKey(name: 'privacy_en') required PrivacyModel privacyEn,
    @JsonKey(name: 'terms_en') required TermsModel termsEn,
    @JsonKey(name: 'privacy_ko') required PrivacyModel privacyKo,
    @JsonKey(name: 'terms_ko') required TermsModel termsKo,
  }) = _PolicyModel;

  factory PolicyModel.fromJson(Map<String, dynamic> json) =>
      _$PolicyModelFromJson(json);
}

@freezed
class PrivacyModel with _$PrivacyModel {
  const factory PrivacyModel({
    @JsonKey(name: 'content') required String content,
    @JsonKey(name: 'version') required String version,
  }) = _PrivacyModel;

  factory PrivacyModel.fromJson(Map<String, dynamic> json) =>
      _$PrivacyModelFromJson(json);
}

@freezed
class TermsModel with _$TermsModel {
  const factory TermsModel({
    @JsonKey(name: 'content') required String content,
    @JsonKey(name: 'version') required String version,
  }) = _TermsModel;

  factory TermsModel.fromJson(Map<String, dynamic> json) =>
      _$TermsModelFromJson(json);
}
