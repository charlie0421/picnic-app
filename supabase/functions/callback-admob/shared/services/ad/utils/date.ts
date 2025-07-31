export function getNextMonth15thAt9AM() {
  const now = new Date();
  const kstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000); // KST 기준으로 보정
  const year = kstNow.getFullYear();
  const month = kstNow.getMonth();
  const day = kstNow.getDate();
  const expireMonth = day <= 15 ? month + 1 : month + 2;
  const expired = new Date(Date.UTC(year, expireMonth, 15, 0, 0, 0)); // UTC 00:00
  return expired.toISOString().slice(0, 19).replace('T', ' ');
}
