import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/interest_tags.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/interest_tag_chip.dart';
import '../../themes/app_theme.dart';

/// İlgi alanlarını düzenleme sayfası - Profilden erişilebilir
class EditInterestsPage extends ConsumerStatefulWidget {
  const EditInterestsPage({super.key});

  @override
  ConsumerState<EditInterestsPage> createState() => _EditInterestsPageState();
}

class _EditInterestsPageState extends ConsumerState<EditInterestsPage> {
  late List<String> _selectedTagIds;

  @override
  void initState() {
    super.initState();
    // Mevcut seçili tag'leri yükle
    final profile = ref.read(userProfileProvider).profile;
    _selectedTagIds = List<String>.from(
      profile?.preferences.interestTags ?? [],
    );
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  Future<void> _saveInterests() async {
    if (_selectedTagIds.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az 3 ilgi alanı seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profile = ref.read(userProfileProvider).profile;
    if (profile != null) {
      final updatedPreferences = profile.preferences.copyWith(
        interestTags: _selectedTagIds,
      );

      await ref
          .read(userProfileProvider.notifier)
          .updatePreferences(updatedPreferences);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlgi alanlarınız güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allTags = InterestTags.allTags;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlgi Alanlarım'),
        actions: [
          TextButton(
            onPressed: _saveInterests,
            child: const Text(
              'Kaydet',
              style: TextStyle(
                color: AppTheme.sageGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isDark ? AppTheme.matBlack : AppTheme.lightBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Açıklama
            Text(
              'Size özel haber akışı için ilgi alanlarınızı seçin. En az 3 ilgi alanı seçmelisiniz.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Seçim sayacı
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_selectedTagIds.length} / ${allTags.length} seçildi (Minimum: 3)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_selectedTagIds.length >= 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.sageGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.sageGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hazır',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.sageGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Hashtag'ler
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: allTags.map((tag) {
                final isSelected = _selectedTagIds.contains(tag.id);
                return InterestTagChip(
                  tag: tag,
                  isSelected: isSelected,
                  onTap: () => _toggleTag(tag.id),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
