from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, Query, Request, Response, status
from fastapi.responses import HTMLResponse, RedirectResponse
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.deps import get_active_workspace_member, require_permission
from app.core.exceptions import AppException, ForbiddenException, NotFoundException
from app.core.logging import logger
from app.integrations.base.capability_models import PlatformCapabilityModel
from app.integrations.integration_service import IntegrationService
from app.integrations.registry import IntegrationRegistry
from app.models.membership import WorkspaceMember
from app.models.social_account import IntegrationEvent, SocialAccount
from app.schemas.social_account import (
    OAuthAuthorizeResponse,
    SelectPageRequest,
    SocialAccountResponse,
    TelegramConnectRequest,
    WhatsAppOnboardRequest,
)

router = APIRouter(prefix="/integrations", tags=["Social Platform Integrations"])


@router.get("/platforms")
def list_available_platforms():
    """List all seven officially supported social platforms."""
    platforms = [
        {
            "identifier": "linkedin",
            "name": "LinkedIn",
            "auth_type": "oauth2",
            "description": "Company Pages & Personal Profiles via OpenID Connect",
            "status": "ready",
        },
        {
            "identifier": "facebook",
            "name": "Facebook Pages",
            "auth_type": "oauth2",
            "description": "Meta Graph API v20.0 Page management & publishing",
            "status": "ready",
        },
        {
            "identifier": "instagram",
            "name": "Instagram Professional",
            "auth_type": "oauth2",
            "description": "Instagram Business & Creator Accounts linked to Facebook Pages",
            "status": "ready",
        },
        {
            "identifier": "youtube",
            "name": "YouTube",
            "auth_type": "oauth2",
            "description": "Google OAuth 2.0 & YouTube Data API v3 channel publishing",
            "status": "ready",
        },
        {
            "identifier": "x",
            "name": "X (Formerly Twitter)",
            "auth_type": "oauth2_pkce",
            "description": "Official X API v2 with OAuth 2.0 PKCE",
            "status": "ready",
        },
        {
            "identifier": "whatsapp",
            "name": "WhatsApp Business Platform",
            "auth_type": "meta_cloud_api",
            "description": "Official Meta Cloud API template messaging & verified numbers",
            "status": "ready",
        },
        {
            "identifier": "telegram",
            "name": "Telegram",
            "auth_type": "bot_token",
            "description": "Official Bot API broadcasting to channels and groups",
            "status": "ready",
        },
    ]
    return {"platforms": platforms}


@router.get("/capabilities", response_model=List[PlatformCapabilityModel])
def list_capabilities(platform: Optional[str] = None):
    """Retrieve the centralized capability matrix across platforms."""
    service = IntegrationService(db=None)  # Provider metadata does not require DB session
    return service.get_capabilities(platform=platform)


@router.get("/{platform}/authorize", response_model=OAuthAuthorizeResponse)
def get_platform_authorization_url(
    platform: str,
    redirect_uri: Optional[str] = None,
    member: WorkspaceMember = Depends(require_permission("accounts:connect")),
    db: Session = Depends(get_db),
):
    """Generate official OAuth 2.0 authorization URL with CSRF state token and PKCE."""
    service = IntegrationService(db)
    return service.generate_authorization_flow(
        workspace_id=member.workspace_id,
        platform=platform,
        redirect_uri=redirect_uri,
    )


