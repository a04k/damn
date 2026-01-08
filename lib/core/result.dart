import 'exceptions.dart';

class Result<T> {
  final T? _data;
  final AppException? _error;
  final bool _isSuccess;
  
  const Result._(this._data, this._error, this._isSuccess);
  
  factory Result.success(T data) => Result._(data, null, true);
  factory Result.failure(AppException error) => Result._(null, error, false);
  
  bool get isSuccess => _isSuccess;
  bool get isFailure => !_isSuccess;
  
  T get data {
    if (_isSuccess) {
      return _data as T;
    }
    throw _error!;
  }
  
  AppException get error {
    if (isFailure) {
      return _error!;
    }
    throw StateError('Cannot get error from successful result');
  }
  
  T? get orNull => _isSuccess ? _data : null;
  
  Result<R> map<R>(R Function(T data) mapper) {
    if (_isSuccess) {
      try {
        return Result.success(mapper(_data as T));
      } catch (e) {
        return Result.failure(
          DataException('Mapping failed', originalError: e),
        );
      }
    }
    return Result.failure(_error!);
  }
  
  Result<R> flatMap<R>(Result<R> Function(T data) mapper) {
    if (_isSuccess) {
      try {
        return mapper(_data as T);
      } catch (e) {
        return Result.failure(
          DataException('Flat mapping failed', originalError: e),
        );
      }
    }
    return Result.failure(_error!);
  }
  
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(AppException error) onFailure,
  ) {
    if (_isSuccess) {
      return onSuccess(_data as T);
    }
    return onFailure(_error!);
  }
  
  @override
  String toString() {
    return _isSuccess ? 'Result.success($_data)' : 'Result.failure($_error)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Result<T> &&
        other._isSuccess == _isSuccess &&
        other._data == _data &&
        other._error == _error;
  }
  
  @override
  int get hashCode => Object.hash(_isSuccess, _data, _error);
}