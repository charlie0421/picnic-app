import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

const supabase = createClient(supabaseUrl, supabaseKey);

export const createSupabaseClient = <T extends { id: string }>(
  tableName: string,
) => {
  return {
    getAll: async (): Promise<T[]> => {
      const { data, error } = await supabase
        .from(tableName)
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data;
    },

    getById: async (id: string): Promise<T> => {
      const { data, error } = await supabase
        .from(tableName)
        .select('*')
        .eq('id', id)
        .single();

      if (error) throw error;
      return data;
    },

    create: async (
      data: Omit<T, 'id' | 'created_at' | 'updated_at'>,
    ): Promise<T> => {
      const { data: newData, error } = await supabase
        .from(tableName)
        .insert(data)
        .select()
        .single();

      if (error) throw error;
      return newData;
    },

    update: async (
      id: string,
      data: Partial<Omit<T, 'id' | 'created_at' | 'updated_at'>>,
    ): Promise<T> => {
      const { data: updatedData, error } = await supabase
        .from(tableName)
        .update(data)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return updatedData;
    },

    delete: async (id: string): Promise<void> => {
      const { error } = await supabase.from(tableName).delete().eq('id', id);

      if (error) throw error;
    },
  };
};
