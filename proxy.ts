import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'
import { ENV } from '@/utils/zod/serverEnvSchema';
import * as jose from 'jose'

const CLOUDFLARE_AUDIENCE_TAG = ENV.CF_AUDIENCE_TAG;
const CLOUDLARE_TEAM_DOMAIN = ENV.CF_TEAM_DOMAIN;
const CLOUDFLARE_TEAM_CERTS = `${CLOUDLARE_TEAM_DOMAIN}/cdn-cgi/access/certs`;

export async function proxy(request: NextRequest) {
  if (!request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  // TODO: Make this more secure?
  if (ENV.NODE_ENV === 'development') {
    return NextResponse.next();
  };

  const cloudflareAccessClientID = request.headers.get('cf-access-client-id');
  console.log('cloudflareAccessClientID', cloudflareAccessClientID);
  const cloudflareAccessClientSecret = request.headers.get('cf-access-client-secret');
  console.log('cloudflareAccessClientSecret', cloudflareAccessClientSecret);

  if (cloudflareAccessClientID === ENV.CF_ACCESS_CLIENT_ID && cloudflareAccessClientSecret === ENV.CF_ACCESS_CLIENT_SECRET) {
    return NextResponse.next();
  }

  const cloudflareJWT = request.headers.get('cf-access-jwt-assertion');
  console.log('cloudflareJWT', cloudflareJWT);

  if (cloudflareJWT) {
    try {
      const JWKS = jose.createRemoteJWKSet(new URL(CLOUDFLARE_TEAM_CERTS));
      await jose.jwtVerify(cloudflareJWT, JWKS, {
        issuer: ENV.CF_TEAM_DOMAIN,
        audience: CLOUDFLARE_AUDIENCE_TAG
      });
      return NextResponse.next();
    } catch (err) {
      console.error("JWT Verify Failed:", err);
    }
  }

  return new NextResponse(JSON.stringify({ error: 'Unauthorized Access' }), {
    status: 401,
    headers: { 'content-type': 'application/json' },
  });
}

export const config = {
  matcher: ['/api/:path*'],
};
