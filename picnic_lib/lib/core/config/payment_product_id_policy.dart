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
    final prefix =
        environment == 'local' || environment == 'dev' ? paymentNamespace : '';
    if ((environment == 'local' || environment == 'dev') && prefix.isEmpty) {
      throw StateError('Sandbox payment namespace is required');
    }
    return '$prefix$serverProductId'.toLowerCase();
  }
}
