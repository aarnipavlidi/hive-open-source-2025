import { NextResponse } from 'next/server'
import { createClient } from '@/utils/supabase/server'
import { selectGuidancesService } from '@/app/services/guidances'

export async function GET() {
  const supabase = await createClient();
  const { data, error } = await selectGuidancesService(supabase);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 })
  }

  return NextResponse.json({ success: true, data })
}
