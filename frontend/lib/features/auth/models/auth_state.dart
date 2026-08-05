import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? userRole;
  final String? userName;
  final String? userId;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.accessToken,
    this.refreshToken,
    this.userRole,
    this.userName,
    this.userId,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    String? userRole,
    String? userName,
    String? userId,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userRole: userRole ?? this.userRole,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    accessToken,
    refreshToken,
    userRole,
    userName,
    userId,
    errorMessage,
  ];
}
