"""phase4_integrations_and_webhooks

Revision ID: 7a391c49e218
Revises: 085e6c54603c
Create Date: 2026-11-14 12:28:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7a391c49e218'
down_revision: Union[str, None] = '085e6c54603c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add code_verifier to oauth_states using batch mode for SQLite compatibility
    with op.batch_alter_table('oauth_states', schema=None) as batch_op:
        batch_op.add_column(sa.Column('code_verifier', sa.String(length=128), nullable=True))

    # 2. Create webhook_subscriptions table
    op.create_table(
        'webhook_subscriptions',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('workspace_id', sa.String(length=36), nullable=False),
        sa.Column('platform', sa.String(length=32), nullable=False),
        sa.Column('subscription_id', sa.String(length=255), nullable=True),
        sa.Column('endpoint_url', sa.String(length=512), nullable=False),
        sa.Column('secret', sa.String(length=255), nullable=True),
        sa.Column('status', sa.String(length=32), server_default='active', nullable=False),
        sa.Column('event_types', sa.Text(), nullable=True),
        sa.Column('last_event_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['workspace_id'], ['workspaces.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_webhook_subscriptions_workspace_id'), 'webhook_subscriptions', ['workspace_id'], unique=False)
    op.create_index(op.f('ix_webhook_subscriptions_platform'), 'webhook_subscriptions', ['platform'], unique=False)

    # 3. Create integration_events table
    op.create_table(
        'integration_events',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('workspace_id', sa.String(length=36), nullable=True),
        sa.Column('platform', sa.String(length=32), nullable=False),
        sa.Column('event_type', sa.String(length=128), nullable=False),
        sa.Column('payload_json', sa.Text(), nullable=False),
        sa.Column('processed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('status', sa.String(length=32), server_default='received', nullable=False),
        sa.Column('error_details', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['workspace_id'], ['workspaces.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_integration_events_workspace_id'), 'integration_events', ['workspace_id'], unique=False)
    op.create_index(op.f('ix_integration_events_platform'), 'integration_events', ['platform'], unique=False)
    op.create_index(op.f('ix_integration_events_event_type'), 'integration_events', ['event_type'], unique=False)

    # 4. Create integration_sync_logs table
    op.create_table(
        'integration_sync_logs',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('account_id', sa.String(length=36), nullable=False),
        sa.Column('sync_type', sa.String(length=64), nullable=False),
        sa.Column('status', sa.String(length=32), nullable=False),
        sa.Column('details', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['account_id'], ['social_accounts.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_integration_sync_logs_account_id'), 'integration_sync_logs', ['account_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_integration_sync_logs_account_id'), table_name='integration_sync_logs')
    op.drop_table('integration_sync_logs')

    op.drop_index(op.f('ix_integration_events_event_type'), table_name='integration_events')
    op.drop_index(op.f('ix_integration_events_platform'), table_name='integration_events')
    op.drop_index(op.f('ix_integration_events_workspace_id'), table_name='integration_events')
    op.drop_table('integration_events')

    op.drop_index(op.f('ix_webhook_subscriptions_platform'), table_name='webhook_subscriptions')
    op.drop_index(op.f('ix_webhook_subscriptions_workspace_id'), table_name='webhook_subscriptions')
    op.drop_table('webhook_subscriptions')

    with op.batch_alter_table('oauth_states', schema=None) as batch_op:
        batch_op.drop_column('code_verifier')

