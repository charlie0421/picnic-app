import React from 'react';
import Image from 'next/image';
import {VoteItem} from '@/types/interfaces';
import {getLocalizedString} from '@/utils/api/strings';

interface VoteDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onVote: () => void;
  selectedArtist: VoteItem | null;
  votes: number;
  setVotes: (votes: number) => void;
}

const VoteDialog: React.FC<VoteDialogProps> = ({
  isOpen,
  onClose,
  onVote,
  selectedArtist,
  votes,
  setVotes,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-bold">투표하기</h3>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        {selectedArtist && (
          <div className="mb-6">
            <div className="flex items-center space-x-4">
              <div className="w-16 h-16 rounded-full overflow-hidden border-2 border-white shadow-sm">
                {selectedArtist.artist?.image ? (
                  <Image
                    src={`${process.env.NEXT_PUBLIC_CDN_URL}/${selectedArtist.artist.image}`}
                    alt={getLocalizedString(selectedArtist.artist.name)}
                    width={64}
                    height={64}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full bg-gray-200 flex items-center justify-center">
                    <span className="text-gray-600 text-xs">No</span>
                  </div>
                )}
              </div>
              <div>
                <p className="font-bold text-lg">
                  {getLocalizedString(selectedArtist.artist?.name)}
                </p>
                <p className="text-sm text-gray-600">
                  {getLocalizedString(selectedArtist.artist?.artist_group?.name)}
                </p>
              </div>
            </div>
          </div>
        )}

        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            투표 수
          </label>
          <div className="flex items-center space-x-4">
            <button
              onClick={() => setVotes(Math.max(1, votes - 1))}
              className="p-2 rounded-full bg-gray-100 hover:bg-gray-200"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M20 12H4"
                />
              </svg>
            </button>
            <input
              type="number"
              min="1"
              value={votes}
              onChange={(e) => setVotes(Math.max(1, parseInt(e.target.value) || 1))}
              className="w-20 text-center border rounded-lg p-2"
            />
            <button
              onClick={() => setVotes(votes + 1)}
              className="p-2 rounded-full bg-gray-100 hover:bg-gray-200"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 4v16m8-8H4"
                />
              </svg>
            </button>
          </div>
        </div>

        <div className="flex justify-end space-x-4">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-600 hover:text-gray-800"
          >
            취소
          </button>
          <button
            onClick={onVote}
            className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark"
          >
            투표하기
          </button>
        </div>
      </div>
    </div>
  );
};

export default VoteDialog;
