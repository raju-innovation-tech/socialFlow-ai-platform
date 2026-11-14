import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
from slugify import slugify
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.exceptions import BadRequestException, ConflictException, ForbiddenException, NotFoundException, UnauthorizedException
from app.core.logging import logger
from app.core.security import (
    create_access_token,
    generate_numeric_otp,
    generate_secure_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.models.audit_log import AuditLog
from app.models.auth_tokens import EmailVerificationToken, LoginAttempt, PasswordResetToken, RefreshToken, UserSession
from app.models.membership import WorkspaceMember
from app.models.user import User, UserProfile
from app.models.workspace import Workspace
from app.schemas.auth import (
    AuthUserResponse,
    ChangePasswordRequest,
    LoginRequest,
    RegisterRequest,
    ResetPasswordRequest,
    TokenResponse,
    VerifyEmailRequest,
)


def to_utc(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def _log_audit(
        self,
        action: str,
        entity_type: str,
        entity_id: str,
        actor_id: Optional[str] = None,
        workspace_id: Optional[str] = None,
        metadata: Optional[str] = None,
        ip_address: Optional[str] = None,
    ):
        try:
            log = AuditLog(
                action=action,
                entity_type=entity_type,
                entity_id=entity_id,
                actor_id=actor_id,
                workspace_id=workspace_id,
                metadata_json=metadata,
                ip_address=ip_address,
            )
            self.db.add(log)
            self.db.commit()
        except Exception as e:
            logger.error("Failed to write audit log: %s", e)
            self.db.rollback()

    def register(self, payload: RegisterRequest, ip_address: Optional[str] = None) -> Tuple[User, str]:
        normalized_email = payload.email.strip().lower()

        # Check duplicate normalized email
        existing = self.db.query(User).filter(User.normalized_email == normalized_email).first()
        if existing:
            raise ConflictException(f"An account with email '{normalized_email}' already exists.")

        now = datetime.now(timezone.utc)
        pwd_hash = hash_password(payload.password)

        # Create user
        user = User(
            email=payload.email.strip(),
            normalized_email=normalized_email,
            full_name=payload.full_name.strip(),
            hashed_password=pwd_hash,
            is_active=True,
            is_verified=False,
            email_verified=False,
            account_status="pending_verification",
            is_super_admin=False,
        )
        self.db.add(user)
        self.db.flush()

        # Create default user profile
        profile = UserProfile(user_id=user.id)
        self.db.add(profile)

        # Create initial default workspace for the new user
        slug_base = slugify(f"{user.full_name} workspace")
        workspace_slug = f"{slug_base}-{uuid.uuid4().hex[:6]}"
        workspace = Workspace(
            name=f"{user.full_name}'s Workspace",
            slug=workspace_slug,
            description="Default personal workspace",
            owner_id=user.id,
            status="active",
            is_active=True,
        )
        self.db.add(workspace)
        self.db.flush()

        # Make the user the Owner
        membership = WorkspaceMember(
            workspace_id=workspace.id,
            user_id=user.id,
            role="owner",
            status="active",
            joined_at=now,
        )
        self.db.add(membership)

        # Generate 6-digit numeric OTP for email verification
        otp_plain = generate_numeric_otp(6)
        token_record = EmailVerificationToken(
            user_id=user.id,
            otp_hash=hash_token(otp_plain),
            attempts_count=0,
            max_attempts=settings.OTP_MAX_ATTEMPTS,
            expires_at=now + timedelta(minutes=settings.OTP_EXPIRE_MINUTES),
            is_used=False,
        )
        self.db.add(token_record)
        self.db.commit()

        self._log_audit(
            action="user_registered",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
            workspace_id=workspace.id,
            metadata=f"Registered with email: {normalized_email}",
            ip_address=ip_address,
        )

        return user, otp_plain

    def verify_email(self, payload: VerifyEmailRequest, ip_address: Optional[str] = None) -> bool:
        normalized_email = payload.email.strip().lower()
        user = self.db.query(User).filter(User.normalized_email == normalized_email).first()
        if not user:
            raise NotFoundException("User", normalized_email)

        if user.email_verified:
            return True

        now = datetime.now(timezone.utc)
        token_record = (
            self.db.query(EmailVerificationToken)
            .filter(
                EmailVerificationToken.user_id == user.id,
                EmailVerificationToken.is_used == False,
                EmailVerificationToken.expires_at > now,
            )
            .order_by(EmailVerificationToken.created_at.desc())
            .first()
        )

        if not token_record:
            raise BadRequestException("Verification OTP has expired or does not exist. Please request a new one.")

        if token_record.attempts_count >= token_record.max_attempts:
            raise BadRequestException("Maximum verification attempts exceeded. Please request a new OTP.")

        submitted_hash = hash_token(payload.otp.strip())
        if submitted_hash != token_record.otp_hash:
            token_record.attempts_count += 1
            self.db.commit()
            remaining = token_record.max_attempts - token_record.attempts_count
            raise BadRequestException(f"Invalid OTP code. {remaining} attempt(s) remaining.")

        # OTP is valid
        token_record.is_used = True
        user.email_verified = True
        user.is_verified = True
        user.account_status = "active"
        self.db.commit()

        self._log_audit(
            action="email_verified",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
            ip_address=ip_address,
        )

        return True

    def resend_verification(self, email: str) -> str:
        normalized_email = email.strip().lower()
        user = self.db.query(User).filter(User.normalized_email == normalized_email).first()
        if not user:
            raise NotFoundException("User", normalized_email)

        if user.email_verified:
            raise BadRequestException("This account is already verified.")

        now = datetime.now(timezone.utc)

        # Invalidate old unused tokens
        self.db.query(EmailVerificationToken).filter(
            EmailVerificationToken.user_id == user.id,
            EmailVerificationToken.is_used == False,
        ).update({"is_used": True})

        otp_plain = generate_numeric_otp(6)
        token_record = EmailVerificationToken(
            user_id=user.id,
            otp_hash=hash_token(otp_plain),
            attempts_count=0,
            max_attempts=settings.OTP_MAX_ATTEMPTS,
            expires_at=now + timedelta(minutes=settings.OTP_EXPIRE_MINUTES),
            is_used=False,
        )
        self.db.add(token_record)
        self.db.commit()

        return otp_plain

    def login(
        self,
        payload: LoginRequest,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> TokenResponse:
        normalized_email = payload.email.strip().lower()
        user = self.db.query(User).filter(User.normalized_email == normalized_email).first()

        now = datetime.now(timezone.utc)

        # Authenticate credentials
        if not user or not verify_password(payload.password, user.hashed_password or ""):
            # Record failed login attempt
            attempt = LoginAttempt(email=normalized_email, ip_address=ip_address, success=False, attempted_at=now)
            self.db.add(attempt)
            self.db.commit()
            raise UnauthorizedException("Invalid email address or password.")

        # Check account status
        if not user.is_active or user.account_status == "suspended":
            raise ForbiddenException("Account has been disabled or suspended. Contact support.")

        if not user.email_verified and not user.is_super_admin:
            raise ForbiddenException("Account email is not verified. Please complete OTP verification.")

        # Record successful login attempt
        attempt = LoginAttempt(email=normalized_email, ip_address=ip_address, success=True, attempted_at=now)
        self.db.add(attempt)

        # Issue JWT Access Token
        access_token = create_access_token(
            user_id=user.id,
            email=user.email,
            is_super_admin=user.is_super_admin,
        )

        # Issue Refresh Token with new Token Family
        plain_refresh_token = generate_secure_token(48)
        family_id = str(uuid.uuid4())
        refresh_expires = now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

        refresh_record = RefreshToken(
            user_id=user.id,
            token_hash=hash_token(plain_refresh_token),
            token_family=family_id,
            expires_at=refresh_expires,
            is_used=False,
        )
        self.db.add(refresh_record)
        self.db.flush()

        # Create active user session
        session = UserSession(
            user_id=user.id,
            refresh_token_id=refresh_record.id,
            ip_address=ip_address,
            user_agent=user_agent,
            expires_at=refresh_expires,
            is_revoked=False,
        )
        self.db.add(session)
        self.db.commit()

        # Find default workspace
        membership = self.db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user.id,
            WorkspaceMember.status == "active",
        ).first()
        default_ws_id = membership.workspace_id if membership else None

        self._log_audit(
            action="login_success",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
            workspace_id=default_ws_id,
            metadata="User logged in successfully",
            ip_address=ip_address,
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=plain_refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=AuthUserResponse(
                id=user.id,
                email=user.email,
                full_name=user.full_name,
                is_active=user.is_active,
                email_verified=user.email_verified,
                is_super_admin=user.is_super_admin,
                default_workspace_id=default_ws_id,
            ),
        )

    def refresh(
        self,
        plain_refresh_token: str,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> TokenResponse:
        now = datetime.now(timezone.utc)
        token_hash = hash_token(plain_refresh_token.strip())

        refresh_record = (
            self.db.query(RefreshToken)
            .filter(RefreshToken.token_hash == token_hash)
            .first()
        )

        if not refresh_record:
            raise UnauthorizedException("Invalid refresh token.")

        # REUSE DETECTION: If token was already used, family theft is suspected!
        if refresh_record.is_used:
            # Revoke entire token family
            self.db.query(RefreshToken).filter(
                RefreshToken.token_family == refresh_record.token_family
            ).update({"revoked_at": now})

            self.db.commit()
            self._log_audit(
                action="token_reuse_detected",
                entity_type="refresh_token",
                entity_id=refresh_record.id,
                actor_id=refresh_record.user_id,
                metadata="Security Alert: Revoked entire token family due to reuse detection",
                ip_address=ip_address,
            )
            raise UnauthorizedException("Security Alert: Token reuse detected. All sessions in this family revoked.")

        if refresh_record.revoked_at or to_utc(refresh_record.expires_at) < now:
            raise UnauthorizedException("Refresh token has expired or been revoked.")

        user = self.db.query(User).filter(User.id == refresh_record.user_id).first()
        if not user or not user.is_active:
            raise ForbiddenException("User account is inactive or no longer exists.")

        # Mark previous refresh token as used
        refresh_record.is_used = True
        refresh_record.revoked_at = now

        # Generate NEW rotating refresh token in same family
        new_plain_refresh = generate_secure_token(48)
        new_refresh_record = RefreshToken(
            user_id=user.id,
            token_hash=hash_token(new_plain_refresh),
            token_family=refresh_record.token_family,
            expires_at=now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            is_used=False,
        )
        self.db.add(new_refresh_record)
        self.db.flush()

        # Update or create session
        session = self.db.query(UserSession).filter(UserSession.refresh_token_id == refresh_record.id).first()
        if session:
            session.refresh_token_id = new_refresh_record.id
            session.expires_at = new_refresh_record.expires_at

        self.db.commit()

        # Issue new access token
        new_access_token = create_access_token(
            user_id=user.id,
            email=user.email,
            is_super_admin=user.is_super_admin,
        )

        membership = self.db.query(WorkspaceMember).filter(
            WorkspaceMember.user_id == user.id,
            WorkspaceMember.status == "active",
        ).first()

        return TokenResponse(
            access_token=new_access_token,
            refresh_token=new_plain_refresh,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user=AuthUserResponse(
                id=user.id,
                email=user.email,
                full_name=user.full_name,
                is_active=user.is_active,
                email_verified=user.email_verified,
                is_super_admin=user.is_super_admin,
                default_workspace_id=membership.workspace_id if membership else None,
            ),
        )

    def logout(self, user_id: str, plain_refresh_token: Optional[str] = None):
        now = datetime.now(timezone.utc)
        if plain_refresh_token:
            token_hash = hash_token(plain_refresh_token.strip())
            record = self.db.query(RefreshToken).filter(RefreshToken.token_hash == token_hash).first()
            if record:
                record.revoked_at = now
                session = self.db.query(UserSession).filter(UserSession.refresh_token_id == record.id).first()
                if session:
                    session.is_revoked = True
                self.db.commit()

        self._log_audit(
            action="logout",
            entity_type="user",
            entity_id=user_id,
            actor_id=user_id,
        )

    def logout_all(self, user_id: str):
        now = datetime.now(timezone.utc)
        self.db.query(RefreshToken).filter(
            RefreshToken.user_id == user_id,
            RefreshToken.revoked_at == None,
        ).update({"revoked_at": now})

        self.db.query(UserSession).filter(
            UserSession.user_id == user_id,
            UserSession.is_revoked == False,
        ).update({"is_revoked": True})

        self.db.commit()
        self._log_audit(
            action="logout_all_sessions",
            entity_type="user",
            entity_id=user_id,
            actor_id=user_id,
        )

    def forgot_password(self, email: str) -> Optional[str]:
        normalized_email = email.strip().lower()
        user = self.db.query(User).filter(User.normalized_email == normalized_email).first()
        if not user:
            # Generic response to prevent account enumeration
            return None

        now = datetime.now(timezone.utc)

        # Invalidate old unused reset tokens
        self.db.query(PasswordResetToken).filter(
            PasswordResetToken.user_id == user.id,
            PasswordResetToken.is_used == False,
        ).update({"is_used": True})

        plain_reset_token = generate_secure_token(32)
        record = PasswordResetToken(
            user_id=user.id,
            token_hash=hash_token(plain_reset_token),
            expires_at=now + timedelta(minutes=settings.PASSWORD_RESET_EXPIRE_MINUTES),
            is_used=False,
        )
        self.db.add(record)
        self.db.commit()

        self._log_audit(
            action="password_reset_requested",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
        )

        return plain_reset_token

    def reset_password(self, payload: ResetPasswordRequest):
        token_hash = hash_token(payload.token.strip())
        now = datetime.now(timezone.utc)

        record = self.db.query(PasswordResetToken).filter(
            PasswordResetToken.token_hash == token_hash,
            PasswordResetToken.is_used == False,
            PasswordResetToken.expires_at > now,
        ).first()

        if not record:
            raise BadRequestException("Password reset token is invalid or has expired.")

        user = self.db.query(User).filter(User.id == record.user_id).first()
        if not user:
            raise NotFoundException("User", record.user_id)

        user.hashed_password = hash_password(payload.new_password)
        record.is_used = True

        # Revoke all existing sessions for security
        self.logout_all(user.id)
        self.db.commit()

        self._log_audit(
            action="password_reset_completed",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
        )

    def change_password(self, user: User, payload: ChangePasswordRequest):
        if not verify_password(payload.current_password, user.hashed_password or ""):
            raise BadRequestException("Current password is incorrect.")

        user.hashed_password = hash_password(payload.new_password)
        self.db.commit()

        self._log_audit(
            action="password_changed",
            entity_type="user",
            entity_id=user.id,
            actor_id=user.id,
        )

