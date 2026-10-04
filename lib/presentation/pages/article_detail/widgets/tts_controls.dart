import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/text_to_speech_service.dart';
import '../../../../domain/entities/article.dart';
import '../../../themes/app_theme.dart';

/// TTS kontrolleri widget'ı - Mini Player tasarımı
class TtsControls extends ConsumerStatefulWidget {
  final Article article;

  const TtsControls({super.key, required this.article});

  @override
  ConsumerState<TtsControls> createState() => _TtsControlsState();
}

class _TtsControlsState extends ConsumerState<TtsControls> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _ttsService.init();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized) {
      await _initializeTts();
    }

    if (_isPlaying && !_isPaused) {
      await _ttsService.pause();
      setState(() {
        _isPaused = true;
      });
    } else if (_isPaused) {
      await _ttsService.resume();
      setState(() {
        _isPaused = false;
      });
    } else {
      // Metni hazırla ve oynat
      final text = _prepareText();
      await _ttsService.speak(text);
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
    }
  }

  Future<void> _stop() async {
    await _ttsService.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });
  }

  String _prepareText() {
    // HTML tag'lerini temizle
    String text = widget.article.content ?? widget.article.description;
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini Player - Her zaman görünür (60px yükseklik)
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Play/Pause butonu
                      IconButton(
                        icon: Icon(
                          _isPlaying && !_isPaused
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: _togglePlayPause,
                        iconSize: 28,
                        color: AppTheme.primaryBlue,
                      ),

                      const SizedBox(width: 12),

                      // Başlık ve bilgi
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sesli Okuma',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isPlaying
                                  ? (_isPaused ? 'Duraklatıldı' : 'Oynatılıyor')
                                  : 'Hazır',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stop butonu
                      if (_isPlaying)
                        IconButton(
                          icon: const Icon(Icons.stop_rounded),
                          onPressed: _stop,
                          color: Colors.red,
                        ),

                      // Expand/Collapse butonu
                      IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.expand_more : Icons.expand_less,
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Genişletilmiş kontroller
              if (_isExpanded) ...[
                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Hız kontrolü
                      _buildExpandedSlider(
                        context,
                        label: 'Hız',
                        icon: Icons.speed_rounded,
                        value: _ttsService.speechRate,
                        min: 0.25,
                        max: 1.0,
                        divisions: 15,
                        onChanged: (value) {
                          _ttsService.setSpeechRate(value);
                          setState(() {});
                        },
                        formatValue: (value) => '${(value * 100).toInt()}%',
                      ),

                      const SizedBox(height: 16),

                      // Ses seviyesi kontrolü
                      _buildExpandedSlider(
                        context,
                        label: 'Ses Seviyesi',
                        icon: Icons.volume_up_rounded,
                        value: _ttsService.volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (value) {
                          _ttsService.setVolume(value);
                          setState(() {});
                        },
                        formatValue: (value) => '${(value * 100).toInt()}%',
                      ),

                      const SizedBox(height: 16),

                      // Hızlı erişim butonları
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickButton(
                            context,
                            icon: Icons.replay_10,
                            label: '10s Geri',
                            onTap: () {
                              // Not: TTS servisi bunu desteklemiyorsa boş bırakılabilir
                            },
                          ),
                          _buildQuickButton(
                            context,
                            icon: Icons.forward_10,
                            label: '10s İleri',
                            onTap: () {
                              // Not: TTS servisi bunu desteklemiyorsa boş bırakılabilir
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Hızlı erişim butonu
  Widget _buildQuickButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// Genişletilmiş slider widget'ı
  Widget _buildExpandedSlider(
    BuildContext context, {
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) formatValue,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formatValue(value),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryBlue,
            inactiveTrackColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
            thumbColor: AppTheme.primaryBlue,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
