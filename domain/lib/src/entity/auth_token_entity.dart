import '../core/entity.dart';

final class AuthTokenEntity extends Entity {
  final String accessToken;
  final String? refreshToken;
  final String? tokenType;
  final DateTime? expiresAt;

  const AuthTokenEntity({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresAt,
  });

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        tokenType,
        expiresAt,
      ];

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  AuthTokenEntity copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
  }) {
    return AuthTokenEntity(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}














