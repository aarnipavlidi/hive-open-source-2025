import 'server-only'
import { ENV } from '@/utils/zod/serverEnvSchema' // Import your typed env
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { Database } from '@/types/database'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    ENV.SUPABASE_URL,
    ENV.SUPABASE_ANON_KEY,
    {
      global: {
        headers: {
          'cf-access-client-id': ENV.CF_ACCESS_CLIENT_ID,
          'cf-access-client-secret': ENV.CF_ACCESS_CLIENT_SECRET,
        },
      },
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Handled by middleware
          }
        },
      },
    }
  )
}
