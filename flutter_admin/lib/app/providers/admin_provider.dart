import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/admin_service.dart';

class AdminState {
  final Map<String, dynamic> overview;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> workspaces;
  final List<Map<String, dynamic>> telemetry;
  final List<Map<String, dynamic>> auditLogs;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.overview = const {},
    this.users = const [],
    this.workspaces = const [],
    this.telemetry = const [],
    this.auditLogs = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    Map<String, dynamic>? overview,
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? workspaces,
    List<Map<String, dynamic>>? telemetry,
    List<Map<String, dynamic>>? auditLogs,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      overview: overview ?? this.overview,
      users: users ?? this.users,
      workspaces: workspaces ?? this.workspaces,
      telemetry: telemetry ?? this.telemetry,
      auditLogs: auditLogs ?? this.auditLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminNotifier extends Notifier<AdminState> {
  final AdminService _service = AdminService();

  @override
  AdminState build() {
    Future.microtask(() => loadDashboardData());
    return const AdminState(
      overview: {
        'total_users': 18420,
        'active_users': 16900,
        'total_workspaces': 3842,
        'active_workspaces': 3650,
        'mrr': 248500.0,
        'arr': 2982000.0,
        'currency': 'INR',
        'system_health': 'operational',
      },
    );
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ov = await _service.getOverview();
      final users = await _service.listUsers();
      final workspaces = await _service.listWorkspaces();
      final telemetry = await _service.getIntegrationHealth();
      final logs = await _service.listAuditLogs();

      state = state.copyWith(
        overview: ov,
        users: users,
        workspaces: workspaces,
        telemetry: telemetry,
        auditLogs: logs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> suspendUser(String userId, String reason) async {
    try {
      await _service.suspendUser(userId, reason);
      await loadDashboardData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reactivateUser(String userId) async {
    try {
      await _service.reactivateUser(userId);
      await loadDashboardData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> suspendWorkspace(String workspaceId, String reason) async {
    try {
      await _service.suspendWorkspace(workspaceId, reason);
      await loadDashboardData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reactivateWorkspace(String workspaceId) async {
    try {
      await _service.reactivateWorkspace(workspaceId);
      await loadDashboardData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(() {
  return AdminNotifier();
});

