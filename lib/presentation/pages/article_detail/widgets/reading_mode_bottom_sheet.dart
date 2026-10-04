import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/reading_mode_provider.dart';
import '../../../themes/app_theme.dart';

/// Okuma modu ayarları bottom sheet
class ReadingModeBottomSheet extends ConsumerWidget {
  const ReadingModeBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final readingMode = ref.watch(readingModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.chrome_reader_mode_rounded,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                Text(
                  'Okuma Modu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ref.read(readingModeProvider.notifier).resetToDefaults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Varsayılan ayarlara dönüldü'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Varsayılana Dön',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // İçerik
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Font Boyutu
                  _buildFontSizeSection(context, ref, readingMode),
                  const SizedBox(height: 24),

                  // Arka Plan Rengi
                  _buildBackgroundColorSection(context, ref, readingMode),
                  const SizedBox(height: 24),

                  // Satır Aralığı
                  _buildLineSpacingSection(context, ref, readingMode),
                  const SizedBox(height: 24),

                  // Gece Modu
                  _buildNightModeSection(context, ref, readingMode),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Font boyutu bölümü
  Widget _buildFontSizeSection(
    BuildContext context,
    WidgetRef ref,
    ReadingModeSettings readingMode,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.text_fields,
              size: 20,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              'Font Boyutu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${(readingMode.fontSize * 100).toInt()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              onPressed: () {
                ref.read(readingModeProvider.notifier).decreaseFontSize();
              },
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.primaryBlue,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.primaryBlue,
                  thumbColor: AppTheme.primaryBlue,
                  overlayColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  inactiveTrackColor: theme.colorScheme.outline.withValues(
                    alpha: 0.2,
                  ),
                ),
                child: Slider(
                  value: readingMode.fontSize,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  onChanged: (value) {
                    ref.read(readingModeProvider.notifier).setFontSize(value);
                  },
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(readingModeProvider.notifier).increaseFontSize();
              },
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        // Önizleme metni
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: readingMode.backgroundColorValue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'Önizleme: Bu metin ${(readingMode.fontSize * 100).toInt()}% boyutunda görünüyor.',
            style: TextStyle(
              fontSize: 16 * readingMode.fontSize,
              color: readingMode.textColorValue,
            ),
          ),
        ),
      ],
    );
  }

  /// Arka plan rengi bölümü
  Widget _buildBackgroundColorSection(
    BuildContext context,
    WidgetRef ref,
    ReadingModeSettings readingMode,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.palette, size: 20, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'Arka Plan Rengi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ReadingBackgroundColor.values.map((color) {
            final isSelected = readingMode.backgroundColor == color;
            final colorValue = _getColorPreview(color);
            final colorName = _getColorName(color);

            return GestureDetector(
              onTap: () {
                ref
                    .read(readingModeProvider.notifier)
                    .setBackgroundColor(color);
              },
              child: Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colorValue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Colors.purple
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getTextColor(color).withValues(alpha: 0.3),
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: _getTextColor(color),
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      colorName,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getTextColor(color),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Satır aralığı bölümü
  Widget _buildLineSpacingSection(
    BuildContext context,
    WidgetRef ref,
    ReadingModeSettings readingMode,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.format_line_spacing,
              size: 20,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              'Satır Aralığı',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LineSpacing.values.map((spacing) {
            final isSelected = readingMode.lineSpacing == spacing;
            final spacingName = _getLineSpacingName(spacing);

            return ChoiceChip(
              label: Text(spacingName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(readingModeProvider.notifier)
                      .setLineSpacing(spacing);
                }
              },
              selectedColor: Colors.orange.withValues(alpha: 0.3),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: isSelected ? Colors.orange.shade700 : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? Colors.orange
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Gece modu bölümü
  Widget _buildNightModeSection(
    BuildContext context,
    WidgetRef ref,
    ReadingModeSettings readingMode,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: readingMode.nightModeEnabled
            ? const Color(0xFF1A1A1A)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: readingMode.nightModeEnabled
              ? Colors.amber
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(
          Icons.nightlight_round,
          color: readingMode.nightModeEnabled ? Colors.amber : Colors.grey,
        ),
        title: Text(
          'Gece Modu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: readingMode.nightModeEnabled ? Colors.white : null,
          ),
        ),
        subtitle: Text(
          'Karanlık arka plan ile rahat okuma',
          style: TextStyle(
            color: readingMode.nightModeEnabled ? Colors.grey.shade400 : null,
          ),
        ),
        value: readingMode.nightModeEnabled,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.amber;
          }
          return null;
        }),
        onChanged: (value) {
          ref.read(readingModeProvider.notifier).toggleNightMode(value);
        },
      ),
    );
  }

  Color _getColorPreview(ReadingBackgroundColor color) {
    switch (color) {
      case ReadingBackgroundColor.white:
        return Colors.white;
      case ReadingBackgroundColor.beige:
        return const Color(0xFFF5F5DC);
      case ReadingBackgroundColor.sepia:
        return const Color(0xFFF4ECD8);
      case ReadingBackgroundColor.black:
        return const Color(0xFF000000);
      case ReadingBackgroundColor.nightMode:
        return const Color(0xFF1A1A1A);
    }
  }

  Color _getTextColor(ReadingBackgroundColor color) {
    if (color == ReadingBackgroundColor.black ||
        color == ReadingBackgroundColor.nightMode) {
      return Colors.white;
    }
    return Colors.black87;
  }

  String _getColorName(ReadingBackgroundColor color) {
    switch (color) {
      case ReadingBackgroundColor.white:
        return 'Beyaz';
      case ReadingBackgroundColor.beige:
        return 'Bej';
      case ReadingBackgroundColor.sepia:
        return 'Sepia';
      case ReadingBackgroundColor.black:
        return 'Siyah';
      case ReadingBackgroundColor.nightMode:
        return 'Gece';
    }
  }

  String _getLineSpacingName(LineSpacing spacing) {
    switch (spacing) {
      case LineSpacing.compact:
        return 'Dar';
      case LineSpacing.normal:
        return 'Normal';
      case LineSpacing.comfortable:
        return 'Rahat';
      case LineSpacing.wide:
        return 'Geniş';
    }
  }

  /// Bottom sheet'i göster
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReadingModeBottomSheet(),
    );
  }
}
