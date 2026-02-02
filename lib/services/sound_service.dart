import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _bgmPlayer = AudioPlayer();

  static Future<void> playSFX(String fileName) async {
    // Standard names: 'success.mp3', 'pop.mp3', 'wrong.mp3'
    await _sfxPlayer.play(AssetSource('sounds/$fileName'));
  }

  static Future<void> playBGM(String fileName) async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('sounds/$fileName'), volume: 0.3);
  }

  static void stopBGM() => _bgmPlayer.stop();
}