@router.get("/{platform}/callback")
async def handle_browser_oauth_callback(
    platform: str,
    code: Optional[str] = None,
    state: Optional[str] = None,
    error: Optional[str] = None,
    error_description: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """Browser OAuth callback landing endpoint."""
    if error:
        return HTMLResponse(
            f"<h3>Authorization Denied: {error}</h3><p>{error_description}</p>",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    if not code or not state:
        return HTMLResponse(
            "<h3>Invalid Callback: Missing 'code' or 'state' parameters.</h3>",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    service = IntegrationService(db)
    try:
        result = await service.handle_oauth_callback(code=code, state_token=state)
        # In a real browser flow, redirect back to Flutter admin dashboard with success status
        return HTMLResponse(
            f"""
            <html>
                <body style="background:#080D18;color:#F4F7FF;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;">
                    <div style="background:#111C2E;padding:32px;border-radius:16px;text-align:center;border:1px solid #1E2D48;">
                        <h2 style="color:#22C58B;">Successfully Connected!</h2>
                        <p>{result['message']}</p>
                        <p style="color:#9AA9BF;font-size:13px;">You can now close this tab and return to SocialFlow AI.</p>
                        <script>
                            setTimeout(function() {{
                                if (window.opener) {{
                                    window.opener.postMessage({{ type: 'OAUTH_SUCCESS', platform: '{platform}' }}, '*');
                                    window.close();
                                }}
                            }}, 1500);
                        </script>
                    </div>
                </body>
            </html>
            """
        )
    except Exception as e:
        logger.error("OAuth callback error: %s", e)
        return HTMLResponse(
            f"""
            <html>
                <body style="background:#080D18;color:#F4F7FF;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;">
                    <div style="background:#111C2E;padding:32px;border-radius:16px;text-align:center;border:1px solid #F16D78;">
                        <h2 style="color:#F16D78;">Connection Failed</h2>
                        <p>{str(e)}</p>
                    </div>
                </body>
            </html>
            """,
            status_code=status.HTTP_400_BAD_REQUEST,
        )


@router.post("/{platform}/callback")
async def handle_direct_api_callback(
    platform: str,
    payload: Dict[str, str],
    db: Session = Depends(get_db),
):
    """Direct API endpoint for mobile/desktop Flutter apps exchanging code and state."""
    code = payload.get("code")
    state = payload.get("state")
    if not code or not state:
        raise AppException(
            status_code=status.HTTP_400_BAD_REQUEST,
            error_code="INVALID_PAYLOAD",
            detail="Payload must include 'code' and 'state'.",
        )

    service = IntegrationService(db)
    result = await service.handle_oauth_callback(code=code, state_token=state)
    return {
        "status": "success",
        "message": result["message"],
        "account_id": result["account"].id,
        "platform_account_id": result["account"].platform_account_id,
        "discovered_channels": result["discovered_channels"],
    }


@router.post("/select-page", response_model=SocialAccountResponse)
async def connect_selected_page(
    payload: SelectPageRequest,
    member: WorkspaceMember = Depends(require_permission("accounts:connect")),
    db: Session = Depends(get_db),
):
    """Connect a specific Facebook Page or Instagram Business account discovered during OAuth."""
    service = IntegrationService(db)
    return await service.connect_discovered_page(
        workspace_id=member.workspace_id,
        platform=payload.platform,
        channel_id=payload.channel_id,
        channel_name=payload.channel_name,
        access_token=payload.access_token,
        account_type=payload.account_type,
        avatar_url=payload.avatar_url,
    )


@router.post("/telegram/connect-bot", response_model=SocialAccountResponse)
async def connect_telegram_bot(
    payload: TelegramConnectRequest,
    member: WorkspaceMember = Depends(require_permission("accounts:connect")),
    db: Session = Depends(get_db),
):
    """Connect and validate Telegram Bot Token and optional channel administrator permissions."""
    service = IntegrationService(db)
    return await service.connect_telegram(
        workspace_id=member.workspace_id,
        bot_token=payload.bot_token,
        chat_id=payload.chat_id,
    )


@router.post("/whatsapp/onboard", response_model=SocialAccountResponse)
async def onboard_whatsapp_business(
    payload: WhatsAppOnboardRequest,
    member: WorkspaceMember = Depends(require_permission("accounts:connect")),
    db: Session = Depends(get_db),
):
    """Connect official WhatsApp Business Account using verified Phone Number ID and WABA ID."""
    from app.integrations.whatsapp.whatsapp_provider import WhatsAppProvider
    provider = WhatsAppProvider()

    # Validate token and phone number ID
    profile = await provider.fetch_profile(payload.access_token, account_id=payload.phone_number_id)
    service = IntegrationService(db)
    account = service._upsert_account(
        workspace_id=member.workspace_id,
        platform="whatsapp",
        profile=profile,
    )
    from app.integrations.base.token_manager import TokenManager
    TokenManager.encrypt_and_store(
        db=db,
        account_id=account.id,
        access_token=payload.access_token,
    )
    service._log_audit(
        workspace_id=member.workspace_id,
        action="whatsapp_onboarded",
        entity_id=account.id,
        metadata=f"Connected WhatsApp Business phone: {profile.username} (WABA ID: {payload.waba_id})",
    )
    db.commit()
    return account


@router.get("/whatsapp/webhook")
def verify_whatsapp_webhook(
    request: Request,
    hub_mode: str = Query(..., alias="hub.mode"),
    hub_verify_token: str = Query(..., alias="hub.verify_token"),
    hub_challenge: str = Query(..., alias="hub.challenge"),
):
    """Meta WhatsApp Webhook subscription verification endpoint."""
    from app.integrations.whatsapp.whatsapp_provider import WhatsAppProvider
    provider = WhatsAppProvider()
    challenge = provider.verify_webhook(hub_mode, hub_verify_token, hub_challenge)
    if challenge:
        return Response(content=challenge, media_type="text/plain")
    return Response(content="Verification failed", status_code=status.HTTP_403_FORBIDDEN)


@router.post("/whatsapp/webhook")
async def receive_whatsapp_webhook(
    request: Request,
    db: Session = Depends(get_db),
):
    """Ingest WhatsApp Cloud API incoming status receipts and messages."""
    body_bytes = await request.body()
    body_text = body_bytes.decode("utf-8")

    event = IntegrationEvent(
        platform="whatsapp",
        event_type="cloud_api_webhook",
        payload_json=body_text,
        processed_at=datetime.now(timezone.utc),
        status="received",
    )
    db.add(event)
    db.commit()
    return {"status": "event_received"}

