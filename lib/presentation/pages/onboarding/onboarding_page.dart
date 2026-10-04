import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/interest_tags.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/interest_tag_chip.dart';
import '../../themes/app_theme.dart';

/// Onboarding ekranı - İlk girişte ilgi alanı seçimi
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    // Tüm tag'leri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider zaten hazır, ek işlem gerekmez
    });
  }

  Future<void> _handleComplete() async {
    final success = await ref
        .read(onboardingProvider.notifier)
        .completeOnboarding();

    if (success && mounted) {
      // Onboarding tamamlandı, ana sayfaya yönlendir
      // App.dart'ta otomatik olarak HomePage'e geçecek
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      // Hata durumunda snackbar göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(onboardingProvider).errorMessage ?? 'Bir hata oluştu',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allTags = InterestTags.allTags;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.matBlack : AppTheme.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Başlık
              Text(
                'İlgi Alanlarınızı Seçin',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Açıklama
              Text(
                'Size özel haber akışı oluşturmak için en az 3 ilgi alanı seçin. Daha sonra değiştirebilirsiniz.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Seçim sayacı
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                        '${onboardingState.selectedCount} / ${allTags.length} seçildi (Minimum: 3)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (onboardingState.canProceed)
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

              // Hashtag'ler - Wrap layout
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: allTags.map((tag) {
                  final isSelected = onboardingState.selectedTagIds.contains(
                    tag.id,
                  );
                  return InterestTagChip(
                    tag: tag,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(onboardingProvider.notifier).toggleTag(tag.id);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Devam Et butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      onboardingState.canProceed && !onboardingState.isLoading
                      ? _handleComplete
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.sageGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: onboardingState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Devam Et',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Bilgi metni
              Center(
                child: Text(
                  'Daha sonra profil ayarlarından değiştirebilirsiniz',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
