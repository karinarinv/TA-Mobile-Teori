import 'package:flutter/services.dart';

class GameAudioService {
  static const _channel = MethodChannel('com.rentbook.audio');

  static Future<void> playBgm() async {
    try {
      await _channel.invokeMethod('playBgm');
    } catch (_) {}
  }

  static Future<void> stopBgm() async {
    try {
      await _channel.invokeMethod('stopBgm');
    } catch (_) {}
  }

  static Future<void> playJumpscare() async {
    try {
      await _channel.invokeMethod('playJumpscare');
    } catch (_) {}
  }
}
