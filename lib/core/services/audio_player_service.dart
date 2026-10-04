import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

import 'package:flutter/foundation.dart';

/// Audio Player Service - Podcast ve ses haberleri için
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  // Getters
  AudioPlayer get player => _audioPlayer;
  bool get isInitialized => _isInitialized;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<double> get speedStream => _audioPlayer.speedStream;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  /// Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Audio session ayarları
      await _audioPlayer
          .setAudioSource(AudioSource.uri(Uri.parse(''), tag: null))
          .catchError((_) {
            // İlk başlatma için boş source
            return null;
          });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Audio player initialization error: $e');
      rethrow;
    }
  }

  /// Ses dosyasını yükle
  Future<Duration?> loadAudio(
    String url, {
    String? title,
    String? artist,
  }) async {
    try {
      await initialize();

      final duration = await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: url,
            title: title ?? 'Haber Podcast',
            artist: artist ?? 'Haber Merkezi',
            artUri: Uri.parse('https://via.placeholder.com/300'),
          ),
        ),
      );

      return duration;
    } catch (e) {
      debugPrint('Audio load error: $e');
      return null;
    }
  }

  /// Podcast playlist'i yükle
  Future<void> loadPlaylist(List<Map<String, String>> items) async {
    try {
      await initialize();

      final sources = items.map((item) {
        return AudioSource.uri(
          Uri.parse(item['url'] ?? ''),
          tag: MediaItem(
            id: item['url'] ?? '',
            title: item['title'] ?? 'Podcast',
            artist: item['artist'] ?? 'Haber Merkezi',
          ),
        );
      }).toList();

      await _audioPlayer.setAudioSources(sources);
    } catch (e) {
      debugPrint('Playlist load error: $e');
    }
  }

  /// Oynat
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Play error: $e');
    }
  }

  /// Duraklat
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Pause error: $e');
    }
  }

  /// Durdur
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Stop error: $e');
    }
  }

  /// Belirli pozisyona git
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Seek error: $e');
    }
  }

  /// Oynatma hızını ayarla
  Future<void> setSpeed(double speed) async {
    try {
      debugPrint('⚡ AudioService: Setting speed to $speed');
      await _audioPlayer.setSpeed(speed);
      debugPrint('⚡ AudioService: Speed set successfully');
    } catch (e) {
      debugPrint('⚡ AudioService: Set speed error: $e');
    }
  }

  /// Ses seviyesini ayarla (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      debugPrint('🎚️ AudioService: Setting volume to $volume');
      await _audioPlayer.setVolume(volume);
      debugPrint('🎚️ AudioService: Volume set successfully');
    } catch (e) {
      debugPrint('🎚️ AudioService: Set volume error: $e');
    }
  }

  /// Sonraki parça
  Future<void> seekToNext() async {
    try {
      await _audioPlayer.seekToNext();
    } catch (e) {
      debugPrint('Seek to next error: $e');
    }
  }

  /// Önceki parça
  Future<void> seekToPrevious() async {
    try {
      await _audioPlayer.seekToPrevious();
    } catch (e) {
      debugPrint('Seek to previous error: $e');
    }
  }

  /// Loop mode ayarla
  Future<void> setLoopMode(LoopMode loopMode) async {
    try {
      await _audioPlayer.setLoopMode(loopMode);
    } catch (e) {
      debugPrint('Set loop mode error: $e');
    }
  }

  /// Shuffle mode ayarla
  Future<void> setShuffleModeEnabled(bool enabled) async {
    try {
      await _audioPlayer.setShuffleModeEnabled(enabled);
    } catch (e) {
      debugPrint('Set shuffle mode error: $e');
    }
  }

  /// Mevcut pozisyonu al
  Duration get currentPosition => _audioPlayer.position;

  /// Toplam süreyi al
  Duration? get duration => _audioPlayer.duration;

  /// Oynatma durumunu al
  bool get isPlaying => _audioPlayer.playing;

  /// İşleniyor mu?
  bool get isProcessing =>
      _audioPlayer.processingState == ProcessingState.loading ||
      _audioPlayer.processingState == ProcessingState.buffering;

  /// Servisi temizle
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Dispose error: $e');
    }
  }

  /// Arka plan modu için MediaItem oluştur
  MediaItem createMediaItem({
    required String id,
    required String title,
    String? artist,
    String? album,
    Uri? artUri,
    Duration? duration,
  }) {
    return MediaItem(
      id: id,
      title: title,
      artist: artist ?? 'Haber Merkezi',
      album: album,
      artUri: artUri,
      duration: duration,
    );
  }
}
