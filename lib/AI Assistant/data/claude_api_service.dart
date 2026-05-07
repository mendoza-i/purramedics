import 'dart:convert';
import 'package:http/http.dart' as http;

const String _systemPrompt = '''
You are Purramedics, a Veterinary Triage Reporting System.

IMPORTANT: Return ONE valid JSON object and NOTHING ELSE. Do not include
surrounding prose, headings, markdown, emojis, or asterisks. The JSON must
follow this schema exactly (example shown). If unsure, choose the more
conservative/serious triage level for safety.

Example output (must be valid JSON):
{
  "triage": "URGENT/EMERGENCY",
  "summary": "One-sentence summary of why (concise)",
  "action_plan": "Clear instruction when to seek veterinary care",
  "immediate_home_care": ["Step 1","Step 2","Step 3"],
  "potential_causes": ["Most serious cause","Second cause","Less likely cause"]
}

Rules:
- Output only valid JSON (object) with keys: triage, summary, action_plan,
  immediate_home_care, potential_causes.
- `triage` must be one of: "MILD", "MODERATE", "URGENT/EMERGENCY".
- `summary` must be a single concise sentence.
- `action_plan` must be a short directive (e.g., "Go to the emergency vet immediately.").
- `immediate_home_care` must be an array of 2-4 short steps (no medication dosing).
- `potential_causes` must be an array of 1-3 concise cause statements.
- Do not output any characters outside the JSON object.
''';

class ClaudeApiService {
  static const String _model = 'claude-sonnet-4-5-20250929';
  static const int _maxTokens = 1024;

  final String _proxyUrl;

  ClaudeApiService({required String proxyUrl}) : _proxyUrl = proxyUrl;

  Future<void> sendMessageStream(
    String content,
    Function(String textChunk) onChunk,
  ) async {
    final request = http.Request('POST', Uri.parse(_proxyUrl));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': _model,
      'max_tokens': _maxTokens,
      'stream': true,
      'temperature': 0.3,
      'system': _systemPrompt,
      'messages': [
        {'role': 'user', 'content': content},
      ],
    });

    try {
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        onChunk('\nError: API status ${streamedResponse.statusCode}\n$errorBody');
        return;
      }

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final jsonString = line.substring(6).trim();
            if (jsonString == '[DONE]') continue;
            try {
              final Map<String, dynamic> jsonData = jsonDecode(jsonString);
              if (jsonData['type'] == 'content_block_delta') {
                final delta = jsonData['delta'];
                if (delta != null && delta['text'] != null) {
                  onChunk(delta['text']);
                }
              }
            } catch (_) {
              continue;
            }
          }
        }
      }
    } catch (e) {
      onChunk('\nConnection Error: $e');
    }
  }
}
