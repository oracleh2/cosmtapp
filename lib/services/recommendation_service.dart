import 'package:skin_analyzer/services/api_service.dart';
import 'package:skin_analyzer/config/app_config.dart';
import 'package:flutter/foundation.dart';

class RecommendationService {
  final ApiService _apiService = ApiService();

  // Получение списка рекомендаций
  Future<List<Map<String, dynamic>>> getRecommendations({Map<String, dynamic>? filters}) async {
    try {
      final response = await _apiService.get(
        AppConfig.recommendationsEndpoint,
        queryParams: filters,
      );

      List<Map<String, dynamic>> recommendations = [];
      for (var item in response['data']) {
        recommendations.add(Map<String, dynamic>.from(item));
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      rethrow;
    }
  }

  // Получение последней рекомендации
  Future<Map<String, dynamic>?> getLatestRecommendation() async {
    try {
      final response = await _apiService.get(AppConfig.latestRecommendationEndpoint);

      if (response.containsKey('data')) {
        return Map<String, dynamic>.from(response['data']);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting latest recommendation: $e');
      rethrow;
    }
  }

  // Получение конкретной рекомендации по ID
  Future<Map<String, dynamic>> getRecommendation(int recommendationId) async {
    try {
      final response = await _apiService.get('${AppConfig.recommendationsEndpoint}/$recommendationId');
      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error getting recommendation: $e');
      rethrow;
    }
  }

  // Сравнение рекомендаций
  Future<Map<String, dynamic>> compareRecommendations(List<int> recommendationIds) async {
    try {
      final response = await _apiService.post(
        AppConfig.compareRecommendationsEndpoint,
        data: {
          'recommendation_ids': recommendationIds,
        },
      );

      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error comparing recommendations: $e');
      rethrow;
    }
  }
}