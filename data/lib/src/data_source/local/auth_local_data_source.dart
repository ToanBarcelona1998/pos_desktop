import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../model/auth_token_model.dart';
import '../../model/user_model.dart';

/// Local data source for authentication
abstract class AuthLocalDataSource {
  /// Gets stored token
  Future<AuthTokenModel?> getToken();

  /// Saves token
  Future<void> saveToken(AuthTokenModel token);

  /// Clears token
  Future<void> clearToken();

  /// Gets cached user
  Future<UserModel?> getCachedUser();

  /// Caches user
  Future<void> cacheUser(UserModel user);

  /// Clears cached user
  Future<void> clearCachedUser();

  /// Clears all auth data
  Future<void> clearAll();
}

/// Implementation of [AuthLocalDataSource] using SharedPreferences
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenTypeKey = 'token_type';
  static const _expiresInKey = 'expires_in';
  static const _userIdKey = 'user_id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<AuthTokenModel?> getToken() async {
    final prefs = await _prefs;
    final accessToken = prefs.getString(_tokenKey);
    if (accessToken == null) return null;

    return AuthTokenModel(
      accessToken: accessToken,
      refreshToken: prefs.getString(_refreshTokenKey),
      tokenType: prefs.getString(_tokenTypeKey),
      expiresIn: prefs.getInt(_expiresInKey),
    );
  }

  @override
  Future<void> saveToken(AuthTokenModel token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token.accessToken);
    if (token.refreshToken != null) {
      await prefs.setString(_refreshTokenKey, token.refreshToken!);
    }
    if (token.tokenType != null) {
      await prefs.setString(_tokenTypeKey, token.tokenType!);
    }
    if (token.expiresIn != null) {
      await prefs.setInt(_expiresInKey, token.expiresIn!);
    }
  }

  @override
  Future<void> clearToken() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_expiresInKey);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final prefs = await _prefs;
    final user = prefs.getString(_userIdKey);
    if (user == null) return null;

    // For more complex user caching, you might want to use a database
    return UserModel.fromJson(jsonDecode(user));
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final prefs = await _prefs;
    await prefs.setString(_userIdKey, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearCachedUser() async {
    final prefs = await _prefs;
    await prefs.remove(_userIdKey);
  }

  @override
  Future<void> clearAll() async {
    await clearToken();
    await clearCachedUser();
  }
}

