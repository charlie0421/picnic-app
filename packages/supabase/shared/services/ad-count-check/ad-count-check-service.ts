import { createClient } from '@supabase/supabase-js';

interface PlatformCounts {
  hourly: number;
  daily: number;
}

interface TransactionRow {
  created_at: string;
}

interface AdLimits {
  hourly: number;
  daily: number;
}

interface NextAvailableTime {
  time: string;
}

const AD_LIMITS: Record<string, AdLimits> = {
  admob: { hourly: 10, daily: 120 },
  unity: { hourly: 10, daily: 120 },
  pangle: { hourly: 10, daily: 120 },
};

export class AdCountCheckService {
  private supabase: ReturnType<typeof createClient>;

  constructor() {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing Supabase credentials');
    }

    this.supabase = createClient(supabaseUrl, supabaseServiceKey);
  }

  private async getTransactionCount(
    platform: string,
    userId: string,
    hours: number,
  ): Promise<number> {
    const { data, error } = await this.supabase
      .from(`transaction_${platform}`)
      .select('created_at')
      .eq('user_id', userId)
      .gte(
        'created_at',
        new Date(Date.now() - hours * 60 * 60 * 1000).toISOString(),
      );

    if (error) {
      console.error(`Error fetching ${platform} transactions:`, error);
      throw error;
    }

    return data.length;
  }

  private async getPlatformCounts(
    platform: string,
    userId: string,
  ): Promise<{
    hourly: number;
    daily: number;
    nextAvailable?: NextAvailableTime;
  }> {
    const hourly = await this.getTransactionCount(platform, userId, 1);
    const daily = await this.getTransactionCount(platform, userId, 24);

    const limit = AD_LIMITS[platform];
    let nextAvailable: NextAvailableTime | undefined;

    if (hourly >= limit.hourly) {
      const oldestHourlyTransaction = await this.getOldestTransaction(
        platform,
        userId,
        1,
      );
      if (oldestHourlyTransaction) {
        const nextHourly = new Date(oldestHourlyTransaction);
        nextHourly.setHours(nextHourly.getHours() + 1);
        nextAvailable = { time: nextHourly.toISOString() };
      }
    }

    if (daily >= limit.daily) {
      const oldestDailyTransaction = await this.getOldestTransaction(
        platform,
        userId,
        24,
      );
      if (oldestDailyTransaction) {
        const nextDaily = new Date(oldestDailyTransaction);
        nextDaily.setHours(nextDaily.getHours() + 24);
        if (
          !nextAvailable ||
          new Date(nextDaily) < new Date(nextAvailable.time)
        ) {
          nextAvailable = { time: nextDaily.toISOString() };
        }
      }
    }

    return { hourly, daily, nextAvailable };
  }

  private async getOldestTransaction(
    platform: string,
    userId: string,
    hours: number,
  ): Promise<string | null> {
    const { data, error } = await this.supabase
      .from(`transaction_${platform}`)
      .select('created_at')
      .eq('user_id', userId)
      .gte(
        'created_at',
        new Date(Date.now() - hours * 60 * 60 * 1000).toISOString(),
      )
      .order('created_at', { ascending: true })
      .limit(1);

    if (error) {
      console.error(`Error fetching oldest ${platform} transaction:`, error);
      return null;
    }

    return data[0]?.created_at || null;
  }

  async checkAdLimits(
    userId: string,
    options: { platform?: string } = {},
  ): Promise<{
    allowed: boolean;
    counts: Record<string, PlatformCounts>;
    limits: Record<string, AdLimits>;
    nextAvailableTime?: string;
  }> {
    const platforms = options.platform
      ? [options.platform]
      : ['admob', 'unity', 'pangle'];
    const counts: Record<string, PlatformCounts> = {};
    let nextAvailableTime: string | undefined;

    for (const platform of platforms) {
      const result = await this.getPlatformCounts(platform, userId);
      counts[platform] = { hourly: result.hourly, daily: result.daily };

      if (result.nextAvailable) {
        if (
          !nextAvailableTime ||
          new Date(result.nextAvailable.time) < new Date(nextAvailableTime)
        ) {
          nextAvailableTime = result.nextAvailable.time;
        }
      }
    }

    const limits = options.platform
      ? { [options.platform]: AD_LIMITS[options.platform] }
      : AD_LIMITS;

    const allowed = Object.entries(counts).every(([platform, count]) => {
      const limit = limits[platform];
      return count.hourly < limit.hourly && count.daily < limit.daily;
    });

    return {
      allowed,
      counts,
      limits,
      ...(nextAvailableTime && { nextAvailableTime }),
    };
  }
}
