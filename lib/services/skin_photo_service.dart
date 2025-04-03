import 'dart:io';
import 'package:skin_analyzer/services/api_service.dart';
import 'package:skin_analyzer/config/app_config.dart';
import 'package:flutter/foundation.dart';

class SkinPhotoService {
  final ApiService _apiService = ApiService();

  // Получение списка фотографий кожи
  Future<List<Map<String, dynamic>>> getSkinPhotos() async {
    try {
      final response = await _apiService.get(AppConfig.skinPhotosEndpoint);

      List<Map<String, dynamic>> photos = [];
      for (var item in response['data']) {
        photos.add(Map<String, dynamic>.from(item));
      }

      return photos;
    } catch (e) {
      debugPrint('Error getting skin photos: $e');
      rethrow;
    }
  }

  // Получение последней фотографии
  Future<Map<String, dynamic>?> getLatestPhoto() async {
    try {
      final response = await _apiService.get(AppConfig.latestSkinPhotoEndpoint);

      if (response.containsKey('data')) {
        return Map<String, dynamic>.from(response['data']);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting latest photo: $e');
      rethrow;
    }
  }

  // Получение конкретной фотографии по ID
  Future<Map<String, dynamic>> getSkinPhoto(int photoId) async {
    try {
      final response = await _apiService.get('${AppConfig.skinPhotosEndpoint}/$photoId');
      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error getting skin photo: $e');
      rethrow;
    }
  }

  // Загрузка новой фотографии
  Future<Map<String, dynamic>> uploadSkinPhoto(File photoFile, {Map<String, dynamic>? metadata}) async {
    try {
      final response = await _apiService.uploadFile(
        AppConfig.skinPhotosEndpoint,
        photoFile,
        extraData: metadata,
      );

      return Map<String, dynamic>.from(response['data']);
    } catch (e) {
      debugPrint('Error uploading skin photo: $e');
      rethrow;
    }
  }

  // Удаление фотографии
  Future<void> deleteSkinPhoto(int photoId) async {
    try {
      await _apiService.delete('${AppConfig.skinPhotosEndpoint}/$photoId');
    } catch (e) {
      debugPrint('Error deleting skin photo: $e');
      rethrow;
    }
  }
}