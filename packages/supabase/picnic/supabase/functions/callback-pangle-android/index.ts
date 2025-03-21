function validateParameters(params) {
  console.log('Validating parameters:', params); // 상세 로깅 추가
  const {
    user_id,
    reward_amount,
    reward_type,
    transaction_id,
    signature,
    reward_name,
  } = params;

  // 각 파라미터 타입과 값을 개별적으로 검증
  if (!user_id) {
    console.log('Missing user_id');
    return false;
  }
  if (reward_amount === undefined || reward_amount === null) {
    // 0도 유효한 값으로 처리
    console.log('Missing reward_amount');
    return false;
  }
  if (!reward_type) {
    console.log('Missing reward_type');
    return false;
  }
  if (!transaction_id) {
    console.log('Missing transaction_id');
    return false;
  }
  if (!signature) {
    console.log('Missing signature');
    return false;
  }
  if (!reward_name) {
    console.log('Missing reward_name');
    return false;
  }

  return true;
}

// verifyPangleSignature 함수도 수정
async function verifyPangleSignature(
  transactionId: string,
  secretKey: string,
  signature: string,
): Promise<boolean> {
  const message = transactionId + secretKey;
  console.log('Verifying signature:');
  console.log('- Transaction ID:', transactionId);
  console.log('- Message:', message);
  console.log('- Expected signature:', signature);

  const msgUint8 = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const calculatedSignature = hashArray
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  console.log('- Calculated signature:', calculatedSignature);
  console.log('- Signatures match:', calculatedSignature === signature);

  return calculatedSignature === signature;
}
