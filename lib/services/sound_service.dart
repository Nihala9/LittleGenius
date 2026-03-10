import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();

  static Future<void> playSFX(String fileName) async {
    try {
      // Mandatory stop before play for MIUI stability
      await _sfxPlayer.stop(); 
      await _sfxPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint("SFX Error: $e");
    }
  }

  static Future<void> playBGM(String fileName) async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('sounds/$fileName'), volume: 0.2);
    } catch (e) {
      debugPrint("BGM Error: $e");
    }
  }

  static void stopBGM() => _bgmPlayer.stop();
}