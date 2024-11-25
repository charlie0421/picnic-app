import { CorsOptions } from './types.ts';

const DEFAULT_CORS_OPTIONS: CorsOptions = {
    allowedOrigins: ['*'],
    allowedMethods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['authorization', 'x-client-info', 'apikey', 'content-type'],
    maxAge: 86400,
};

/**
 * Creates CORS headers based on the origin and provided options
 */
export function createCorsHeaders(
    origin: string | null,
    options: Partial<CorsOptions> = {},
): Record<string, string> {
    const allowedOrigins: string[] = options.allowedOrigins ??
        DEFAULT_CORS_OPTIONS.allowedOrigins ?? [];
    const allowedMethods: string[] = options.allowedMethods ??
        DEFAULT_CORS_OPTIONS.allowedMethods ?? [];
    const allowedHeaders: string[] = options.allowedHeaders ??
        DEFAULT_CORS_OPTIONS.allowedHeaders ?? [];
    const maxAge: number = options.maxAge ?? DEFAULT_CORS_OPTIONS.maxAge ?? 86400;

    const allowedOrigin = getAllowedOrigin(origin, allowedOrigins);

    return {
        'Access-Control-Allow-Origin': allowedOrigin,
        'Access-Control-Allow-Methods': allowedMethods.join(', '),
        'Access-Control-Allow-Headers': allowedHeaders.join(', '),
        'Access-Control-Max-Age': maxAge.toString(),
        'Vary': 'Origin',
        'Content-Type': 'application/json',
    };
}

/**
 * Determines the appropriate value for the Access-Control-Allow-Origin header
 */
function getAllowedOrigin(origin: string | null, allowedOrigins: string[]): string {
    if (!origin) {
        return '*';
    }

    // Picnic specific domains always allowed
    if (origin.endsWith('picnic.fan') || origin.endsWith('www.picnic.fan')) {
        return origin;
    }

    // If wildcard is allowed, return it
    if (allowedOrigins.includes('*')) {
        return '*';
    }

    // Check if the origin matches any of the allowed domains
    const isAllowed = allowedOrigins.some((allowed) => origin.endsWith(allowed));
    if (isAllowed) {
        return origin;
    }

    // Default to first allowed origin if no match
    return allowedOrigins[0] || '*';
}

/**
 * Creates a basic CORS response for OPTIONS requests
 */
export function createOptionsResponse(
    origin: string | null,
    options?: Partial<CorsOptions>,
): Response {
    return new Response(null, {
        status: 204,
        headers: createCorsHeaders(origin, options),
    });
}
