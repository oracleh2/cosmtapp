import 'dart:io';
import 'package:skin_analyzer/models/skin_analysis.dart';
import 'package:skin_analyzer/models/cosmetic_product.dart';
import 'package:skin_analyzer/services/api_service.dart';
import 'package:skin_analyzer/config/app_config.dart';
import 'package:flutter/foundation.dart';

class AnalysisService {
  final ApiService _apiService = ApiService();

  // Получение списка анализов
  Future<List<SkinAnalysis>> getAnalysisHistory() async {
    try {
      final response = await _apiService.get(AppConfig.skinAnalysesEndpoint);

      List<SkinAnalysis> analyses = [];
      if (response['data'] != null && response['data'] is List) {
        for (var item in response['data']) {
          analyses.add(SkinAnalysis.fromJson(item));
        }
      }

      return analyses;
    } catch (e) {
      debugPrint('Error getting analysis history: $e');
      rethrow;
    }
  }

  // Получение деталей конкретного анализа
  Future<SkinAnalysis> getAnalysisDetails(int analysisId) async {
    try {
      final response = await _apiService.get('${AppConfig.skinAnalysesEndpoint}/$analysisId');

      if (response['data'] != null) {
        return SkinAnalysis.fromJson(response['data']);
      }

      throw Exception('Данные анализа не найдены');
    } catch (e) {
      debugPrint('Error getting analysis details: $e');
      rethrow;
    }
  }

  // Загрузка и анализ фотографии кожи
  Future<SkinAnalysis> analyzeSkin(File imageFile, {Map<String, dynamic>? additionalData}) async {
    try {
      // Шаг 1: Загрузить фото
      final photoResponse = await _apiService.uploadFile(
        AppConfig.skinPhotosEndpoint,
        imageFile,
        extraData: additionalData,
      );

      if (photoResponse['data'] == null || photoResponse['data']['id'] == null) {
        throw Exception('Ошибка при загрузке фото');
      }

      final int photoId = photoResponse['data']['id'];

      // Шаг 2: Запустить анализ фото
      final analysisResponse = await _apiService.post(
        '${AppConfig.skinPhotosEndpoint}/$photoId/analyze',
        data: additionalData,
      );

      if (analysisResponse['data'] == null) {
        throw Exception('Ошибка при анализе фото');
      }

      return SkinAnalysis.fromJson(analysisResponse['data']);
    } catch (e) {
      debugPrint('Error analyzing skin: $e');
      rethrow;
    }
  }

  // Анализ ингредиентов косметического продукта
  Future<Map<String, dynamic>> analyzeProductIngredients(File imageFile) async {
    try {
      final response = await _apiService.uploadFile(
        AppConfig.analyzeIngredientsEndpoint,
        imageFile,
      );

      if (response['data'] == null) {
        throw Exception('Ошибка при анализе ингредиентов');
      }

      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error analyzing ingredients: $e');
      rethrow;
    }
  }

  // Получение временной шкалы анализов
  Future<List<Map<String, dynamic>>> getAnalysisTimeline() async {
    try {
      final response = await _apiService.get(AppConfig.timelineEndpoint);

      List<Map<String, dynamic>> timeline = [];
      if (response['data'] != null && response['data'] is List) {
        for (var item in response['data']) {
          timeline.add(Map<String, dynamic>.from(item));
        }
      }

      return timeline;
    } catch (e) {
      debugPrint('Error getting timeline: $e');
      rethrow;
    }
  }

  // Поиск косметических продуктов
  Future<List<CosmeticProduct>> searchProducts(String query, {String? category, String? skinType}) async {
    try {
      Map<String, dynamic> queryParams = {
        'search': query,
      };

      if (category != null) {
        queryParams['category'] = category;
      }

      if (skinType != null) {
        queryParams['skin_type'] = skinType;
      }

      final response = await _apiService.get(
        AppConfig.cosmeticsEndpoint,
        queryParams: queryParams,
      );

      List<CosmeticProduct> products = [];
      if (response['data'] != null && response['data'] is List) {
        for (var item in response['data']) {
          products.add(CosmeticProduct.fromJson(item));
        }
      }

      return products;
    } catch (e) {
      debugPrint('Error searching products: $e');
      rethrow;
    }
  }

  // Получение информации о продукте
  Future<CosmeticProduct> getProductDetails(int productId) async {
    try {
      final response = await _apiService.get('${AppConfig.cosmeticsEndpoint}/$productId');

      if (response['data'] != null) {
        return CosmeticProduct.fromJson(response['data']);
      }

      throw Exception('Информация о продукте не найдена');
    } catch (e) {
      debugPrint('Error getting product details: $e');
      rethrow;
    }
  }

  // Проверка совместимости косметического продукта с типом кожи
  Future<Map<String, dynamic>> checkProductCompatibility(
      int productId,
      {String? skinType, List<String>? skinConcerns}
      ) async {
    try {
      Map<String, dynamic> data = {
        'product_id': productId,
      };

      if (skinType != null) {
        data['skin_type'] = skinType;
      }

      if (skinConcerns != null) {
        data['skin_concerns'] = skinConcerns;
      }

      final response = await _apiService.post(
        '${AppConfig.compareRecommendationsEndpoint}',
        data: data,
      );

      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error checking product compatibility: $e');
      rethrow;
    }
  }
}