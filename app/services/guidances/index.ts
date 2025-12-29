import { SupabaseClient } from '@supabase/supabase-js';
import { Database } from '@/types/database';

export async function selectGuidancesService(supabase: SupabaseClient<Database>) {
  return await supabase
    .from('guidances')
    .select('*')
};
