export interface RemainingTime {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

export function calculateRemainingTime(endTime: string): RemainingTime {
  const now = new Date().getTime();
  const end = new Date(endTime).getTime();
  const distance = Math.max(0, end - now);

  const days = Math.floor(distance / (1000 * 60 * 60 * 24));
  const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((distance % (1000 * 60)) / 1000);

  return {
    days,
    hours,
    minutes,
    seconds,
  };
} 