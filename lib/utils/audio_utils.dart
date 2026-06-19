import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioUtils {
  static final AudioPlayer _player = AudioPlayer();
  
  // Reliable public notification sound from Google Actions sounds library
  static const String _notificationUrl = 'https://actions.google.com/sounds/v1/ui/message_notification.ogg';

  static Future<void> playNotificationSound() async {
    try {
      if (kIsWeb) {
        // For web, we might need to set the player to play even without interaction, but browsers may block it.
      }
      await _player.play(UrlSource(_notificationUrl), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }
}
