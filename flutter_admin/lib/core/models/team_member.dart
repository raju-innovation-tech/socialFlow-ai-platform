enum WorkspaceRole {
  owner,
  admin,
  editor,
  approver,
  analyst,
  viewer,
}

class TeamMember {
  final String id;
  final String name;
  final String email;
  final WorkspaceRole role;
  final String avatarUrl;
  final DateTime joinedAt;
  final bool isActive;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
    required this.joinedAt,
    this.isActive = true,
  });

  String get roleName {
    switch (role) {
      case WorkspaceRole.owner:
        return 'Owner';
      case WorkspaceRole.admin:
        return 'Admin';
      case WorkspaceRole.editor:
        return 'Editor';
      case WorkspaceRole.approver:
        return 'Approver';
      case WorkspaceRole.analyst:
        return 'Analyst';
      case WorkspaceRole.viewer:
        return 'Viewer';
    }
  }
}

