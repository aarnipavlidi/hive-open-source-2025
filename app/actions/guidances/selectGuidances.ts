'use server'
import { createClient } from "@/utils/supabase/server"
import { selectGuidancesService } from "@/app/services/guidances"

export async function selectGuidancesAction() {
  const supabase = await createClient();
  const { data, error } = await selectGuidancesService(supabase);

  if (error) {
    return {
      success: false,
      error: error.message,
    };
  };

  return {
    success: true,
    data,
  };
};
