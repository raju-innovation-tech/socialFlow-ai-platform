# Workspace Team Invitations & Lifecycle

## 1. Invitation Lifecycle

1. **Send Invitation (`POST /api/v1/workspaces/{workspace_id}/invitations`):**
   - Caller must hold `members:invite` permission (`owner` or `admin`).
   - Validates that target email is not already an active member of this workspace.
   - Generates a 48-byte cryptographically secure token, hashes it via SHA-256, and stores in `workspace_invitations`.
   - Sets a 7-day expiration.
2. **Accept Invitation (`POST /api/v1/invitations/accept`):**
   - User passes `invitation_token`.
   - Validates token hash, status (`pending`), and non-expired TTL.
   - Binds `user_id` to workspace as `WorkspaceMember` with the invited role.
   - Marks invitation `accepted` and sets `accepted_at`.
3. **Reject Invitation (`POST /api/v1/invitations/reject`):**
   - Sets status to `rejected` and records rejection in audit log.
4. **Member Role Updates (`PUT /api/v1/workspaces/{workspace_id}/members/{member_id}`):**
   - Caller must hold `members:update_role`.
   - Restricts changing the `owner` role (must use explicit ownership transfer endpoint).
5. **Ownership Transfer (`POST /api/v1/workspaces/{workspace_id}/transfer-ownership`):**
   - Only the existing `owner` can transfer ownership to another active member.
   - Demotes previous owner to `admin` and elevates target member to `owner`.

