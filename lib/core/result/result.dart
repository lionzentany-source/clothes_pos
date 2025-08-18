// Unified Result / Failure abstraction for repository & service layers.
// Provides a lightweight alternative to throwing exceptions across async boundaries.

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get requireValue => switch (this) {
    Success<T>(value: final v) => v,
    Failure<T>(message: final m, code: final c, exception: final e) =>
      throw StateError(
        'Tried to access value of Failure(code=$c, message=$m, exception=$e)',
      ),
  };

  R map<R>({
    required R Function(T value) success,
    required R Function(Failure<T> f) failure,
  }) => switch (this) {
    Success<T>(value: final v) => success(v),
    Failure<T>() => failure(this as Failure<T>),
  };

  Future<Result<R>> thenAsync<R>(
    Future<Result<R>> Function(T value) next,
  ) async => switch (this) {
    Success<T>(value: final v) => await next(v),
    Failure<T>() => this as Failure<R>,
  };
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
  @override
  String toString() => 'Success($value)';
}

class Failure<T> extends Result<T> {
  final String message;
  final String? code;
  final Object? exception;
  final StackTrace? stackTrace;
  final bool retryable;

  const Failure({
    required this.message,
    this.code,
    this.exception,
    this.stackTrace,
    this.retryable = false,
  });

  Failure<T> copyWith({
    String? message,
    String? code,
    Object? exception,
    StackTrace? stackTrace,
    bool? retryable,
  }) => Failure<T>(
    message: message ?? this.message,
    code: code ?? this.code,
    exception: exception ?? this.exception,
    stackTrace: stackTrace ?? this.stackTrace,
    retryable: retryable ?? this.retryable,
  );

  @override
  String toString() =>
      'Failure(code=$code, retryable=$retryable, message=$message, exception=$exception)';
}

extension ResultExtensions<T> on Result<T> {
  T? get valueOrNull => switch (this) {
    Success<T>(value: final v) => v,
    Failure<T>() => null,
  };

  T valueOr(T fallback) => switch (this) {
    Success<T>(value: final v) => v,
    Failure<T>() => fallback,
  };

  Result<R> cast<R>() => switch (this) {
    Success<T>(value: final v) => Success<R>(v as R),
    Failure<T>(
      message: final m,
      code: final c,
      exception: final e,
      stackTrace: final s,
      retryable: final r,
    ) =>
      Failure<R>(
        message: m,
        code: c,
        exception: e,
        stackTrace: s,
        retryable: r,
      ),
  };
}

// Helper factories
Success<T> ok<T>(T v) => Success(v);
Failure<T> fail<T>(
  String message, {
  String? code,
  Object? exception,
  StackTrace? stackTrace,
  bool retryable = false,
}) => Failure(
  message: message,
  code: code,
  exception: exception,
  stackTrace: stackTrace,
  retryable: retryable,
);
