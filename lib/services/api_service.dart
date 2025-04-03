import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skin_analyzer/config/app_config.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService() {
    _setupDio();
  }

  void _setupDio() {
    BaseOptions options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
      responseType: ResponseType.json,
      contentType: 'application/json',
    );

    _dio = Dio(options);

    // Логирование для отладки
    _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) {
          debugPrint('API_LOG: $object');
        }
    ));

    // Добавляем интерцептор для автоматического добавления токена в заголовки
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: 'auth_token');
        debugPrint('API_REQUEST: ${options.method} ${options.uri}');
        debugPrint('API_HEADERS: ${options.headers}');

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint('API_AUTH: Token found and applied');
        } else {
          debugPrint('API_AUTH: No token available');
        }

        if (options.data != null) {
          debugPrint('API_DATA: ${options.data}');
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('API_RESPONSE: Status ${response.statusCode}');
        debugPrint('API_RESPONSE_DATA: ${jsonEncode(response.data)}');
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        debugPrint('API_ERROR: ${error.type}');
        debugPrint('API_ERROR_MESSAGE: ${error.message}');

        if (error.response != null) {
          debugPrint('API_ERROR_STATUS: ${error.response?.statusCode}');
          debugPrint('API_ERROR_DATA: ${error.response?.data}');
        }

        // Обработка ошибок авторизации (401)
        if (error.response?.statusCode == 401) {
          // Тут можно запустить процесс обновления токена, если необходимо
          // или просто вернуть ошибку для обработки в UI
          debugPrint('API_AUTH_ERROR: 401 Unauthorized');
        }

        return handler.next(error);
      },
    ));
  }

  // GET запрос
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      debugPrint('API_CALL: GET $endpoint with params $queryParams');
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // POST запрос
  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      debugPrint('API_CALL: POST $endpoint');
      final response = await _dio.post(
        endpoint,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // PUT запрос
  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      debugPrint('API_CALL: PUT $endpoint');
      final response = await _dio.put(
        endpoint,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // DELETE запрос
  Future<dynamic> delete(String endpoint, {dynamic data}) async {
    try {
      debugPrint('API_CALL: DELETE $endpoint');
      final response = await _dio.delete(
        endpoint,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // Мультиформ запрос для отправки файлов
  Future<dynamic> uploadFile(
      String endpoint,
      File file,
      {Map<String, dynamic>? extraData}) async {
    try {
      debugPrint('API_CALL: UPLOAD to $endpoint');
      String fileName = file.path.split('/').last;

      // FormData formData = FormData.fromMap({
      //   'image': await MultipartFile.fromFile(file.path, filename: fileName),
      //   if (extraData != null) ...extraData,
      // });

      Map<String, dynamic> formMap = {
        'image': await MultipartFile.fromFile(file.path, filename: fileName),
      };

      // Корректно добавляем дополнительные данные, обрабатывая массивы
      if (extraData != null) {
        extraData.forEach((key, value) {
          if (value is List) {
            // Для каждого элемента массива создаем отдельное поле с одинаковым именем
            for (var item in value) {
              if (formMap.containsKey('$key[]')) {
                (formMap['$key[]'] as List).add(item);
              } else {
                formMap['$key[]'] = [item];
              }
            }
          } else {
            formMap[key] = value;
          }
        });
      }

      FormData formData = FormData.fromMap(formMap);

      debugPrint('API_UPLOAD: File $fileName, extra data: $extraData');
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return response.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // Обработка ошибок
  void _handleError(DioException error) {
    String errorMessage = 'Произошла ошибка при обращении к серверу';

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Превышено время ожидания ответа от сервера';
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      debugPrint('API_ERROR_DETAILS: Status $statusCode, Data: $data');

      if (data != null && data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else {
        switch (statusCode) {
          case 400:
            errorMessage = 'Некорректный запрос';
            break;
          case 401:
            errorMessage = 'Необходима авторизация';
            break;
          case 403:
            errorMessage = 'Доступ запрещен';
            break;
          case 404:
            errorMessage = 'Ресурс не найден';
            break;
          case 422:
            if (data != null && data is Map && data.containsKey('errors')) {
              final errors = data['errors'];
              if (errors is Map) {
                final firstError = errors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  errorMessage = firstError.first.toString();
                }
              }
            } else {
              errorMessage = 'Ошибка валидации данных';
            }
            break;
          case 500:
            errorMessage = 'Внутренняя ошибка сервера';
            break;
        }
      }
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'Проблема с подключением к сети';
      debugPrint('API_NETWORK_ERROR: ${error.message}');
    }

    debugPrint('API_ERROR_FINAL: $errorMessage');
    throw Exception(errorMessage);
  }
}