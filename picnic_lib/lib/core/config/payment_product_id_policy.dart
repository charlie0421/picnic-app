class PaymentProductIdPolicy {
  const PaymentProductIdPolicy._();

  static String effectiveProductId({
    required String environment,
    required bool isAndroid,
    required String paymentNamespace,
    required String serverProductId,
    required String iosAppPrefix,
  }) {
    if (!isAndroid) {
      return '$iosAppPrefix$serverProductId';
    }
    // dev/local에서 네임스페이스가 비어 있으면 프로덕션 SKU를 그대로 쓴다
    // (Play 라이선스 테스터 결제 전제 — 과금 없이 같은 상품으로 테스트).
    // wallet.v1 서버(cotton-candy-engine)는 Google 검증 시 정규화된
    // SKU(starxxx)로 조회하므로 이 경로가 서버 설계와 정합하고, 네임스페이스
    // SKU(staging.starxxx)는 오히려 조회 불일치를 일으킬 수 있다.
    final prefix =
        environment == 'local' || environment == 'dev' ? paymentNamespace : '';
    return '$prefix$serverProductId'.toLowerCase();
  }
}
