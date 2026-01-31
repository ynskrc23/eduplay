import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();

  bool _isMuted = false;

  void setMute(bool mute) {
    _isMuted = mute;
    if (_isMuted) {
      _bgPlayer.pause();
    } else {
      _bgPlayer.resume();
    }
  }

  Future<void> playCorrect() async {
    if (_isMuted) return;
    try {
      await _effectPlayer.play(AssetSource('sounds/correct.mp3'));
    } catch (e) {
      debugPrint('🔊 Ses Çalma Hatası (Doğru): $e - Lütfen assets/sounds/correct.mp3 dosyasının varlığından emin olun.');
    }
  }

  Future<void> playWrong() async {
    if (_isMuted) return;
    try {
      await _effectPlayer.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      debugPrint('🔊 Ses Çalma Hatası (Yanlış): $e - Lütfen assets/sounds/wrong.mp3 dosyasının varlığından emin olun.');
    }
  }

  Future<void> playClick() async {
    if (_isMuted) return;
    try {
      await _effectPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      debugPrint('🔊 Ses Çalma Hatası (Tık): $e - Lütfen assets/sounds/click.mp3 dosyasının varlığından emin olun.');
    }
  }

  Future<void> startBgMusic() async {
    if (_isMuted) return;
    try {
      _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource('sounds/bg_music.mp3'));
      await _bgPlayer.setVolume(0.3);
    } catch (e) {
      debugPrint('🔊 Müzik Çalma Hatası (Arkaplan): $e - Lütfen assets/sounds/bg_music.mp3 dosyasının varlığından emin olun.');
    }
  }

  Future<void> stopBgMusic() async {
    await _bgPlayer.stop();
  }

  void dispose() {
    _effectPlayer.dispose();
    _bgPlayer.dispose();
  }
}
