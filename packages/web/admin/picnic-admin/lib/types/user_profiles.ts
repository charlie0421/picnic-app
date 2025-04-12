import { VotePick } from './vote';

export interface UserProfile {
  id: string;
  avatar_url?: string;
  created_at: string;
  updated_at: string;
  star_candy: number;
  nickname?: string;
  deleted_at?: string;
  email?: string;
  star_candy_bonus: number;
  birth_date?: string;
  gender?: 'male' | 'female';
  open_ages: boolean;
  open_gender: boolean;
  is_admin: boolean;
  birth_time?: string;
  vote_picks?: VotePick[];
}

export enum UserGender {
  MALE = 'male',
  FEMALE = 'female',
}

export const genderOptions = [
  { label: '남성', value: UserGender.MALE },
  { label: '여성', value: UserGender.FEMALE },
]; 