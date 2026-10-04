import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'hive_service.dart';
import '../../data/models/user_profile_model.dart';

/// Avatar yükleme ve yönetim servisi
/// Image picker, cropper ve local storage entegrasyonu sağlar
class AvatarService {
  static final AvatarService _instance = AvatarService._internal();
  factory AvatarService() => _instance;
  AvatarService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Avatar dizin adı
  static const String _avatarDirName = 'avatars';

  /// Kameradan fotoğraf çek
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      debugPrint('❌ Kameradan fotoğraf çekme hatası: $e');
      return null;
    }
  }

  /// Galeriden fotoğraf seç
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('❌ Galeriden fotoğraf seçme hatası: $e');
      return null;
    }
  }

  /// Fotoğrafı kırp
  Future<File?> cropImage(File imageFile) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Fotoğrafı Kırp',
            toolbarColor: const Color(0xFF1976D2),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Fotoğrafı Kırp',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
        ],
        compressQuality: 70,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      debugPrint('❌ Fotoğraf kırpma hatası: $e');
      return null;
    }
  }

  /// Avatar'ı kaydet ve user profile'ı güncelle
  Future<String?> saveAvatar(File imageFile, String userId) async {
    try {
      // Avatar dizinini oluştur
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory avatarDir = Directory(
        path.join(appDir.path, _avatarDirName),
      );

      if (!avatarDir.existsSync()) {
        await avatarDir.create(recursive: true);
      }

      // Yeni dosya adı oluştur (timestamp ile)
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(imageFile.path);
      final String fileName = 'avatar_${userId}_$timestamp$extension';
      final String newPath = path.join(avatarDir.path, fileName);

      // Dosyayı kopyala
      final File savedFile = await imageFile.copy(newPath);

      // Eski avatar'ı sil (varsa)
      await _deleteOldAvatar(userId);

      debugPrint('✅ Avatar kaydedildi: $newPath');
      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Avatar kaydetme hatası: $e');
      return null;
    }
  }

  /// User profile'ı avatar URL ile güncelle
  Future<bool> updateUserAvatar(String userId, String avatarPath) async {
    try {
      final userBox = HiveService.userProfileBox;

      // Mevcut profili al veya yeni oluştur
      UserProfileModel? currentProfile = userBox.get(userId);

      if (currentProfile == null) {
        // Yeni profil oluştur
        currentProfile = UserProfileModel(
          id: userId,
          avatarUrl: avatarPath,
          createdAt: DateTime.now(),
          stats: UserStatsModel.empty,
          preferences: UserPreferencesModel.defaultPreferences,
        );
      } else {
        // Mevcut profili güncelle
        currentProfile = UserProfileModel(
          id: currentProfile.id,
          name: currentProfile.name,
          email: currentProfile.email,
          avatarUrl: avatarPath,
          createdAt: currentProfile.createdAt,
          stats: currentProfile.stats,
          preferences: currentProfile.preferences,
        );
      }

      await userBox.put(userId, currentProfile);
      debugPrint('✅ User avatar güncellendi: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ User avatar güncelleme hatası: $e');
      return false;
    }
  }

  /// Avatar'ı sil
  Future<bool> deleteAvatar(String userId) async {
    try {
      // Eski avatar dosyasını sil
      await _deleteOldAvatar(userId);

      // User profile'dan avatar URL'i kaldır
      final userBox = HiveService.userProfileBox;
      final UserProfileModel? currentProfile = userBox.get(userId);

      if (currentProfile != null) {
        final updatedProfile = UserProfileModel(
          id: currentProfile.id,
          name: currentProfile.name,
          email: currentProfile.email,
          avatarUrl: null,
          createdAt: currentProfile.createdAt,
          stats: currentProfile.stats,
          preferences: currentProfile.preferences,
        );

        await userBox.put(userId, updatedProfile);
      }

      debugPrint('✅ Avatar silindi: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Avatar silme hatası: $e');
      return false;
    }
  }

  /// Eski avatar dosyasını sil
  Future<void> _deleteOldAvatar(String userId) async {
    try {
      final userBox = HiveService.userProfileBox;
      final UserProfileModel? currentProfile = userBox.get(userId);

      if (currentProfile?.avatarUrl != null) {
        final File oldFile = File(currentProfile!.avatarUrl!);
        if (oldFile.existsSync()) {
          await oldFile.delete();
          debugPrint('🗑️ Eski avatar silindi: ${currentProfile.avatarUrl}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Eski avatar silme hatası: $e');
    }
  }

  /// Avatar dosyasını al
  Future<File?> getAvatarFile(String userId) async {
    try {
      final userBox = HiveService.userProfileBox;
      final UserProfileModel? profile = userBox.get(userId);

      if (profile?.avatarUrl != null) {
        final File file = File(profile!.avatarUrl!);
        if (file.existsSync()) {
          return file;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Avatar dosyası alma hatası: $e');
      return null;
    }
  }

  /// Avatar byte array'i al (UI için)
  Future<Uint8List?> getAvatarBytes(String userId) async {
    try {
      final File? file = await getAvatarFile(userId);
      if (file != null) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Avatar bytes alma hatası: $e');
      return null;
    }
  }

  /// Kullanıcının avatar'ı var mı kontrol et
  Future<bool> hasAvatar(String userId) async {
    try {
      final File? file = await getAvatarFile(userId);
      return file != null;
    } catch (e) {
      return false;
    }
  }

  /// Tüm avatar dosyalarını temizle (cache temizleme için)
  Future<void> clearAllAvatars() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory avatarDir = Directory(
        path.join(appDir.path, _avatarDirName),
      );

      if (avatarDir.existsSync()) {
        await avatarDir.delete(recursive: true);
        debugPrint('🗑️ Tüm avatar dosyaları silindi');
      }
    } catch (e) {
      debugPrint('❌ Avatar temizleme hatası: $e');
    }
  }

  /// Avatar dosya boyutunu al (KB)
  Future<double?> getAvatarFileSize(String userId) async {
    try {
      final File? file = await getAvatarFile(userId);
      if (file != null) {
        final int bytes = await file.length();
        return bytes / 1024; // KB
      }
      return null;
    } catch (e) {
      debugPrint('❌ Avatar dosya boyutu alma hatası: $e');
      return null;
    }
  }
}
