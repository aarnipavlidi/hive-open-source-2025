import z from 'zod';

const envSchema = z.object({
    CF_ACCESS_CLIENT_ID: z.string().trim().min(1),
    CF_ACCESS_CLIENT_SECRET: z.string().trim().min(1),
    CF_AUDIENCE_TAG: z.string().trim().min(1),
    CF_TEAM_DOMAIN: z.url(),
    SUPABASE_URL: z.url(),
    SUPABASE_ANON_KEY: z.string().trim().min(1),
    PORT: z.coerce.number().default(3000),
    NODE_ENV: z
        .enum(['development', 'staging', 'production'])
        .default('development'),
});

const serverEnv = envSchema.safeParse(process.env);

if (!serverEnv.success) {
    // TODO: Fix this "format" deprecation issue.
    console.error('❌ Invalid environment variables:', serverEnv.error.format());
    throw new Error('There is an error with the server environment variables');
}

export const ENV = serverEnv.data;
