import { create } from 'zustand';

interface GlobalTimerState {
  currentTime: Date;
  subscribe: (callback: (time: Date) => void) => () => void;
}

const useGlobalTimer = create<GlobalTimerState>((set, get) => {
  let subscribers = new Set<(time: Date) => void>();
  let timer: NodeJS.Timeout | null = null;

  const startTimer = () => {
    if (timer) return;
    
    timer = setInterval(() => {
      const now = new Date();
      set({ currentTime: now });
      console.log('currentTime', now);
      subscribers.forEach(callback => callback(now));
    }, 1000);
  };

  const stopTimer = () => {
    if (timer) {
      clearInterval(timer);
      timer = null;
    }
  };

  return {
    currentTime: new Date(),
    subscribe: (callback) => {
      subscribers.add(callback);
      if (subscribers.size === 1) {
        startTimer();
      }
      return () => {
        subscribers.delete(callback);
        if (subscribers.size === 0) {
          stopTimer();
        }
      };
    },
  };
});

export default useGlobalTimer; 