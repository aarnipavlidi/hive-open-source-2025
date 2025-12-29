import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'
import { ENV } from '@/utils/zod/serverEnvSchema';
import * as jose from 'jose'

const CLOUDFLARE_AUDIENCE_TAG = ENV.CF_AUDIENCE_TAG;
const CLOUDLARE_TEAM_DOMAIN = ENV.CF_TEAM_DOMAIN;
const CLOUDFLARE_CERTS_URL = `${CLOUDLARE_TEAM_DOMAIN}/cdn-cgi/access/certs`;
const JWKS = jose.createRemoteJWKSet(new URL(CLOUDFLARE_CERTS_URL));

export async function proxy(request: NextRequest) {
  if (!request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  // TODO: Make this more secure?
  if (ENV.NODE_ENV === 'development') {
    return NextResponse.next();
  };

  const cloudflareJWT = request.headers.get('cf-access-jwt-assertion');

  if (cloudflareJWT) {
    try {
      await jose.jwtVerify(cloudflareJWT, JWKS, {
        issuer: CLOUDLARE_TEAM_DOMAIN,
        audience: CLOUDFLARE_AUDIENCE_TAG,
      });

      return NextResponse.next();
    } catch (error) {
      const errorResponse = {
        error: 'You are not authorized to access this resource, either your token is invalid or has expired.'
      };

      return new NextResponse(JSON.stringify(errorResponse), {
        status: 401,
        statusText: 'Unauthorized',
      });
    };
  };

  const errorResponse = {
    error: 'You are not authorized to access this resource.'
  };

  return new NextResponse(JSON.stringify(errorResponse), {
    status: 401,
    statusText: 'Unauthorized',
  });
};

export const config = {
  matcher: ['/api/:path*'],
};
