/// Base exception for data layer
abstract class DataException implements Exception {
  final String message;
  final String? code;

  const DataException(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception for network-related errors
class NetworkException extends DataException {
  const NetworkException(super.message, {super.code});
}

/// Exception for server-related errors
class ServerException extends DataException {
  final int? statusCode;

  const ServerException(super.message, {super.code, this.statusCode});
}

/// Exception for unauthorized access
class UnauthorizedException extends DataException {
  const UnauthorizedException(super.message, {super.code});
}

/// Exception for forbidden access
class ForbiddenException extends DataException {
  const ForbiddenException(super.message, {super.code});
}

/// Exception for resource not found
class NotFoundException extends DataException {
  const NotFoundException(super.message, {super.code});
}

/// Exception for bad request
class BadRequestException extends DataException {
  final dynamic errors;

  const BadRequestException(super.message, {super.code, this.errors});
}

/// Exception for validation errors
class ValidationException extends DataException {
  final dynamic errors;

  const ValidationException(super.message, {super.code, this.errors});
}

/// Exception for cache/local storage errors
class CacheException extends DataException {
  const CacheException(super.message, {super.code});
}

/// Exception for parsing/mapping errors
class ParseException extends DataException {
  const ParseException(super.message, {super.code});
}














