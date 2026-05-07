// Build-time configuration.
//
// The Anthropic API key is NEVER stored in the client. The Flutter app calls
// a Vercel serverless proxy at `/api/claude`, which injects the key from
// the ANTHROPIC_API_KEY environment variable on the server side.
//
// `claudeProxyUrl` resolves at build time from --dart-define:
//   flutter run         -> defaults to '/api/claude' (relative to host)
//   flutter build web   -> same default; works on Vercel deploy
//   override:           -> --dart-define=CLAUDE_PROXY_URL=https://example.com/api/claude
const String claudeProxyUrl = String.fromEnvironment(
  'CLAUDE_PROXY_URL',
  defaultValue: '/api/claude',
);
