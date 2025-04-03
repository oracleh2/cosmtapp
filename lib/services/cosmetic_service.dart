import 'dart:io';
import 'package:skin_analyzer/services/api_service.dart';
import 'package:skin_analyzer/config/app_config.dart';
import 'package:flutter/foundation.dart';

class CosmeticService {
  final ApiService _apiService = ApiService();

  // Получение списка косметических продуктов
  Future<List<Map<String, dynamic>>> getCosmetics({Map<String, dynamic>? filters}) async {
    try {
      final response = await _apiService.get(
        AppConfig.cosmeticsEndpoint,
        queryParams: filters,
      );

      List<Map<String, dynamic>> cosmetics = [];
      for (var item in response['data']) {
        cosmetics.add(Map<String, dynamic>.from(item));
      }

      return cosmetics;
    } catch (e) {
      debugPrint('Error getting cosmetics: $e');
      rethrow;
    }
  }

  // Получение конкретного косметического продукта по ID
  Future<Map<String, dynamic>> getCosmetic(int cosmeticId) async {
    try {
      final response = await _apiService.get('${AppConfig.cosmeticsEndpoint}/$cosmeticId');
      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error getting cosmetic: $e');
      rethrow;
    }
  }

  // Создание нового косметического продукта
  Future<Map<String, dynamic>> createCosmetic(Map<String, dynamic> cosmeticData, {File? imageFile}) async {
    try {
      dynamic response;

      if (imageFile != null) {
        // Если есть изображение, используем multipart запрос
        response = await _apiService.uploadFile(
          AppConfig.cosmeticsEndpoint,
          imageFile,
          extraData: cosmeticData,
        );
      } else {
        // Если изображения нет, используем обычный JSON запрос
        response = await _apiService.post(
          AppConfig.cosmeticsEndpoint,
          data: cosmeticData,
        );
      }

      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error creating cosmetic: $e');
      rethrow;
    }
  }

  // Обновление косметического продукта
  Future<Map<String, dynamic>> updateCosmetic(int cosmeticId, Map<String, dynamic> cosmeticData, {File? imageFile}) async {
    try {
      dynamic response;

      if (imageFile != null) {
        // Если есть изображение, используем multipart запрос
        response = await _apiService.uploadFile(
          '${AppConfig.cosmeticsEndpoint}/$cosmeticId',
          imageFile,
          extraData: {...cosmeticData, '_method': 'PUT'}, // Laravel использует _method для указания метода при multipart
        );
      } else {
        // Если изображения нет, используем обычный JSON запрос
        response = await _apiService.put(
          '${AppConfig.cosmeticsEndpoint}/$cosmeticId',
          data: cosmeticData,
        );
      }

      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error updating cosmetic: $e');
      rethrow;
    }
  }

  // Удаление косметического продукта
  Future<void> deleteCosmetic(int cosmeticId) async {
    try {
      await _apiService.delete('${AppConfig.cosmeticsEndpoint}/$cosmeticId');
    } catch (e) {
      debugPrint('Error deleting cosmetic: $e');
      rethrow;
    }
  }

  // Анализ ингредиентов косметического продукта по изображению
  Future<Map<String, dynamic>> analyzeIngredients(File imageFile, {Map<String, dynamic>? options}) async {
    try {
      final response = await _apiService.uploadFile(
        AppConfig.analyzeIngredientsEndpoint,
        imageFile,
        extraData: options,
      );

      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error analyzing ingredients: $e');
      rethrow;
    }
  }
}