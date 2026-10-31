"""Preserve administrative hiding across automatic source refreshes."""

from alembic import op
import sqlalchemy as sa

revision = "ed20261006e"
down_revision = "ed20261006d"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "law",
        sa.Column(
            "hidden_by_admin", sa.Boolean(), nullable=False, server_default=sa.false()
        ),
    )


def downgrade() -> None:
    op.drop_column("law", "hidden_by_admin")
