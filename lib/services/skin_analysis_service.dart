import 'package:skin_analyzer/services/api_service.dart';
import 'package:skin_analyzer/config/app_config.dart';
import 'package:flutter/foundation.dart';

class SkinAnalysisService {
  final ApiService _apiService = ApiService();

  // Получение списка анализов кожи
  Future<List<Map<String, dynamic>>> getSkinAnalyses() async {
    try {
      final response = await _apiService.get(AppConfig.skinAnalysesEndpoint);

      List<Map<String, dynamic>> analyses = [];
      for (var item in response['data']) {
        analyses.add(Map<String, dynamic>.from(item));
      }

      return analyses;
    } catch (e) {
      debugPrint('Error getting skin analyses: $e');
      rethrow;
    }
  }

  // Получение конкретного анализа по ID
  Future<Map<String, dynamic>> getSkinAnalysis(int analysisId) async {
    try {
      final response = await _apiService.get('${AppConfig.skinAnalysesEndpoint}/$analysisId');
      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error getting skin analysis: $e');
      rethrow;
    }
  }

  // Запуск анализа существующей фотографии
  Future<Map<String, dynamic>> analyzePhoto(int photoId, {Map<String, dynamic>? options}) async {
    try {
      final response = await _apiService.post(
        '${AppConfig.skinPhotosEndpoint}/$photoId/analyze',
        data: options,
      );

      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error analyzing photo: $e');
      rethrow;
    }
  }

  // Получение таймлайна (истории) анализов
  Future<List<Map<String, dynamic>>> getTimeline() async {
    try {
      final response = await _apiService.get(AppConfig.timelineEndpoint);

      List<Map<String, dynamic>> timeline = [];
      for (var item in response['data']) {
        timeline.add(Map<String, dynamic>.from(item));
      }

      return timeline;
    } catch (e) {
      debugPrint('Error getting timeline: $e');
      rethrow;
    }
  }

// Полный процесс: загрузка фото и анализ в один запрос
// Этот метод можно добавить, если API поддерживает такую операцию
// В противном случае, нужно использовать два отдельных запроса
}