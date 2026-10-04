import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_controller.dart';

/// Gelişmiş Onboarding Ekranı - 4 sayfalık PageView tabanlı
class EnhancedOnboardingPage extends ConsumerStatefulWidget {
  const EnhancedOnboardingPage({super.key});

  @override
  ConsumerState<EnhancedOnboardingPage> createState() =>
      _EnhancedOnboardingPageState();
}

class _EnhancedOnboardingPageState
    extends ConsumerState<EnhancedOnboardingPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    ref.read(onboardingPageControllerProvider.notifier).setPage(page);
  }

  void _nextPage() {
    final state = ref.read(onboardingPageControllerProvider);
    if (state.isLastPage) {
      _completeOnboarding();
    } else {
      _goToPage(state.currentPage + 1);
    }
  }

  void _previousPage() {
    final state = ref.read(onboardingPageControllerProvider);
    if (state.currentPage > 0) {
      _goToPage(state.currentPage - 1);
    }
  }

  Future<void> _completeOnboarding() async {
    final success = await ref
        .read(onboardingPageControllerProvider.notifier)
        .completeOnboarding();

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir hata oluştu, lütfen tekrar deneyin'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingPageControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst kısım - Atla butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!state.isLastPage)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Atla',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Sayfa içeriği
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  ref
                      .read(onboardingPageControllerProvider.notifier)
                      .setPage(page);
                },
                children: [
                  _WelcomePage(),
                  _CategoriesPage(),
                  _NotificationsPage(),
                  _ReadyPage(),
                ],
              ),
            ),

            // Alt kısım - Dot indicator + Butonlar
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Dot indicator
                  _DotIndicator(currentPage: state.currentPage, totalPages: 4),
                  const SizedBox(height: 24),

                  // Butonlar
                  Row(
                    children: [
                      // Geri butonu
                      if (state.currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Geri'),
                          ),
                        ),
                      if (state.currentPage > 0) const SizedBox(width: 12),

                      // İleri / Başla butonu
                      Expanded(
                        flex: state.currentPage > 0 ? 2 : 1,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : _nextPage,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  state.isLastPage ? 'Başla' : 'Devam',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dot indicator widget
class _DotIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _DotIndicator({required this.currentPage, required this.totalPages});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Sayfa 1: Haberleri Keşfet - Uygulama tanıtımı
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.newspaper,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 40),

          // Başlık
          Text(
            'Haberleri Keşfet',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Açıklama
          Text(
            'Türkiye ve dünyadan en güncel haberleri tek bir uygulamada takip edin. '
            'RSS kaynakları ile kişiselleştirilmiş haber akışınızı oluşturun.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Özellik listesi
          const _FeatureItem(
            icon: Icons.bolt,
            text: 'Anlık haber bildirimleri',
          ),
          const SizedBox(height: 12),
          const _FeatureItem(
            icon: Icons.bookmark_border,
            text: 'Haberleri kaydet ve sonra oku',
          ),
          const SizedBox(height: 12),
          const _FeatureItem(
            icon: Icons.dark_mode,
            text: 'Karanlık mod desteği',
          ),
        ],
      ),
    );
  }
}

/// Sayfa 2: Kategorileri Seç
class _CategoriesPage extends ConsumerWidget {
  static const List<_CategoryItem> _categories = [
    _CategoryItem('genel', 'Gündem', Icons.public),
    _CategoryItem('turkiye', 'Türkiye', Icons.flag),
    _CategoryItem('ekonomi', 'Ekonomi', Icons.trending_up),
    _CategoryItem('teknoloji', 'Teknoloji', Icons.computer),
    _CategoryItem('spor', 'Spor', Icons.sports_soccer),
    _CategoryItem('dunya', 'Dünya', Icons.language),
    _CategoryItem('saglik', 'Sağlık', Icons.health_and_safety),
    _CategoryItem('bilim', 'Bilim', Icons.science),
    _CategoryItem('kultur', 'Kültür-Sanat', Icons.palette),
    _CategoryItem('magazin', 'Magazin', Icons.star),
    _CategoryItem('egitim', 'Eğitim', Icons.school),
    _CategoryItem('otomobil', 'Otomobil', Icons.directions_car),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingPageControllerProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Başlık
          Text(
            'Kategorileri Seç',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'İlgilendiğin kategorileri seçerek haber akışını kişiselleştir',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Kategori grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = state.selectedCategories.contains(
                  category.id,
                );

                return GestureDetector(
                  onTap: () => ref
                      .read(onboardingPageControllerProvider.notifier)
                      .toggleCategory(category.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          size: 32,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check_circle,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Seçim bilgisi
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${state.selectedCategories.length} kategori seçildi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sayfa 3: Bildirimleri Ayarla
class _NotificationsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingPageControllerProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 40),

          // Başlık
          Text(
            'Bildirimleri Ayarla',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Hangi bildirimleri almak istediğinizi seçin',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Bildirim seçenekleri
          _NotificationOption(
            icon: Icons.notifications,
            title: 'Genel Bildirimler',
            subtitle: 'Önemli haber güncellemeleri',
            value: state.notificationsEnabled,
            onChanged: (value) => ref
                .read(onboardingPageControllerProvider.notifier)
                .setNotificationsEnabled(value),
          ),
          const SizedBox(height: 16),
          _NotificationOption(
            icon: Icons.flash_on,
            title: 'Son Dakika Haberleri',
            subtitle: 'Anlık son dakika bildirimleri',
            value: state.breakingNewsEnabled,
            onChanged: (value) => ref
                .read(onboardingPageControllerProvider.notifier)
                .setBreakingNewsEnabled(value),
          ),
          const SizedBox(height: 16),
          _NotificationOption(
            icon: Icons.summarize,
            title: 'Günlük Özet',
            subtitle: 'Her sabah günün özetini alın',
            value: state.dailyDigestEnabled,
            onChanged: (value) => ref
                .read(onboardingPageControllerProvider.notifier)
                .setDailyDigestEnabled(value),
          ),

          const SizedBox(height: 16),

          Text(
            'Bu ayarları daha sonra değiştirebilirsiniz',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Sayfa 4: Hazırsınız!
class _ReadyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // İkon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 40),

          // Başlık
          Text(
            'Hazırsınız!',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Her şey tamam! Artık Haber Merkezi ile güncel haberleri takip etmeye başlayabilirsiniz.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Özet bilgiler
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                _SummaryItem(
                  icon: Icons.category,
                  text: 'Kategoriler ayarlandı',
                ),
                Divider(height: 24),
                _SummaryItem(
                  icon: Icons.notifications_active,
                  text: 'Bildirimler yapılandırıldı',
                ),
                Divider(height: 24),
                _SummaryItem(
                  icon: Icons.tune,
                  text: 'Kişiselleştirme tamamlandı',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Özellik satırı widget'ı
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bildirim seçenek widget'ı
class _NotificationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Özet bilgi satırı
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SummaryItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Kategori item data class
class _CategoryItem {
  final String id;
  final String name;
  final IconData icon;

  const _CategoryItem(this.id, this.name, this.icon);
}
