import React, { useState, useEffect, useRef } from "react";
import { differenceInSeconds } from "date-fns";
import { useLanguageStore } from "@/stores/languageStore";

interface CountdownTimerProps {
  endTime: string;
  startTime: string;
  status: 'scheduled' | 'in_progress';
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

const CountdownTimer = React.memo(({ endTime, startTime, status }: CountdownTimerProps) => {
  const targetDate = status === 'scheduled' ? new Date(startTime) : new Date(endTime);
  const isEnded = new Date() >= targetDate;
  const initialDiffInSeconds = differenceInSeconds(targetDate, new Date());
  
  const [remainingTime, setRemainingTime] = useState<TimeUnits | null>(
    initialDiffInSeconds > 0 ? calculateTimeUnits(initialDiffInSeconds) : null
  );
  const [scale, setScale] = useState(1);
  const [timerStyle, setTimerStyle] = useState<TimerStyle>(
    initialDiffInSeconds > 0 ? getTimerStyle(initialDiffInSeconds) : {
      textColor: 'text-black',
      bgColor: 'bg-secondary',
      animationInterval: 60
    }
  );
  const { t } = useLanguageStore();
  const lastAnimationTimeRef = useRef<number>(0);
  const targetDateRef = useRef(targetDate);

  useEffect(() => {
    targetDateRef.current = targetDate;
  }, [targetDate]);

  useEffect(() => {
    if (isEnded) return;

    const updateTimer = () => {
      const now = new Date();
      const diffInSeconds = differenceInSeconds(targetDateRef.current, now);

      if (diffInSeconds <= 0) {
        setRemainingTime(null);
        return;
      }

      const newTimerStyle = getTimerStyle(diffInSeconds);
      setTimerStyle(newTimerStyle);
      setRemainingTime(calculateTimeUnits(diffInSeconds));
      
      // 애니메이션 실행 조건
      if (shouldAnimate(diffInSeconds, newTimerStyle)) {
        setScale(1.1);
        setTimeout(() => setScale(1), 100);
      }
    };

    // 초기 상태 설정
    updateTimer();
    
    const timer = setInterval(updateTimer, 1000);
    return () => clearInterval(timer);
  }, [isEnded]);

  if (!remainingTime || isEnded) return null;

  return (
    <div className='flex flex-col items-center'>
      <div className='text-xs text-gray-500 mb-2'>
        {status === 'scheduled' ? t('text_vote_countdown_start') : t('text_vote_countdown_end')}
      </div>
      <div className='flex items-center justify-center gap-2'>
        {Object.entries(remainingTime).map(([unit, value], index, array) => (
          <React.Fragment key={unit}>
            <div className='flex flex-col items-center'>
              <div
                className={`${timerStyle.bgColor} w-14 h-14 rounded-lg flex flex-col items-center justify-center font-mono text-lg font-bold ${timerStyle.textColor} relative gap-0`}
                style={{ transform: `scale(${scale})`, transition: 'transform 0.1s ease-in-out' }}
              >
                {value.toString().padStart(2, '0')}
                <span className={`text-[10px] font-medium ${timerStyle.textColor} leading-none`}>
                  {unit === 'days' ? 'D' : unit === 'hours' ? 'H' : unit === 'minutes' ? 'M' : 'S'}
                </span>
              </div>
            </div>
            {index < array.length - 1 && (
              <span className={`${timerStyle.textColor} font-bold`}>:</span>
            )}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
});

CountdownTimer.displayName = 'CountdownTimer';

export default CountdownTimer;