// lib/response.ts
import { createCorsHeaders } from './cors.ts';
import { logError } from './utils.ts';
export function createSuccessResponse(data, corsHeaders = {}) {
  const response = {
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
export function createErrorResponse(message, status = 400, code, details, corsHeaders = {}) {
  const response = {
    success: false,
    error: {
      message,
      code,
      details
    }
  };
  logError(new Error(message), {
    context: code || 'error-response',
    details
  });
  return new Response(JSON.stringify(response), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders
    }
  });
}
export function handleApiError(error, corsOptions) {
  const corsHeaders = corsOptions ? createCorsHeaders(null, corsOptions) : {};
  if (error instanceof TypeError) {
    return createErrorResponse('Invalid request data', 400, 'INVALID_REQUEST', {
      originalError: error.message
    }, corsHeaders);
  }
  if (error.name === 'PostgrestError') {
    return createErrorResponse('Database error occurred', 500, 'DATABASE_ERROR', {
      originalError: error.message
    }, corsHeaders);
  }
  return createErrorResponse('Internal server error', 500, 'INTERNAL_ERROR', {
    originalError: error.message
  }, corsHeaders);
}
