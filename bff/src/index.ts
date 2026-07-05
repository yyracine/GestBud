import { handleOtp } from './handlers/otp';
import { handleOcr } from './handlers/ocr';
import { handleCategorize } from './handlers/categorize';
import { handleScan } from './handlers/scan';

export interface Env {
  OTP_STORE: KVNamespace;
  AFRICA_TALKING_API_KEY: string;
  AFRICA_TALKING_USERNAME: string;
  MINDEE_API_KEY?: string;
  MISTRAL_API_KEY?: string;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      if (path === '/otp/send' || path === '/otp/verify') {
        return await handleOtp(request, env, path);
      }
      if (path === '/scan/receipt') {
        return await handleScan(request, env);
      }
      if (path === '/scan') {
        return await handleOcr(request, env);
      }
      if (path === '/categorize') {
        return await handleCategorize(request, env);
      }
      return json({ error: 'Not found' }, 404);
    } catch (err) {
      console.error('[BFF] Unhandled error:', err);
      return json({ error: 'Internal server error' }, 500);
    }
  },
};

export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
