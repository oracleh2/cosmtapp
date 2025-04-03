import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skin_analyzer/models/skin_analysis.dart';
import 'package:skin_analyzer/models/cosmetic_product.dart';
import 'package:skin_analyzer/services/skin_photo_service.dart';
import 'package:skin_analyzer/services/skin_analysis_service.dart';
import 'package:skin_analyzer/services/cosmetic_service.dart';
import 'package:skin_analyzer/services/recommendation_service.dart';

class AnalysisProvider extends ChangeNotifier {
  final SkinPhotoService _skinPhotoService = SkinPhotoService();
  final SkinAnalysisService _skinAnalysisService = SkinAnalysisService();
  final CosmeticService _cosmeticService = CosmeticService();
  final RecommendationService _recommendationService = RecommendationService();

  List<SkinAnalysis> _analyses = [];
  SkinAnalysis? _currentAnalysis;
  List<CosmeticProduct> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Геттеры
  List<SkinAnalysis> get analyses => _analyses;
  SkinAnalysis? get currentAnalysis => _currentAnalysis;
  List<CosmeticProduct> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Загрузка истории анализов
  Future<void> loadAnalysisHistory() async {
    _setLoading(true);
    _clearError();

    try {
      final analysesList = await _skinAnalysisService.getSkinAnalyses();

      _analyses = analysesList.map((data) {
        // Преобразуем Map<String, dynamic> в SkinAnalysis
        // Это потребует адаптации модели SkinAnalysis или создания метода fromMap
        return SkinAnalysis.fromJson(data);
      }).toList();

      _analyses.sort((a, b) => b.analysisDate.compareTo(a.analysisDate)); // Сортировка от новых к старым
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Получение деталей анализа
  Future<void> getAnalysisDetails(int analysisId) async {
    _setLoading(true);
    _clearError();

    try {
      final analysisData = await _skinAnalysisService.getSkinAnalysis(analysisId);
      _currentAnalysis = SkinAnalysis.fromJson(analysisData);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Отправка изображения на анализ - прямой метод
  Future<bool> analyzeSkin(File imageFile, {Map<String, dynamic>? additionalData}) async {
    _setLoading(true);
    _clearError();

    try {
      // Загрузка фото
      final photoData = await _skinPhotoService.uploadSkinPhoto(imageFile, metadata: additionalData);
      final photoId = photoData['id'];

      // Анализ фото
      final analysisData = await _skinAnalysisService.analyzePhoto(photoId);

      // Преобразуем ответ в объект модели
      _currentAnalysis = SkinAnalysis.fromJson(analysisData);

      // Обновляем историю анализов
      if (!_analyses.any((analysis) => analysis.id == _currentAnalysis!.id)) {
        _analyses.insert(0, _currentAnalysis!);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Анализ состава косметики
  Future<Map<String, dynamic>?> analyzeProductIngredients(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _cosmeticService.analyzeIngredients(imageFile);
      _setLoading(false);
      return result;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Удаление анализа
  Future<bool> deleteAnalysis(int analysisId) async {
    _setLoading(true);
    _clearError();

    try {
      // Получаем анализ, чтобы узнать ID фото
      final analysis = _analyses.firstWhere((a) => a.id == analysisId);

      // Удаляем анализ - если ваш API поддерживает прямое удаление анализов
      // Иначе можно удалить фото, что должно каскадно удалить и анализ
      await _skinPhotoService.deleteSkinPhoto(analysis.userId); // Предполагаем, что userId это photoId

      // Удаляем из локального списка
      _analyses.removeWhere((analysis) => analysis.id == analysisId);

      // Если удаляемый анализ является текущим, очищаем его
      if (_currentAnalysis != null && _currentAnalysis!.id == analysisId) {
        _currentAnalysis = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Поиск косметических продуктов
  Future<void> searchProducts(String query, {String? category, String? skinType}) async {
    _setLoading(true);
    _clearError();

    try {
      final filters = <String, dynamic>{
        'search': query,
      };

      if (category != null) {
        filters['category'] = category;
      }

      if (skinType != null) {
        filters['skin_type'] = skinType;
      }

      final productsData = await _cosmeticService.getCosmetics(filters: filters);

      _products = productsData.map((data) {
        return CosmeticProduct.fromJson(data);
      }).toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Получение деталей продукта
  Future<CosmeticProduct?> getProductDetails(int productId) async {
    _setLoading(true);
    _clearError();

    try {
      final productData = await _cosmeticService.getCosmetic(productId);
      _setLoading(false);
      return CosmeticProduct.fromJson(productData);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Получение рекомендаций
  Future<List<Map<String, dynamic>>?> getRecommendations() async {
    _setLoading(true);
    _clearError();

    try {
      final recommendations = await _recommendationService.getRecommendations();
      _setLoading(false);
      return recommendations;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Получение последней рекомендации
  Future<Map<String, dynamic>?> getLatestRecommendation() async {
    _setLoading(true);
    _clearError();

    try {
      final recommendation = await _recommendationService.getLatestRecommendation();
      _setLoading(false);
      return recommendation;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
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
  }

  // Очистка данных текущего анализа
  void clearCurrentAnalysis() {
    _currentAnalysis = null;
    notifyListeners();
  }
}