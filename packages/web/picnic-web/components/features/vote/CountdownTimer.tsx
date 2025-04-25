import React, { useEffect, useState } from 'react';

interface RemainingTime {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

function calculateRemainingTime(endTime: string): RemainingTime {
  const now = new Date().getTime();
  const end = new Date(endTime).getTime();
  const diff = Math.max(0, end - now);

  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((diff % (1000 * 60)) / 1000);

  return { days, hours, minutes, seconds };
}

interface CountdownTimerProps {
  endTime: string;
}

export default function CountdownTimer({ endTime }: CountdownTimerProps) {
  const [remainingTime, setRemainingTime] = useState<RemainingTime>(calculateRemainingTime(endTime));
  const [scale, setScale] = useState(1);

  useEffect(() => {
    const timer = setInterval(() => {
      const newTime = calculateRemainingTime(endTime);
      setRemainingTime((prevTime: RemainingTime) => {
        if (prevTime.seconds !== newTime.seconds) {
          setScale(1.2);
          setTimeout(() => setScale(1), 200);
        }
        return newTime;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [endTime]);

  const getTimeBoxStyle = (hours: number) => {
    if (hours >= 24) {
      return "flex flex-col items-center justify-center bg-secondary rounded-lg p-3 min-w-[70px] shadow-lg transform transition-transform duration-200";
    } else if (hours >= 1) {
      return "flex flex-col items-center justify-center bg-sub rounded-lg p-3 min-w-[70px] shadow-lg transform transition-transform duration-200";
    } else {
      return "flex flex-col items-center justify-center bg-point rounded-lg p-3 min-w-[70px] shadow-lg transform transition-transform duration-200";
    }
  };

  const getTextStyle = (hours: number) => {
    if (hours >= 24) {
      return {
        number: "text-2xl font-bold text-secondary-content",
        label: "text-xs text-secondary-content/80 mt-1"
      };
    } else if (hours >= 1) {
      return {
        number: "text-2xl font-bold text-sub-content",
        label: "text-xs text-sub-content/80 mt-1"
      };
    } else {
      return {
        number: "text-2xl font-bold text-point-content",
        label: "text-xs text-point-content/80 mt-1"
      };
    }
  };

  const totalHours = remainingTime.days * 24 + remainingTime.hours;
  const timeBoxStyle = getTimeBoxStyle(totalHours);
  const textStyle = getTextStyle(totalHours);

  return (
    <div className="flex gap-4 items-center justify-center p-4">
      <div className={timeBoxStyle} style={{ transform: `scale(${remainingTime.days > 0 ? scale : 1})` }}>
        <span className={textStyle.number}>{remainingTime.days}</span>
        <span className={textStyle.label}>일</span>
      </div>
      <div className={timeBoxStyle} style={{ transform: `scale(${scale})` }}>
        <span className={textStyle.number}>{remainingTime.hours}</span>
        <span className={textStyle.label}>시간</span>
      </div>
      <div className={timeBoxStyle} style={{ transform: `scale(${scale})` }}>
        <span className={textStyle.number}>{remainingTime.minutes}</span>
        <span className={textStyle.label}>분</span>
      </div>
      <div className={timeBoxStyle} style={{ transform: `scale(${scale})` }}>
        <span className={textStyle.number}>{remainingTime.seconds}</span>
        <span className={textStyle.label}>초</span>
      </div>
    </div>
  );
} 