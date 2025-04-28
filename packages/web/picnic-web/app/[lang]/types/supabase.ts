export type Database = {
    public: {
        Tables: {
            vote: {
                Row: {
                    id: number;
                    title: string;
                    created_at: string;
                    updated_at: string;
                    deleted_at: string | null;
                    start_at: string;
                    stop_at: string;
                };
                Insert: {
                    id?: number;
                    title: string;
                    created_at?: string;
                    updated_at?: string;
                    deleted_at?: string | null;
                    start_at: string;
                    stop_at: string;
                };
                Update: {
                    id?: number;
                    title?: string;
                    created_at?: string;
                    updated_at?: string;
                    deleted_at?: string | null;
                    start_at?: string;
                    stop_at?: string;
                };
            };
        };
    };
}; 