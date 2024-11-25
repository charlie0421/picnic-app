// lib/response.ts

import { ApiResponse, CorsOptions } from './types.ts';
import { createCorsHeaders } from './cors.ts';
import { logError } from './utils.ts';

export function createSuccessResponse<T>(
  data: T,
  corsHeaders: Record<string, string> = {}
): Response {
  const response: ApiResponse<T> = {
    success: true,
    data
  };

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders
    }
  });
}

export function createErrorResponse(
  message: string,
  status = 400,
  code?: string,
  details?: unknown,
  corsHeaders: Record<string, string> = {}
): Response {
  const response: ApiResponse = {
    success: false,
    error: {
      message,
      code,
      details
    }
  };

  logError(new Error(message), { context: code || 'error-response', details });

  return new Response(JSON.stringify(response), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders
    }
  });
}

export function handleApiError(
  error: Error,
  corsOptions?: CorsOptions
): Response {
  const corsHeaders = corsOptions ? createCorsHeaders(null, corsOptions) : {};
  
  if (error instanceof TypeError) {
    return createErrorResponse(
      'Invalid request data',
      400,
      'INVALID_REQUEST',
      { originalError: error.message },
      corsHeaders
    );
  }

  if (error.name === 'PostgrestError') {
    return createErrorResponse(
      'Database error occurred',
      500,
      'DATABASE_ERROR',
      { originalError: error.message },
      corsHeaders
    );
  }

  return createErrorResponse(
    'Internal server error',
    500,
    'INTERNAL_ERROR',
    { originalError: error.message },
    corsHeaders
  );
}
