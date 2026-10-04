import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data
/// Uses platform-specific secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage Keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyApiKey = 'api_key';
  static const String _keyEncryptionKey = 'encryption_key';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyPinCode = 'pin_code';

  /// Write a value to secure storage
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a value from secure storage
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Delete all values from secure storage
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Get all keys from secure storage
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }

  // Auth Token Methods
  Future<void> saveAuthToken(String token) async {
    await write(_keyAuthToken, token);
  }

  Future<String?> getAuthToken() async {
    return await read(_keyAuthToken);
  }

  Future<void> deleteAuthToken() async {
    await delete(_keyAuthToken);
  }

  // Refresh Token Methods
  Future<void> saveRefreshToken(String token) async {
    await write(_keyRefreshToken, token);
  }

  Future<String?> getRefreshToken() async {
    return await read(_keyRefreshToken);
  }

  Future<void> deleteRefreshToken() async {
    await delete(_keyRefreshToken);
  }

  // User ID Methods
  Future<void> saveUserId(String userId) async {
    await write(_keyUserId, userId);
  }

  Future<String?> getUserId() async {
    return await read(_keyUserId);
  }

  Future<void> deleteUserId() async {
    await delete(_keyUserId);
  }

  // User Email Methods
  Future<void> saveUserEmail(String email) async {
    await write(_keyUserEmail, email);
  }

  Future<String?> getUserEmail() async {
    return await read(_keyUserEmail);
  }

  Future<void> deleteUserEmail() async {
    await delete(_keyUserEmail);
  }

  // API Key Methods
  Future<void> saveApiKey(String apiKey) async {
    await write(_keyApiKey, apiKey);
  }

  Future<String?> getApiKey() async {
    return await read(_keyApiKey);
  }

  Future<void> deleteApiKey() async {
    await delete(_keyApiKey);
  }

  // Encryption Key Methods
  Future<void> saveEncryptionKey(String key) async {
    await write(_keyEncryptionKey, key);
  }

  Future<String?> getEncryptionKey() async {
    return await read(_keyEncryptionKey);
  }

  Future<void> deleteEncryptionKey() async {
    await delete(_keyEncryptionKey);
  }

  // Biometric Methods
  Future<void> setBiometricEnabled(bool enabled) async {
    await write(_keyBiometricEnabled, enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await read(_keyBiometricEnabled);
    return value == 'true';
  }

  // PIN Code Methods
  Future<void> savePinCode(String pin) async {
    await write(_keyPinCode, pin);
  }

  Future<String?> getPinCode() async {
    return await read(_keyPinCode);
  }

  Future<void> deletePinCode() async {
    await delete(_keyPinCode);
  }

  Future<bool> hasPinCode() async {
    return await containsKey(_keyPinCode);
  }

  Future<bool> verifyPinCode(String pin) async {
    final storedPin = await getPinCode();
    return storedPin == pin;
  }

  // Session Management
  Future<void> clearSession() async {
    await deleteAuthToken();
    await deleteRefreshToken();
    await deleteUserId();
    await deleteUserEmail();
  }

  Future<bool> hasValidSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // Custom Key-Value Storage
  Future<void> saveCustomValue(String key, String value) async {
    await write('custom_$key', value);
  }

  Future<String?> getCustomValue(String key) async {
    return await read('custom_$key');
  }

  Future<void> deleteCustomValue(String key) async {
    await delete('custom_$key');
  }
}
