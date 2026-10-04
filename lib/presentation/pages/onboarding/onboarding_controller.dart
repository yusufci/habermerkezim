import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding durumu
class OnboardingPageState {
  final int currentPage;
  final List<String> selectedCategories;
  final bool notificationsEnabled;
  final bool breakingNewsEnabled;
  final bool dailyDigestEnabled;
  final bool isCompleted;
  final bool isLoading;

  const OnboardingPageState({
    this.currentPage = 0,
    this.selectedCategories = const [],
    this.notificationsEnabled = true,
    this.breakingNewsEnabled = true,
    this.dailyDigestEnabled = false,
    this.isCompleted = false,
    this.isLoading = false,
  });

  OnboardingPageState copyWith({
    int? currentPage,
    List<String>? selectedCategories,
    bool? notificationsEnabled,
    bool? breakingNewsEnabled,
    bool? dailyDigestEnabled,
    bool? isCompleted,
    bool? isLoading,
  }) {
    return OnboardingPageState(
      currentPage: currentPage ?? this.currentPage,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      breakingNewsEnabled: breakingNewsEnabled ?? this.breakingNewsEnabled,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Son sayfa mı kontrol
  bool get isLastPage => currentPage == 3;

  /// Kategori seçimi yeterli mi
  bool get hasEnoughCategories => selectedCategories.isNotEmpty;
}

/// Onboarding state notifier - Riverpod ile durum yönetimi
class OnboardingPageController extends StateNotifier<OnboardingPageState> {
  OnboardingPageController() : super(const OnboardingPageState());

  /// Sayfa değiştir
  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  /// Sonraki sayfaya git
  void nextPage() {
    if (state.currentPage < 3) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  /// Önceki sayfaya git
  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  /// Kategori seç/seçimi kaldır
  void toggleCategory(String category) {
    final current = List<String>.from(state.selectedCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(selectedCategories: current);
  }

  /// Bildirim ayarlarını güncelle
  void setNotificationsEnabled(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void setBreakingNewsEnabled(bool value) {
    state = state.copyWith(breakingNewsEnabled: value);
  }

  void setDailyDigestEnabled(bool value) {
    state = state.copyWith(dailyDigestEnabled: value);
  }

  /// Onboarding'i tamamla ve SharedPreferences ile kaydet
  Future<bool> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Onboarding tamamlanma durumu
      await prefs.setBool('onboarding_completed', true);

      // Seçilen kategoriler
      await prefs.setStringList(
        'selected_categories',
        state.selectedCategories,
      );

      // Bildirim tercihleri
      await prefs.setBool('notifications_enabled', state.notificationsEnabled);
      await prefs.setBool('breaking_news_enabled', state.breakingNewsEnabled);
      await prefs.setBool('daily_digest_enabled', state.dailyDigestEnabled);

      state = state.copyWith(isCompleted: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Onboarding tamamlanmış mı kontrol et
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
}

/// Onboarding controller provider
final onboardingPageControllerProvider =
    StateNotifierProvider<OnboardingPageController, OnboardingPageState>(
      (ref) => OnboardingPageController(),
    );

/// Onboarding tamamlanmış mı provider
final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  return OnboardingPageController.isOnboardingCompleted();
});
