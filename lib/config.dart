// Build-time configuration.

// On web, the Vercel proxy handles the API key server-side.
// On native (Android/iOS/desktop), set your key here for local development only.
// NEVER commit a real key — use environment variables or a .env file.
const String claudeApiKey = '';

const String claudeProxyUrl = String.fromEnvironment(
  'CLAUDE_PROXY_URL',
  defaultValue: '/api/chat',
);
