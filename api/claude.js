// Vercel serverless proxy for the Anthropic Messages API.
// Keeps ANTHROPIC_API_KEY out of the client bundle.
//
// Required env var (set in Vercel project settings):
//   ANTHROPIC_API_KEY = sk-ant-...
//
// Optional env var:
//   ALLOWED_ORIGIN = https://your-app.vercel.app   (defaults to "*" — tighten before launch)

export const config = { runtime: 'edge' };

const ANTHROPIC_URL = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';

export default async function handler(req) {
  const allowOrigin = process.env.ALLOWED_ORIGIN || '*';
  const corsHeaders = {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Vary': 'Origin',
  };

  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: corsHeaders });
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return new Response(JSON.stringify({ error: 'Server misconfigured: ANTHROPIC_API_KEY missing' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  let payload;
  try {
    payload = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const upstream = await fetch(ANTHROPIC_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': ANTHROPIC_VERSION,
    },
    body: JSON.stringify(payload),
  });

  return new Response(upstream.body, {
    status: upstream.status,
    headers: {
      ...corsHeaders,
      'Content-Type': upstream.headers.get('content-type') || 'text/event-stream',
      'Cache-Control': 'no-cache',
    },
  });
}
