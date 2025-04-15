export interface Board {
  board_id: string;
  name: Record<string, string>;
  description: string;
  created_at: string;
  parent_board_id: string | null;
  is_official: boolean;
  creator_id: string | null;
  artist_id: number;
  updated_at: string;
  status: string;
  request_message: string;
  order: number;
  features: string[];
  deleted_at: string | null;
}

export type BoardCreateInput = Omit<
  Board,
  'board_id' | 'created_at' | 'updated_at'
>;
export type BoardUpdateInput = Partial<BoardCreateInput>;
