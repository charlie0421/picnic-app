import React from 'react';

interface VotePopupProps {
  isOpen: boolean;
  onClose: () => void;
  onCloseFor7Days: () => void;
  imageUrl?: string;
  title?: string;
  content?: string;
}

const VotePopup: React.FC<VotePopupProps> = ({
  isOpen,
  onClose,
  onCloseFor7Days,
  imageUrl,
  title,
  content,
}) => {
  if (!isOpen) return null;

  console.log(title);
  console.log(content);
  console.log(imageUrl);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="bg-white rounded-lg shadow-lg p-6 w-full max-w-sm mx-4 flex flex-col items-center relative">
        {/* 닫기 버튼 */}
        <button
          className="absolute top-3 right-3 text-gray-400 hover:text-gray-600"
          onClick={onClose}
          aria-label="닫기"
        >
          <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
        {/* 이미지 */}
        {imageUrl && (
          <img src={imageUrl} alt="popup" className="w-32 h-32 object-contain mb-4 rounded" />
        )}
        {/* 타이틀 */}
        {title && <h2 className="text-lg font-bold mb-2 text-center text-black">{title}</h2>}
        {/* 설명 */}
        {content && <p className="text-gray-700 mb-4 text-center whitespace-pre-line">{content}</p>}
        {/* 버튼 영역 */}
        <div className="flex flex-col gap-2 w-full mt-2">
          <button
            className="w-full py-2 rounded bg-gray-200 text-gray-700 hover:bg-gray-300"
            onClick={onClose}
          >
            닫기
          </button>
          <button
            className="w-full py-2 rounded bg-primary text-white hover:bg-primary-dark"
            onClick={onCloseFor7Days}
          >
            7일간 보지 않기
          </button>
        </div>
      </div>
    </div>
  );
};

export default VotePopup; 