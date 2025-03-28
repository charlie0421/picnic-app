export function getNextMonth15thAt9AM(): string {
  const now = new Date();
  const nextMonth = new Date(
    now.getFullYear(),
    now.getMonth() + 1,
    15,
    9,
    0,
    0,
  );
  return nextMonth.toISOString().slice(0, 19).replace('T', ' ');
}
