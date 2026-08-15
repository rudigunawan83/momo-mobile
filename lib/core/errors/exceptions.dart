/// Momo Exception - Base exception untuk aplikasi
abstract class MomoException implements Exception {
  final String message;
  final dynamic originalException;
  final StackTrace? stackTrace;

  MomoException({
    required this.message,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

/// Network Exception
class NetworkException extends MomoException {
  NetworkException({
    required super.message,
    super.originalException,
    super.stackTrace,
  });
}

/// Timeout Exception
class TimeoutException extends MomoException {
  TimeoutException({
    required super.message,
    super.originalException,
    super.stackTrace,
  });
}

/// Unauthorized Exception
class UnauthorizedException extends MomoException {
  UnauthorizedException({
    required super.message,
    super.originalException,
    super.stackTrace,
  });
}

/// Not Found Exception
class NotFoundException extends MomoException {
  NotFoundException({
    required super.message,
    super.originalException,
    super.stackTrace,
  });
}

/// Server Exception
class ServerException extends MomoException {
  final int? statusCode;

  ServerException({
    required super.message,
    this.statusCode,
    super.originalException,
    super.stackTrace,
  });
}

/// Cache Exception
class CacheException extends MomoException {
  CacheException({
    required super.message,
    super.originalException,
    super.stackTrace,
  });
}

/// Generic Exception
class GenericException extends MomoException {
  GenericException({
    required super.message,
    super.originalException,
    super.stackTrace,
  });
}
