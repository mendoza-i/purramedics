import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/claude_api_service.dart';
import '../model/message.dart';

import '../model/ai_report.dart';

class ChatProvider with ChangeNotifier {
  // Service used to call the AI. If not provided, construct one with an
  // empty API key (avoid embedding secrets in source). You can pass a
  // configured `ClaudeApiService` when creating the provider.
  final ClaudeApiService apiService;

  ChatProvider({ClaudeApiService? apiService})
    : apiService =
          apiService ?? ClaudeApiService(apiKey: '', proxyUrl: '/api/chat');

  final List<Message> _messages = [];
  bool _isLoading = false;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Message? get lastBotMessage {
    try {
      return _messages.lastWhere((m) => !m.isUser);
    } catch (_) {
      return null;
    }
  }

  // Parses the last bot message into a structured AiReport
  AiReport? get lastReport {
    final msg = lastBotMessage;
    if (msg == null || msg.content.isEmpty) return null;
    return _parseReport(msg.content);
  }

  AiReport _parseReport(String text) {
    // 1. Attempt to parse JSON response (The preferred format from ClaudeApiService)
    try {
      // Sometimes the AI might include markdown code blocks ```json ... ```
      // We strip them if present.
      String jsonString = text.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
      } else if (jsonString.startsWith('```')) {
        jsonString = jsonString.replaceAll('```', '').trim();
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);

      return AiReport(
        triage: data['triage'] ?? "Assessment Pending",
        summary: data['summary'] ?? "",
        actionPlan: data['action_plan'] ?? "Consult a veterinarian.",
        immediateHomeCare: List<String>.from(data['immediate_home_care'] ?? []),
        potentialCauses: List<String>.from(data['potential_causes'] ?? []),
      );
    } catch (e) {
      // 2. Fallback: If JSON parsing fails, treat as raw text or partial markdown
      // This handles cases where the AI might have refused the JSON constraint
      // or if the stream was interrupted.

      // We will just return a generic report with the full text in the summary
      // so the user at least sees the content.
      return AiReport(
        triage: "See Details Below",
        summary: text, // Put everything in summary so it displays
        actionPlan: "Review the full analysis above.",
        immediateHomeCare: [],
        potentialCauses: [],
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = Message(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    // Add placeholder bot message which we will update as chunks arrive
    final botTimestamp = DateTime.now();
    _messages.add(Message(content: '', isUser: false, timestamp: botTimestamp));
    notifyListeners();

    String currentResponse = '';

    try {
      await apiService.sendMessageStream(content, (textChunk) {
        currentResponse += textChunk;

        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.removeLast();
        }

        _messages.add(
          Message(
            content: currentResponse,
            isUser: false,
            timestamp: botTimestamp,
          ),
        );
        notifyListeners();
      });
    } catch (e) {
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages.removeLast();
      }
      _messages.add(
        Message(content: 'Error: $e', isUser: false, timestamp: DateTime.now()),
      );
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
