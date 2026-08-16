import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'package:logger/logger.dart';

/// API Client untuk Momo AI
class ApiClient {
  final Dio _dio;
  final Logger _logger;

  ApiClient({Dio? dio, Logger? logger})
      : _dio = dio ?? Dio(),
        _logger = logger ?? Logger();

  /// Get Dio instance untuk advanced usage (e.g., streaming)
  Dio get dio => _dio;

  /// Initialize API Client
  void init({
    String? baseUrl,
    required String Function() getToken,
    Duration? connectTimeout,
    Duration? receiveTimeout,
  }) {
    _dio.options = BaseOptions(
      baseUrl: baseUrl ?? EnvConfig.apiBaseUrl,
      connectTimeout: connectTimeout ?? AppConstants.apiTimeout,
      receiveTimeout: receiveTimeout ?? AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors
    _dio.interceptors.clear();

    // Token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = getToken();
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.i('🔵 ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i('🟢 Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('🔴 Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );

    // Retry interceptor
    _dio.interceptors.add(
      RetryInterceptor(
        _dio,
        logger: _logger,
      ),
    );
  }

  /// GET request
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleException(e);
    } catch (e) {
      throw GenericException(
        message: 'Unexpected error',
        originalException: e,
      );
    }
  }

  /// POST request
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleException(e);
    } catch (e) {
      throw GenericException(
        message: 'Unexpected error',
        originalException: e,
      );
    }
  }

  /// PUT request
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleException(e);
    } catch (e) {
      throw GenericException(
        message: 'Unexpected error',
        originalException: e,
      );
    }
  }

  /// DELETE request
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleException(e);
    } catch (e) {
      throw GenericException(
        message: 'Unexpected error',
        originalException: e,
      );
    }
  }

  /// PATCH request
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _handleException(e);
    } catch (e) {
      throw GenericException(
        message: 'Unexpected error',
        originalException: e,
      );
    }
  }

  /// Handle response — unwraps ApiResponse envelope {"success":true,"data":{...}}
  T _handleResponse<T>(Response<dynamic> response) {
    final statusCode = response.statusCode ?? 200;

    if (statusCode >= 200 && statusCode < 300) {
      final body = response.data;

      // Unwrap ApiResponse envelope: {"success": true, "data": {...}}
      if (body is Map<String, dynamic> && body.containsKey('data') && body.containsKey('success')) {
        if (body['success'] == true) {
          return body['data'] as T;
        } else {
          final errors = (body['errors'] as List?)?.join(', ') ?? body['message'] ?? 'Unknown error';
          throw ServerException(
            message: errors.toString(),
            statusCode: statusCode,
            originalException: body,
          );
        }
      }

      return body as T;
    }

    throw ServerException(
      message: 'Server error',
      statusCode: statusCode,
      originalException: response.data,
    );
  }

  /// Handle DioException
  MomoException _handleException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Connection timeout. Please try again.',
          originalException: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 401) {
          return UnauthorizedException(
            message: 'Unauthorized. Please login again.',
            originalException: error,
          );
        } else if (statusCode == 404) {
          return NotFoundException(
            message: 'Resource not found.',
            originalException: error,
          );
        } else if (statusCode >= 500) {
          return ServerException(
            message: 'Server error. Please try again later.',
            statusCode: statusCode,
            originalException: error,
          );
        } else {
          return ServerException(
            message: 'Error: $statusCode',
            statusCode: statusCode,
            originalException: error,
          );
        }

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Network error. Please check your connection.',
          originalException: error,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return GenericException(
          message: 'Unexpected error. Please try again.',
          originalException: error,
        );
    }
  }
}

/// Retry Interceptor - automatic retry on failure
class RetryInterceptor extends QueuedInterceptor {
  final Dio dio;
  final Logger logger;

  RetryInterceptor(this.dio, {required this.logger});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRetryableStatusCode = err.response?.statusCode == 429 ||
        err.response?.statusCode == 503 ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    final retries = (err.requestOptions.extra['retries'] as int?) ?? 0;

    if (isRetryableStatusCode && retries < AppConstants.apiRetryCount) {
      logger.w('🔄 Retrying request (${retries + 1}): ${err.requestOptions.path}');
      err.requestOptions.extra['retries'] = retries + 1;

      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // If retry also fails, pass original error
      }
    }

    handler.next(err);
  }
}
