import { useLanguageStore } from '@/stores/languageStore';
import React, { useState, useRef, useEffect } from 'react';

interface Slide {
  imageUrl?: string;
  title?: string;
  content?: string;
}

interface VotePopupProps {
  isOpen: boolean;
  onClose: () => void;
  onCloseFor7Days: () => void;
  slides: Slide[];
}

const VotePopup: React.FC<VotePopupProps> = ({
  isOpen,
  onClose,
  onCloseFor7Days,
  slides,
}) => {
  const [current, setCurrent] = useState(0);
  const [direction, setDirection] = useState<'left' | 'right' | null>(null);
  const contentRef = useRef<HTMLParagraphElement>(null);
  const [isOverflow, setIsOverflow] = useState(false);

  const { imageUrl, title, content } = slides[current] || {};
  const { t } = useLanguageStore();

  useEffect(() => {
    if (contentRef.current) {
      setIsOverflow(contentRef.current.scrollHeight > 100);
    }
  }, [content, current]);

  if (!isOpen || !slides || slides.length === 0) return null;

  const handlePrev = () => {
    if (current > 0) {
      setDirection('left');
      setTimeout(() => {
        setCurrent((prev) => prev - 1);
        setDirection(null);
      }, 250);
    }
  };

  const handleNext = () => {
    if (current < slides.length - 1) {
      setDirection('right');
      setTimeout(() => {
        setCurrent((prev) => prev + 1);
        setDirection(null);
      }, 250);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div
        className={`bg-white rounded-lg shadow-lg p-0 w-full max-w-sm mx-4 flex flex-col items-center relative overflow-hidden h-[450px]`}
      >
        {/* 좌우 버튼 */}
        {current > 0 && (
          <button
            className="absolute left-2 top-1/2 -translate-y-1/2 bg-primary shadow-lg rounded-full p-2 flex items-center justify-center hover:bg-primary-dark transition-colors z-10"
            onClick={handlePrev}
            aria-label="이전"
          >
            <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="white" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </button>
        )}
        {current < slides.length - 1 && (
          <button
            className="absolute right-2 top-1/2 -translate-y-1/2 bg-primary shadow-lg rounded-full p-2 flex items-center justify-center hover:bg-primary-dark transition-colors z-10"
            onClick={handleNext}
            aria-label="다음"
          >
            <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="white" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
            </svg>
          </button>
        )}
        {/* 슬라이드 영역 */}
        <div
          className={`flex flex-col items-center w-full transition-transform duration-300 ease-in-out ${direction === 'left' ? '-translate-x-10 opacity-0' : direction === 'right' ? 'translate-x-10 opacity-0' : 'translate-x-0 opacity-100'}`}
        >
          <div className="w-full mb-4 rounded-t-lg overflow-hidden bg-gray-100" style={{ position: 'relative', paddingTop: '56.25%' }}>
            <img
              src={imageUrl || '/images/logo_alpha.png'}
              alt="popup"
              className={`absolute top-0 left-0 w-full h-full ${imageUrl ? 'object-cover' : 'object-contain'}`}
            />
          </div>
          {title && <h2 className="text-lg font-bold mb-2 text-center text-black">{title}</h2>}
          {content && (
            <div className="w-full mb-4 px-4 relative text-sm">
              <p
                ref={contentRef}
                className="text-gray-700 text-left whitespace-pre-line overflow-y-auto max-h-[100px] pr-2"
              >
                {content}
              </p>
              {isOverflow && (
                <div className="pointer-events-none absolute left-0 right-0 bottom-0 h-6 bg-gradient-to-t from-white to-transparent" />
              )}
            </div>
          )}
        </div>
        {/* 버튼 영역 */}
        <div className="flex flex-row gap-2 w-full mt-auto px-4 pb-4">
          <button
            className="flex-1 py-2 rounded bg-gray-200 text-gray-700 hover:bg-gray-300 transition-colors"
            onClick={onClose}
          >
            {t('label_popup_close')}
          </button>
          <button
            className="flex-1 py-2 rounded bg-primary text-white hover:bg-primary-dark transition-colors"
            onClick={onCloseFor7Days}
          >
            {t('label_popup_hide_7days')}
          </button>
        </div>
      </div>
    </div>
  );
};

export default VotePopup; 