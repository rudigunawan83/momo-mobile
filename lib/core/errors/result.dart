/// Result type untuk better error handling
/// 
/// Menggunakan sealed class untuk type-safe result handling
sealed class Result<T> {
  const Result();

  /// Factory: create a Success result
  static Result<T> success<T>(T data) => Success<T>(data);

  /// Factory: create a Failure result
  static Result<Never> failure({
    required Exception exception,
    required String message,
  }) =>
      Failure(exception: exception, message: message);

  /// Map result ke tipe lain
  R map<R>(
    R Function(T data) onSuccess,
    R Function(Failure failure) onFailure,
  ) {
    return switch (this) {
      Success<T> success => onSuccess(success.data),
      Failure failure => onFailure(failure),
    };
  }

  /// Get data atau throw exception
  T getOrThrow() {
    return switch (this) {
      Success<T> success => success.data,
      Failure failure => throw failure.exception,
    };
  }

  /// Cek apakah success
  bool get isSuccess => this is Success<T>;

  /// Cek apakah failure
  bool get isFailure => this is Failure;
}

/// Success Result
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Failure Result
class Failure extends Result<Never> {
  final Exception exception;
  final String message;

  const Failure({
    required this.exception,
    required this.message,
  });

  @override
  String toString() => 'Failure($message)';
}
