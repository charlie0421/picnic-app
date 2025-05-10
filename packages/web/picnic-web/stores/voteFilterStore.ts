import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export const VOTE_STATUS = {
  UPCOMING: 'upcoming',
  ONGOING: 'ongoing',
  COMPLETED: 'completed',
} as const;

export const VOTE_AREAS = {
  KPOP: 'kpop',
  MUSICAL: 'musical',
} as const;

export type VoteStatus = (typeof VOTE_STATUS)[keyof typeof VOTE_STATUS];
export type VoteArea = (typeof VOTE_AREAS)[keyof typeof VOTE_AREAS];

interface VoteFilterState {
  selectedStatus: VoteStatus;
  selectedArea: VoteArea;
  setSelectedStatus: (status: VoteStatus) => void;
  setSelectedArea: (area: VoteArea) => void;
}

export const useVoteFilterStore = create<VoteFilterState>()(
  persist(
    (set) => ({
      selectedStatus: VOTE_STATUS.ONGOING,
      selectedArea: VOTE_AREAS.KPOP,
      setSelectedStatus: (status) => set({ selectedStatus: status }),
      setSelectedArea: (area) => set({ selectedArea: area }),
    }),
    {
      name: 'vote-filter-storage',
    }
  )
); 