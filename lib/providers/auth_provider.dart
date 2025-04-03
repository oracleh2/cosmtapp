import 'package:flutter/material.dart';
import 'package:skin_analyzer/models/user.dart';
import 'package:skin_analyzer/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Геттеры
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUser => _currentUser != null;

  // Проверка авторизации при запуске
  Future<bool> isAuthenticated() async {
    try {
      bool hasToken = await _authService.isAuthenticated();

      if (hasToken && _currentUser == null) {
        await getUserProfile();
      }

      return _currentUser != null;
    } catch (e) {
      return false;
    }
  }

  // Авторизация
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.login(email, password);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Регистрация
  Future<bool> register(String name, String email, String password, String passwordConfirmation) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.register(name, email, password, passwordConfirmation);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Выход из аккаунта
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Получение профиля
  Future<void> getUserProfile() async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.getProfile();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Обновление профиля
  Future<bool> updateProfile({
    String? name,
    String? skinType,
    List<String>? skinConcerns,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _authService.updateProfile(
        name: name,
        skinType: skinType,
        skinConcerns: skinConcerns,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Смена пароля
  Future<bool> changePassword(String currentPassword, String newPassword, String newPasswordConfirmation) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(currentPassword, newPassword, newPasswordConfirmation);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Вспомогательные методы
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}