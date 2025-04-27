import React, { useState, useEffect, useRef, useMemo } from "react";
import { differenceInSeconds } from "date-fns";
import { useLanguageStore } from "@/stores/languageStore";

interface CountdownTimerProps {
  endTime: string | null;
  startTime: string | null;
  status: 'scheduled' | 'in_progress';
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
  if (seconds >= 86400) { // 24시간 이상
    return {
      textColor: 'text-black',
      bgColor: 'bg-secondary',
      animationInterval: 60 // 1분
    };
  } else if (seconds >= 3600) { // 1시간 이상 24시간 미만
    return {
      textColor: 'text-black',
      bgColor: 'bg-sub',
      animationInterval: 10 // 10초
    };
  } else { // 1시간 미만
    return {
      textColor: 'text-white',
      bgColor: 'bg-point',
      animationInterval: 1 // 1초
    };
  }
};

const shouldAnimate = (seconds: number, timerStyle: TimerStyle): boolean => {
  if (timerStyle.animationInterval === 60) {
    // 1분마다 (1분 00초)
    return seconds % 60 === 0;
  } else if (timerStyle.animationInterval === 10) {
    // 10초마다 (00초, 10초, 20초, 30초, 40초, 50초)
    return seconds % 10 === 0;
  } else {
    // 1초마다
    return true;
  }
};

const CountdownTimer = React.memo(({ endTime, startTime, status, className }: CountdownTimerProps) => {
  const { t } = useLanguageStore();
  const lastAnimationTimeRef = useRef<number>(0);
  const targetDateRef = useRef<Date | null>(null);
  
  const [remainingTime, setRemainingTime] = useState<TimeUnits | null>(null);
  const [scale, setScale] = useState(1);
  const [pulse, setPulse] = useState(false);
  const [timerStyle, setTimerStyle] = useState<TimerStyle>({
    textColor: 'text-black',
    bgColor: 'bg-secondary',
    animationInterval: 60
  });

  // targetDate 계산을 useMemo로 분리
  const targetDate = useMemo(() => {
    if (!startTime || !endTime) return null;
    return status === 'scheduled' ? new Date(startTime) : new Date(endTime);
  }, [startTime, endTime, status]);

  useEffect(() => {
    if (targetDate) {
      targetDateRef.current = targetDate;
    }
  }, [targetDate]);

  useEffect(() => {
    if (!targetDate) return;
    
    const isEnded = new Date() >= targetDate;
    if (isEnded) return;

    const updateTimer = () => {
      const now = new Date();
      const diffInSeconds = differenceInSeconds(targetDateRef.current!, now);

      if (diffInSeconds <= 0) {
        setRemainingTime(null);
        return;
      }

      const newTimerStyle = getTimerStyle(diffInSeconds);
      setTimerStyle(newTimerStyle);
      setRemainingTime(calculateTimeUnits(diffInSeconds));
      
      if (shouldAnimate(diffInSeconds, newTimerStyle)) {
        setScale(1.1);
        setPulse(true);
        setTimeout(() => {
          setScale(1);
          setPulse(false);
        }, 500);
      }
    };

    updateTimer();
    const timer = setInterval(updateTimer, 1000);
    return () => clearInterval(timer);
  }, [targetDate]);

  if (!targetDate || !remainingTime) return null;

  return (
    <div className={`flex flex-col items-center ${className || ''}`}>
      <div className='text-xs text-gray-500 mb-2'>
        {status === 'scheduled' ? t('text_vote_countdown_start') : t('text_vote_countdown_end')}
      </div>
      <div className='flex items-center justify-center gap-1'>
        {Object.entries(remainingTime).map(([unit, value], index, array) => (
          <React.Fragment key={unit}>
            <div className='flex flex-col items-center'>
              <div
                className={`${timerStyle.bgColor} w-10 h-10 rounded-lg flex flex-col items-center justify-center font-mono text-base font-bold ${timerStyle.textColor} relative gap-0 shadow-lg transition-all duration-1000 ${
                  pulse ? 'animate-pulse' : ''
                }`}
                style={{ 
                  transform: `scale(${scale})`,
                  transition: 'all 1s cubic-bezier(0.4, 0, 0.2, 1)',
                  boxShadow: pulse ? '0 0 20px rgba(0,0,0,0.3)' : '0 4px 6px rgba(0,0,0,0.1)'
                }}
              >
                {value.toString().padStart(2, '0')}
                <span className={`text-[9px] font-medium ${timerStyle.textColor} leading-none transition-opacity duration-300 ${
                  pulse ? 'opacity-100' : 'opacity-90'
                }`}>
                  {unit === 'days' ? 'D' : unit === 'hours' ? 'H' : unit === 'minutes' ? 'M' : 'S'}
                </span>
              </div>
            </div>
            {index < array.length - 1 && (
              <span className={`${timerStyle.textColor} font-bold transition-opacity duration-300 ${
                pulse ? 'opacity-100' : 'opacity-80'
              }`}>:</span>
            )}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
});

CountdownTimer.displayName = 'CountdownTimer';

export default CountdownTimer;