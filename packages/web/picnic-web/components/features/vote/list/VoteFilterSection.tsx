import React, { useCallback } from 'react';
import VoteStatusFilter from './VoteStatusFilter';
import VoteAreaFilter from './VoteAreaFilter';
import { useVoteFilterStore, VOTE_STATUS, VOTE_AREAS } from '@/stores/voteFilterStore';
import { useRouter, useSearchParams } from 'next/navigation';

const VoteFilterSection: React.FC = () => {
  const { selectedStatus, selectedArea, setSelectedStatus, setSelectedArea } = useVoteFilterStore();
  const router = useRouter();
  const searchParams = useSearchParams();

  // URL 파라미터 업데이트 함수
  const updateUrlParams = useCallback((status: typeof selectedStatus, area: typeof selectedArea) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set('status', status);
    params.set('area', area);
    router.push(`?${params.toString()}`, { scroll: false });
  }, [router, searchParams]);

  // 상태 변경 핸들러
  const handleStatusChange = useCallback((status: typeof selectedStatus) => {
    if (status === selectedStatus) return;
    setSelectedStatus(status);
    updateUrlParams(status, selectedArea);
  }, [selectedStatus, selectedArea, setSelectedStatus, updateUrlParams]);

  // 영역 변경 핸들러
  const handleAreaChange = useCallback((area: typeof selectedArea) => {
    if (area === selectedArea) return;
    setSelectedArea(area);
    updateUrlParams(selectedStatus, area);
  }, [selectedStatus, selectedArea, setSelectedArea, updateUrlParams]);

  return (
    <div className='flex justify-between items-center mb-4'>
      <div className='flex-1 flex justify-start'>
        <VoteAreaFilter
          selectedArea={selectedArea}
          onAreaChange={handleAreaChange}
        />
      </div>
      <div className='flex-1 flex justify-end'>
        <VoteStatusFilter
          selectedStatus={selectedStatus}
          onStatusChange={handleStatusChange}
        />
      </div>
    </div>
  );
};

export default VoteFilterSection; 