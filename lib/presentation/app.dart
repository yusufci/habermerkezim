import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/utils/app_logger.dart';
import 'providers/providers.dart';
import 'providers/locale_provider.dart';
import 'themes/app_theme.dart';
import 'pages/home/home_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/update/update_dialog.dart';
import '../core/services/update_service.dart';
import '../l10n/generated/app_localizations.dart';

/// Ana uygulama widget'ı - Haber Merkezi
/// Riverpod ile state management ve theme management
/// Material Design 3 Dynamic Color desteği ile
class HaberMerkeziApp extends ConsumerWidget {
  const HaberMerkeziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme durumunu izle
    final themeState = ref.watch(themeProvider);
    final themeMode = themeState.themeMode;
    final fontScale = themeState.fontScale;
    final colorTheme = themeState.colorTheme;

    // Locale durumunu izle
    final localeState = ref.watch(localeProvider);
    final currentLocale = localeState.locale;

    // App initialization durumunu izle
    final appInitialization = ref.watch(appInitializationProvider);

    // DynamicColorBuilder ile sistem renklerini al
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Dynamic color'ları provider'a kaydet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (lightDynamic != null && darkDynamic != null) {
            ref
                .read(dynamicColorProvider.notifier)
                .setDynamicColors(lightDynamic, darkDynamic);
          }
        });

        // Dynamic color kullanılıyorsa ve destekleniyorsa
        final effectiveLightDynamic = colorTheme == ColorTheme.dynamic
            ? lightDynamic
            : null;
        final effectiveDarkDynamic = colorTheme == ColorTheme.dynamic
            ? darkDynamic
            : null;

        return MaterialApp(
          title: 'Haber Merkezim',
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: false,

          // Tema ayarları - font scale, color theme ve dynamic color ile birlikte
          theme: AppTheme.getLightTheme(
            fontScale,
            colorTheme,
            effectiveLightDynamic,
          ),
          darkTheme: AppTheme.getDarkTheme(
            fontScale,
            colorTheme,
            effectiveDarkDynamic,
          ),
          themeMode: themeMode,

          // Localization ayarları
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'), // Türkçe
            Locale('en', 'US'), // İngilizce
          ],
          locale: currentLocale,

          // Ana sayfa - initialization ve authentication durumuna göre
          home: appInitialization.when(
            data: (_) {
              // Authentication kontrolü yap - DEVRE DIŞI BIRAKILDI (Açık kaynak için)
              return const _OnboardingCheckWrapper(
                child: _UpdateCheckWrapper(child: HomePage()),
              );
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) {
              AppLogger.error('App initialization hatasi', error, stackTrace);
              return ErrorPage(
                error: error,
                onRetry: () {
                  ref.invalidate(appInitializationProvider);
                },
              );
            },
          ),

          // Route ayarları
          routes: {
            '/home': (context) => const HomePage(),
            '/onboarding': (context) => const OnboardingPage(),
            '/login': (context) => const LoginPage(),
          },

          // App boyut ve orientation ayarları
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                // Font scale'i provider'dan alınan değerle sınırla
                textScaler: TextScaler.linear(fontScale.clamp(0.8, 1.6)),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

/// Hata sayfası - uygulama başlatılamadığında gösterilir
class ErrorPage extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorPage({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hata ikonu
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),

              const SizedBox(height: 32),

              // Başlık
              Text(
                'Bir sorun oluştu',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Açıklama
              Text(
                'Haber Merkezi başlatılırken bir hata oluştu. Lütfen tekrar deneyin.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Hata detayı (debug modda)
              if (error.toString().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 40),

              // Yeniden dene butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // İptal butonu
              TextButton(
                onPressed: () {
                  // Uygulamayı kapat
                  SystemNavigator.pop();
                },
                child: Text(
                  'Uygulamayı Kapat',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Güncelleme kontrolü wrapper widget'ı
/// HomePage'e geçmeden önce güncelleme kontrolü yapar
class _UpdateCheckWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const _UpdateCheckWrapper({required this.child});

  @override
  ConsumerState<_UpdateCheckWrapper> createState() =>
      _UpdateCheckWrapperState();
}

class _UpdateCheckWrapperState extends ConsumerState<_UpdateCheckWrapper> {
  bool _hasCheckedUpdate = false;

  @override
  void initState() {
    super.initState();
    // Widget mount olduktan sonra güncelleme kontrolü yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    if (_hasCheckedUpdate) return;
    _hasCheckedUpdate = true;

    try {
      // Güncelleme kontrolü yap (non-blocking)
      final updateResult = await ref.read(checkForUpdatesProvider.future);

      if (updateResult != null && mounted) {
        // Güncelleme mevcut, dialog göster
        showDialog(
          context: context,
          barrierDismissible:
              updateResult.type != UpdateType.immediate &&
              !(updateResult.updateInfo?.forceUpdate ?? false),
          builder: (context) => UpdateDialog(
            updateResult: updateResult,
            onUpdateComplete: () {
              // Güncelleme tamamlandığında callback
            },
          ),
        );
      }
    } catch (e) {
      AppLogger.warning('Güncelleme kontrolü hatası: $e');
      // Hata durumunda sessizce devam et
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Onboarding kontrolü wrapper widget'ı
/// İlk giriş kontrolü yapar, onboarding tamamlanmamışsa OnboardingPage gösterir
class _OnboardingCheckWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const _OnboardingCheckWrapper({required this.child});

  @override
  ConsumerState<_OnboardingCheckWrapper> createState() =>
      _OnboardingCheckWrapperState();
}

class _OnboardingCheckWrapperState
    extends ConsumerState<_OnboardingCheckWrapper> {
  bool? _hasCompletedOnboarding;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Hemen kontrol et, gecikme olmadan
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      // Timeout ekle - maksimum 500ms bekle
      final result = await ref
          .read(hasCompletedOnboardingProvider.future)
          .timeout(const Duration(milliseconds: 500), onTimeout: () => true);
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.warning('Onboarding kontrolü hatası: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading durumunda kısa bir süre bekle, sonra child'ı göster
    if (_isLoading) {
      // 100ms sonra otomatik olarak child'a geç
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
            _hasCompletedOnboarding = true; // Varsayılan olarak tamamlanmış say
          });
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError || _hasCompletedOnboarding == true) {
      return widget.child;
    }

    return const OnboardingPage();
  }
}
