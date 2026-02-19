import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();

  // Play "Pop", "Ding", "Success"
  static Future<void> playSFX(String fileName) async {
    try {
      await _sfxPlayer.stop(); // Stop current effect to allow rapid play
      await _sfxPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      print("SFX Error: $e");
    }
  }

  // Play Background Forest Music
  static Future<void> playBGM(String fileName) async {
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.play(AssetSource('sounds/$fileName'), volume: 0.2);
    } catch (e) {
      print("BGM Error: $e");
    }
  }

  static void stopBGM() => _bgmPlayer.stop();
}