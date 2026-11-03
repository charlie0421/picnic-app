/// 광고 구좌의 기본 노출 순서.
///
/// 글로벌 번호는 이 목록을 순회한 결과로 계산되므로, 순서를 바꾸려면 이
/// 상수의 항목만 이동하면 된다. 사용 불가한 구좌는 [resolveAdOrder]가
/// 자동으로 제외한다.
const defaultAdOrder = <String>['admob', 'internal-shortform', 'pangle'];

List<String> resolveAdOrder({
  required Map<String, bool> available,
  List<String> configuredOrder = defaultAdOrder,
}) {
  return configuredOrder
      .where((platform) => available[platform] == true)
      .toList(growable: false);
}
