import { AdLimits } from './interfaces/index.ts';

export const AD_LIMITS: Record<string, AdLimits> = {
  admob: { hourly: 5, daily: 50 },
  unity: { hourly: 5, daily: 50 },
  pangle: { hourly: 5, daily: 50 },
};
