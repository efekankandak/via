import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String userId;
  final bool isAnonymous;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const AuthAuthenticated({
    required this.userId,
    required this.isAnonymous,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  @override
  List<Object?> get props =>
      [userId, isAnonymous, displayName, email, photoUrl];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
