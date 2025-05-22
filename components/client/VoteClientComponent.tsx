'use client';

import React, { useState } from 'react';

// 투표 데이터 타입
interface Vote {
  id: number;
  title: string;
  description: string;
  created_at: string;
  updated_at: string;
  [key: string]: any;
}

interface VoteClientComponentProps {
  votes: Vote[];
}

/**
 * 투표 데이터를 표시하고 상호작용하는 클라이언트 컴포넌트
 * 
 * 이 컴포넌트는 서버 컴포넌트에서 가져온 데이터를 받아
 * 클라이언트 상호작용(정렬, 필터링, 클릭 이벤트 등)을 처리합니다.
 */
export default function VoteClientComponent({ votes }: VoteClientComponentProps) {
  const [selectedVote, setSelectedVote] = useState<Vote | null>(null);
  const [sortOrder, setSortOrder] = useState<'newest' | 'oldest'>('newest');
  
  // 정렬된 투표 목록
  const sortedVotes = [...votes].sort((a, b) => {
    const dateA = new Date(a.created_at).getTime();
    const dateB = new Date(b.created_at).getTime();
    return sortOrder === 'newest' ? dateB - dateA : dateA - dateB;
  });
  
  // 투표 선택 핸들러
  const handleVoteSelect = (vote: Vote) => {
    setSelectedVote(vote);
  };
  
  // 정렬 순서 변경 핸들러
  const toggleSortOrder = () => {
    setSortOrder(prev => prev === 'newest' ? 'oldest' : 'newest');
  };
  
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-bold">투표 목록</h2>
        <button
          onClick={toggleSortOrder}
          className="px-3 py-1 bg-gray-100 hover:bg-gray-200 rounded text-sm transition-colors"
        >
          {sortOrder === 'newest' ? '최신순' : '오래된순'} ↓
        </button>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* 투표 목록 */}
        <div className="border rounded-lg overflow-hidden">
          {sortedVotes.length === 0 ? (
            <p className="p-4 text-gray-500">표시할 투표가 없습니다.</p>
          ) : (
            <ul className="divide-y">
              {sortedVotes.map(vote => (
                <li 
                  key={vote.id}
                  className={`p-4 cursor-pointer transition-colors ${
                    selectedVote?.id === vote.id ? 'bg-primary/10' : 'hover:bg-gray-50'
                  }`}
                  onClick={() => handleVoteSelect(vote)}
                >
                  <h3 className="font-semibold">{vote.title}</h3>
                  <p className="text-sm text-gray-600 mt-1 line-clamp-2">{vote.description}</p>
                  <div className="text-xs text-gray-500 mt-1">
                    {new Date(vote.created_at).toLocaleDateString()}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
        
        {/* 선택된 투표 상세 정보 */}
        <div className="border rounded-lg p-4">
          {selectedVote ? (
            <div>
              <h3 className="text-lg font-bold">{selectedVote.title}</h3>
              <p className="mt-3 text-gray-600">{selectedVote.description}</p>
              <div className="mt-4 text-sm text-gray-500">
                생성일: {new Date(selectedVote.created_at).toLocaleDateString()}
                <br />
                마지막 수정: {new Date(selectedVote.updated_at).toLocaleDateString()}
              </div>
              <div className="mt-6">
                <button className="px-4 py-2 bg-primary text-white rounded hover:bg-primary/80 transition-colors">
                  투표 참여하기
                </button>
              </div>
            </div>
          ) : (
            <div className="h-full flex items-center justify-center text-gray-500">
              좌측에서 투표를 선택해주세요
            </div>
          )}
        </div>
      </div>
      
      <div className="mt-6 text-sm text-gray-500">
        <p>
          <strong>참고:</strong> 이 컴포넌트는 클라이언트 측에서 실행되며, 서버 컴포넌트에서 받은 
          데이터를 사용자 상호작용과 함께 처리합니다.
        </p>
      </div>
    </div>
  );
} 