import 'package:domain/domain.dart';

import 'exceptions.dart';

/// Handles exceptions and converts them to domain failures
class ExceptionHandler {
  /// Converts a [DataException] to a [Failure]
  static Failure handleException(Object exception) {
    if (exception is NetworkException) {
      return const NetworkFailure();
    }

    if (exception is UnauthorizedException) {
      return AuthFailure(message: exception.message);
    }

    if (exception is ForbiddenException) {
      return AuthFailure(message: exception.message);
    }

    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        fieldErrors: _parseErrors(exception.errors),
      );
    }

    if (exception is BadRequestException) {
      return ValidationFailure(
        message: exception.message,
        fieldErrors: _parseErrors(exception.errors),
      );
    }

    if (exception is NotFoundException) {
      return ServerFailure(
        message: exception.message,
        statusCode: 404,
      );
    }

    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        statusCode: exception.statusCode,
      );
    }

    if (exception is CacheException) {
      return CacheFailure(message: exception.message);
    }

    if (exception is DataException) {
      return ServerFailure(message: exception.message);
    }

    // Unknown exception
    return UnknownFailure(
      message: exception.toString(),
    );
  }

  /// Parses error object to Map<String, String>
  static Map<String, String>? _parseErrors(dynamic errors) {
    if (errors == null) return null;

    if (errors is Map<String, dynamic>) {
      return errors.map((key, value) {
        if (value is List && value.isNotEmpty) {
          return MapEntry(key, value.first.toString());
        }
        return MapEntry(key, value.toString());
      });
    }

    return null;
  }
}












