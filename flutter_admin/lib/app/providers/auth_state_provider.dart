import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/team_member.dart';
import '../../core/services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final String userId;
  final String userName;
  final String userEmail;
  final WorkspaceRole role;
  final bool isSuperAdmin;
  final String? currentWorkspaceId;
  final String currentWorkspaceName;
  final List<WorkspaceInfo> workspaces;
  final List<String> permissions;
  final bool isLoading;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    this.isSuperAdmin = false,
    this.currentWorkspaceId,
    this.currentWorkspaceName = 'Default Workspace',
    this.workspaces = const [],
    this.permissions = const [],
    this.isLoading = false,
    this.error,
  });

  bool hasPermission(String code) {
    if (isSuperAdmin) return true;
    return permissions.contains(code);
  }

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? userName,
    String? userEmail,
    WorkspaceRole? role,
    bool? isSuperAdmin,
    String? currentWorkspaceId,
    String? currentWorkspaceName,
    List<WorkspaceInfo>? workspaces,
    List<String>? permissions,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      currentWorkspaceId: currentWorkspaceId ?? this.currentWorkspaceId,
      currentWorkspaceName: currentWorkspaceName ?? this.currentWorkspaceName,
      workspaces: workspaces ?? this.workspaces,
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    return const AuthState(
      isAuthenticated: false,
      userId: '',
      userName: '',
      userEmail: '',
      role: WorkspaceRole.viewer,
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _authService.login(email: email, password: password);
      
      // Load user workspaces
      List<WorkspaceInfo> userWorkspaces = [];
      try {
        userWorkspaces = await _authService.listWorkspaces();
      } catch (_) {}

      final currentWs = userWorkspaces.firstWhere(
        (ws) => ws.id == res.user.defaultWorkspaceId,
        orElse: () => userWorkspaces.isNotEmpty
            ? userWorkspaces.first
            : WorkspaceInfo(
                id: res.user.defaultWorkspaceId ?? '',
                name: 'Default Workspace',
                slug: 'default',
                role: 'owner',
                status: 'active',
                isDefault: true,
              ),
      );

      state = state.copyWith(
        isAuthenticated: true,
        userId: res.user.id,
        userName: res.user.fullName,
        userEmail: res.user.email,
        isSuperAdmin: res.user.isSuperAdmin,
        currentWorkspaceId: currentWs.id,
        currentWorkspaceName: currentWs.name,
        workspaces: userWorkspaces,
        role: _parseRole(currentWs.role),
        permissions: res.permissions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> verifyEmail({required String email, required String otp}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.verifyEmail(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<String?> resendOtp(String email) async {
    try {
      return await _authService.resendVerificationOtp(email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> switchWorkspace(String workspaceId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _authService.switchWorkspace(workspaceId);
      final ws = state.workspaces.firstWhere((w) => w.id == workspaceId);
      final perms = (res['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      state = state.copyWith(
        currentWorkspaceId: ws.id,
        currentWorkspaceName: ws.name,
        role: _parseRole(res['role'] ?? ws.role),
        permissions: perms,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(
      isAuthenticated: false,
      userId: '',
      userName: '',
      userEmail: '',
      role: WorkspaceRole.viewer,
    );
  }

  static WorkspaceRole _parseRole(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'owner':
        return WorkspaceRole.owner;
      case 'admin':
        return WorkspaceRole.admin;
      case 'editor':
        return WorkspaceRole.editor;
      case 'approver':
        return WorkspaceRole.approver;
      case 'analyst':
        return WorkspaceRole.analyst;
      case 'viewer':
      default:
        return WorkspaceRole.viewer;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
