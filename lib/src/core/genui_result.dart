sealed class GenUiResult<T> {
  const GenUiResult();

  bool get isSuccess => this is GenUiSuccess<T>;
  bool get isFailure => this is GenUiFailure<T>;
}

final class GenUiSuccess<T> extends GenUiResult<T> {
  const GenUiSuccess(this.value);

  final T value;
}

final class GenUiFailure<T> extends GenUiResult<T> {
  const GenUiFailure(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
}
