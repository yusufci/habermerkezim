import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'providers.dart';

/// UserProfile State - profil durumunu tutar
class UserProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;

  const UserProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
  });

  UserProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get isEmpty => profile == null && !isLoading;
  bool get isError => errorMessage != null;
  bool get hasData => profile != null;
}

/// UserProfile StateNotifier - profil işlemlerini yönetir
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final UserProfileRepository _repository;

  UserProfileNotifier(this._repository) : super(const UserProfileState());

  /// Firebase Auth bilgilerini profil ile senkronize et
  Future<void> syncWithFirebaseAuth(User? firebaseUser) async {
    if (firebaseUser == null) return;

    try {
      // Mevcut profili al
      final currentProfile = await _repository.getProfile();

      // Firebase'den gelen bilgilerle güncelle
      final updatedProfile = currentProfile.copyWith(
        name: firebaseUser.displayName ?? currentProfile.name,
        email: firebaseUser.email ?? currentProfile.email,
        avatarUrl: firebaseUser.photoURL ?? currentProfile.avatarUrl,
      );

      // Profili kaydet
      await _repository.updateProfile(updatedProfile);
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      // Hata durumunda sadece log
      debugPrint('⚠️ Firebase Auth sync error: $e');
    }
  }

  /// Profili yükle ve Firebase Auth ile senkronize et
  Future<void> loadProfile({User? firebaseUser}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final profile = await _repository.getProfile();

      // Firebase User varsa bilgileri senkronize et
      if (firebaseUser != null) {
        final syncedProfile = profile.copyWith(
          name: firebaseUser.displayName ?? profile.name,
          email: firebaseUser.email ?? profile.email,
          avatarUrl: firebaseUser.photoURL ?? profile.avatarUrl,
        );

        // Eğer değişiklik varsa kaydet
        if (syncedProfile.name != profile.name ||
            syncedProfile.email != profile.email ||
            syncedProfile.avatarUrl != profile.avatarUrl) {
          await _repository.updateProfile(syncedProfile);
          state = state.copyWith(
            profile: syncedProfile,
            isLoading: false,
            errorMessage: null,
          );
        } else {
          state = state.copyWith(
            profile: profile,
            isLoading: false,
            errorMessage: null,
          );
        }
      } else {
        state = state.copyWith(
          profile: profile,
          isLoading: false,
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Profili güncelle
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _repository.updateProfile(profile);
      state = state.copyWith(profile: profile);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// İstatistikleri güncelle
  Future<void> refreshStats() async {
    try {
      await _repository.updateStatsFromAnalytics();
      // Profili yeniden yükle
      await loadProfile();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Tercihleri güncelle
  Future<void> updatePreferences(UserPreferences preferences) async {
    try {
      await _repository.updatePreferences(preferences);

      // Mevcut profili güncelle
      if (state.profile != null) {
        final updatedProfile = state.profile!.copyWith(
          preferences: preferences,
        );
        state = state.copyWith(profile: updatedProfile);
      } else {
        // Profil yoksa yükle
        await loadProfile();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Profil adını güncelle
  Future<void> updateName(String name) async {
    if (state.profile == null) {
      // Profil yoksa önce yükle
      await loadProfile();
      if (state.profile == null) return;
    }

    try {
      final updatedProfile = state.profile!.copyWith(
        name: name.isEmpty ? null : name,
      );
      await _repository.updateProfile(updatedProfile);
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// E-posta adresini güncelle
  Future<void> updateEmail(String email) async {
    if (state.profile == null) {
      await loadProfile();
      if (state.profile == null) return;
    }

    try {
      final updatedProfile = state.profile!.copyWith(
        email: email.isEmpty ? null : email,
      );
      await _repository.updateProfile(updatedProfile);
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Avatar URL'ini güncelle
  Future<void> updateAvatar(String? avatarUrl) async {
    if (state.profile == null) return;

    try {
      final updatedProfile = state.profile!.copyWith(avatarUrl: avatarUrl);
      await _repository.updateProfile(updatedProfile);
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Hata durumunu temizle
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// UserProfile provider - StateNotifierProvider
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
      final repository = ref.read(userProfileRepositoryProvider);
      return UserProfileNotifier(repository);
    });
