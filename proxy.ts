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
  }

  const cloudflareJWT = request.headers.get('cf-access-jwt-assertion');

  if (!cloudflareJWT) {
    const errorResponse = {
      error: 'You are not authorized to access this resource, as you are missing token. Please try again later.'
    };

    return new NextResponse(JSON.stringify(errorResponse), {
      status: 401,
      headers: {
        'content-type': 'application/json'
      },
    });
  };

  try {
    const JWKS = jose.createRemoteJWKSet(new URL(CLOUDFLARE_TEAM_CERTS));
    await jose.jwtVerify(cloudflareJWT, JWKS, {
      issuer: CLOUDLARE_TEAM_DOMAIN,
      audience: CLOUDFLARE_AUDIENCE_TAG,
    });

    return NextResponse.next();
  } catch (err) {
    const errorResponse = {
      error: 'You are not authorized to access this resource, as your token may be invalid or expired. Please try again later.'
    };

    return new NextResponse(JSON.stringify(errorResponse), {
      status: 403,
      headers: { 'content-type': 'application/json' },
    });
  };
};


export const config = {
  matcher: ['/api/:path*'],
};
