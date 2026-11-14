import argparse
import sys
import uuid
from datetime import datetime, timezone
from slugify import slugify

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.membership import Workspace, WorkspaceMember
from app.models.user import User, UserProfile


def create_super_admin(email: str, password: str, full_name: str):
    normalized = email.strip().lower()
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.normalized_email == normalized).first()
        if existing:
            if existing.is_super_admin:
                print(f"[!] User '{normalized}' is already a Super Admin.")
                return
            existing.is_super_admin = True
            existing.email_verified = True
            existing.account_status = "active"
            db.commit()
            print(f"[✓] Successfully upgraded existing user '{normalized}' to Super Admin.")
            return

        now = datetime.now(timezone.utc)
        user = User(
            email=email.strip(),
            normalized_email=normalized,
            full_name=full_name.strip(),
            hashed_password=hash_password(password),
            is_active=True,
            is_verified=True,
            email_verified=True,
            account_status="active",
            is_super_admin=True,
        )
        db.add(user)
        db.flush()

        profile = UserProfile(user_id=user.id)
        db.add(profile)

        # Create system management workspace
        slug = f"platform-admin-{uuid.uuid4().hex[:6]}"
        workspace = Workspace(
            name="Platform Operations Workspace",
            slug=slug,
            description="Dedicated platform operator workspace",
            owner_id=user.id,
            status="active",
            is_active=True,
        )
        db.add(workspace)
        db.flush()

        membership = WorkspaceMember(
            workspace_id=workspace.id,
            user_id=user.id,
            role="owner",
            status="active",
            joined_at=now,
        )
        db.add(membership)
        db.commit()
        print(f"[✓] Successfully created Super Admin: {normalized} (User ID: {user.id})")
    except Exception as e:
        db.rollback()
        print(f"[x] Failed to create Super Admin: {e}")
        sys.exit(1)
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="SocialFlow AI SaaS Management Tool")
    subparsers = parser.add_subparsers(dest="command", required=True)

    admin_parser = subparsers.add_parser("create-super-admin", help="Create or elevate a platform Super Admin")
    admin_parser.add_argument("--email", required=True, help="Super admin email address")
    admin_parser.add_argument("--password", required=True, help="Super admin password")
    admin_parser.add_argument("--name", default="Platform Super Admin", help="Full name")

    args = parser.parse_args()
    if args.command == "create-super-admin":
        create_super_admin(args.email, args.password, args.name)


if __name__ == "__main__":
    main()

