import 'package:flutter/services.dart';

/// Jembatan dari Flutter ke pemutar suara native melalui MethodChannel.
class GameAudioService {
  // Nama channel ini harus sama dengan handler pada kode platform Android/iOS.
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

  static Future<void> playChase() async {
    try {
      await _channel.invokeMethod('playChase');
    } catch (_) {}
  }

  static Future<void> stopChase() async {
    try {
      await _channel.invokeMethod('stopChase');
    } catch (_) {}
  }

  static Future<void> playTing() async {
    try {
      await _channel.invokeMethod('playTing');
    } catch (_) {}
  }

  static Future<void> playPageTurn() async {
    try {
      await _channel.invokeMethod('playPageTurn');
    } catch (_) {}
  }

  static Future<void> playJumpscare() async {
    try {
      await _channel.invokeMethod('playJumpscare');
    } catch (_) {}
  }

  static Future<void> stopJumpscare() async {
    try {
      await _channel.invokeMethod('stopJumpscare');
    } catch (_) {}
  }

  static Future<void> playWin() async {
    try {
      await _channel.invokeMethod('playWin');
    } catch (_) {}
  }

  static Future<void> playLose() async {
    try {
      await _channel.invokeMethod('playLose');
    } catch (_) {}
  }

  static Future<void> stopAll() async {
    try {
      await _channel.invokeMethod('stopAll');
    } catch (_) {}
  }
}
