"""Tie HTTP cache validation to the transaction that imported the snapshot."""

from alembic import op
import sqlalchemy as sa

revision = "ed20261006g"
down_revision = "ed20261006f"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("lawsyncstate", sa.Column("content_hash", sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column("lawsyncstate", "content_hash")
