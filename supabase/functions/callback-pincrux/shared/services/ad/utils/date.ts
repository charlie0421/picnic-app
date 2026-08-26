export function getNextMonth15thAt9AM(now = new Date()) {
  const kstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  const year = kstNow.getUTCFullYear();
  const month = kstNow.getUTCMonth();
  const day = kstNow.getUTCDate();
  const expireMonth = day <= 15 ? month + 1 : month + 2;
  const expired = new Date(Date.UTC(year, expireMonth, 15, 0, 0, 0));
  return expired.toISOString().slice(0, 19).replace('T', ' ');
}

export function getPincruxRewardExpiry(transactionId: string, now = new Date()) {
  const match = /^(\d{4})(\d{2})(\d{2})/.exec(transactionId);
  if (!match) return getNextMonth15thAt9AM(now);

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const transactionDate = new Date(Date.UTC(year, month - 1, day, 0, 0, 0));
  if (
    transactionDate.getUTCFullYear() !== year ||
    transactionDate.getUTCMonth() !== month - 1 ||
    transactionDate.getUTCDate() !== day
  ) {
    return getNextMonth15thAt9AM(now);
  }

  return getNextMonth15thAt9AM(transactionDate);
}
