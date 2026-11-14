import argparse
import sys
from app.core.database import SessionLocal
from app.models.user import User


def bootstrap_super_admin(email: str):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.normalized_email == email.strip().lower()).first()
        if not user:
            print(f"Error: User with email '{email}' does not exist.")
            sys.exit(1)

        user.is_super_admin = True
        user.is_active = True
        user.email_verified = True
        db.commit()
        print(f"Success: User '{user.email}' is now a Platform Super Admin.")
    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="Promote a user to Platform Super Admin.")
    parser.add_argument("--email", required=True, help="User email address")
    args = parser.parse_args()

    bootstrap_super_admin(args.email)


if __name__ == "__main__":
    main()

