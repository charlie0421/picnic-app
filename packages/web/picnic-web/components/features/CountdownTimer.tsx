import React, {useEffect, useMemo, useState} from 'react';
import {differenceInSeconds} from 'date-fns';
import {useLanguageStore} from '@/stores/languageStore';
import useGlobalTimer from '@/utils/global-timer';

const TIMER_STATUS = {
  SCHEDULED: 'scheduled',
  IN_PROGRESS: 'in_progress',
  ENDED: 'ended',
} as const;

type TimerStatus = (typeof TIMER_STATUS)[keyof typeof TIMER_STATUS];

interface CountdownTimerProps {
  endTime: string | null;
  startTime: string | null;
  status: TimerStatus;
  className?: string;
}

interface TimeUnits {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

const calculateTimeUnits = (seconds: number): TimeUnits => {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secondsRemaining = seconds % 60;

  return { days, hours, minutes, seconds: secondsRemaining };
};

type TimerStyle = {
  textColor: string;
  bgColor: string;
  animationInterval: number;
};

const getTimerStyle = (seconds: number): TimerStyle => {
  if (seconds >= 86400) {
    return {
      textColor: 'text-black',
      bgColor: 'bg-secondary',
      animationInterval: 60,
    };
  } else if (seconds >= 3600) {
    return {
      textColor: 'text-black',
      bgColor: 'bg-sub',
      animationInterval: 10,
    };
  } else {
    return {
      textColor: 'text-white',
      bgColor: 'bg-point',
      animationInterval: 1,
    };
  }
};

const shouldAnimate = (seconds: number, timerStyle: TimerStyle): boolean => {
  if (timerStyle.animationInterval === 60) {
    return seconds % 60 === 0;
  } else if (timerStyle.animationInterval === 10) {
    return seconds % 10 === 0;
  } else {
    return true;
  }
};

const CountdownTimer = React.memo(
  ({ endTime, startTime, status, className }: CountdownTimerProps) => {
    const { t } = useLanguageStore();
    const [remainingTime, setRemainingTime] = useState<TimeUnits | null>(null);
    const [scale, setScale] = useState(1);
    const [pulse, setPulse] = useState(false);
    const [timerStyle, setTimerStyle] = useState<TimerStyle>({
      textColor: 'text-black',
      bgColor: 'bg-secondary',
      animationInterval: 60,
    });

    const targetDate = useMemo(() => {
      if (!startTime || !endTime) return null;
      return status === TIMER_STATUS.SCHEDULED
        ? new Date(startTime)
        : new Date(endTime);
    }, [startTime, endTime, status]);

    useEffect(() => {
      if (!targetDate || status === TIMER_STATUS.ENDED) {
        setRemainingTime({
          days: 0,
          hours: 0,
          minutes: 0,
          seconds: 0,
        });
        return;
      }

      const updateTimer = (now: Date) => {
        const diffInSeconds = differenceInSeconds(targetDate, now);

        if (diffInSeconds <= 0) {
          setRemainingTime({
            days: 0,
            hours: 0,
            minutes: 0,
            seconds: 0,
          });
          return;
        }

        const newTimerStyle = getTimerStyle(diffInSeconds);
        const newRemainingTime = calculateTimeUnits(diffInSeconds);

        setTimerStyle(newTimerStyle);
        setRemainingTime(newRemainingTime);

        if (shouldAnimate(diffInSeconds, newTimerStyle)) {
          setScale(1.1);
          setPulse(true);
          setTimeout(() => {
            setScale(1);
            setPulse(false);
          }, 500);
        }
      };

      // 초기 업데이트
      updateTimer(new Date());

      // 전역 타이머 구독
      const unsubscribe = useGlobalTimer.subscribe((state) => {
        updateTimer(state.currentTime);
      });

      return () => {
        unsubscribe();
      };
    }, [targetDate, status]);

    if (!targetDate) return null;

    const getStatusText = () => {
      switch (status) {
        case TIMER_STATUS.SCHEDULED:
          return t('text_vote_countdown_start');
        case TIMER_STATUS.IN_PROGRESS:
          return t('text_vote_countdown_end');
        case TIMER_STATUS.ENDED:
          return t('text_vote_ended');
      }
    };

    const isEnded = status === TIMER_STATUS.ENDED;

    return (
      <div className={`flex flex-col items-center ${className || ''}`}>
        <div className='text-xs text-gray-500 mb-2'>{getStatusText()}</div>
        <div
          className={`flex items-center justify-center gap-1 ${
            isEnded ? 'opacity-50' : ''
          }`}
        >
          {Object.entries(
            remainingTime || { days: 0, hours: 0, minutes: 0, seconds: 0 },
          ).map(([unit, value], index, array) => (
            <React.Fragment key={unit}>
              <div className='flex flex-col items-center'>
                <div
                  className={`${
                    isEnded ? 'bg-gray-300' : timerStyle.bgColor
                  } w-10 h-10 rounded-lg flex flex-col items-center justify-center font-mono text-base font-bold ${
                    isEnded ? 'text-gray-500' : timerStyle.textColor
                  } relative gap-0 shadow-lg transition-all duration-1000 ${
                    pulse && !isEnded ? 'animate-pulse' : ''
                  }`}
                  style={{
                    transform: `scale(${scale})`,
                    transition: 'all 1s cubic-bezier(0.4, 0, 0.2, 1)',
                    boxShadow:
                      pulse && !isEnded
                        ? '0 0 20px rgba(0,0,0,0.3)'
                        : '0 4px 6px rgba(0,0,0,0.1)',
                  }}
                >
                  {value.toString().padStart(2, '0')}
                  <span
                    className={`text-[9px] font-medium ${
                      isEnded ? 'text-gray-500' : timerStyle.textColor
                    } leading-none transition-opacity duration-300 ${
                      pulse && !isEnded ? 'opacity-100' : 'opacity-90'
                    }`}
                  >
                    {unit === 'days'
                      ? 'D'
                      : unit === 'hours'
                      ? 'H'
                      : unit === 'minutes'
                      ? 'M'
                      : 'S'}
                  </span>
                </div>
              </div>
              {index < array.length - 1 && (
                <span
                  className={`font-bold ${
                    isEnded ? 'text-gray-400' : 'text-gray-500'
                  }`}
                >
                  :
                </span>
              )}
            </React.Fragment>
          ))}
        </div>
      </div>
    );
  },
);

CountdownTimer.displayName = 'CountdownTimer';

export default CountdownTimer;
