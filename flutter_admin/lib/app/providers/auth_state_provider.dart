import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/team_member.dart';

class AuthState {
  final bool isAuthenticated;
  final String userName;
  final String userEmail;
  final WorkspaceRole role;

  const AuthState({
    required this.isAuthenticated,
    required this.userName,
    required this.userEmail,
    required this.role,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userName,
    String? userEmail,
    WorkspaceRole? role,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(
        isAuthenticated: true,
        userName: 'Cyber Magic Team',
        userEmail: 'admin@cybermagic.studio',
        role: WorkspaceRole.owner,
      );

  void login(String email, String password) {
    state = state.copyWith(
      isAuthenticated: true,
      userEmail: email,
    );
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
