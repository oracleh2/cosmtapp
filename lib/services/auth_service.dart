import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skin_analyzer/models/user.dart';
import 'package:skin_analyzer/services/api_service.dart';
import 'package:skin_analyzer/config/app_config.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Авторизация пользователя
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        AppConfig.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      // Сохраняем токен
      await _secureStorage.write(
        key: 'auth_token',
        value: response['token'],
      );

      // Возвращаем данные пользователя
      return User.fromJson(response['user']);
    } catch (e) {
      rethrow;
    }
  }

  // Регистрация нового пользователя
  Future<User> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      final response = await _apiService.post(
        AppConfig.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );

      // Сохраняем токен
      await _secureStorage.write(
        key: 'auth_token',
        value: response['token'],
      );

      // Возвращаем данные пользователя
      return User.fromJson(response['user']);
    } catch (e) {
      rethrow;
    }
  }

  // Выход из профиля
  Future<void> logout() async {
    try {
      // Делаем запрос на сервер для инвалидации токена
      await _apiService.post(AppConfig.logoutEndpoint);
    } catch (e) {
      // Игнорируем ошибки, так как токен будет удален в любом случае
    } finally {
      // Удаляем токен из хранилища
      await _secureStorage.delete(key: 'auth_token');
    }
  }

  // Получение данных профиля
  Future<User> getProfile() async {
    try {
      final response = await _apiService.get(AppConfig.userEndpoint);
      return User.fromJson(response['user']);
    } catch (e) {
      rethrow;
    }
  }

  // Проверка наличия токена (аутентификации)
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  // Обновление профиля пользователя
  Future<User> updateProfile({
    String? name,
    String? skinType,
    List<String>? skinConcerns,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (name != null) data['name'] = name;
      if (skinType != null) data['skin_type'] = skinType;
      if (skinConcerns != null) data['skin_concerns'] = skinConcerns;

      final response = await _apiService.put(
        AppConfig.updateProfileEndpoint,
        data: data,
      );

      return User.fromJson(response['user']);
    } catch (e) {
      rethrow;
    }
  }

  // Смена пароля
  Future<void> changePassword(String currentPassword, String newPassword, String newPasswordConfirmation) async {
    try {
      await _apiService.put(
        //TODO смену пароля реализовать
        '${AppConfig.updateProfileEndpoint}/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}