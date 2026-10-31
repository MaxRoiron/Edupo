"""Retain summary attribution and identity links across source outages."""

from alembic import op
import sqlalchemy as sa

revision = "ed20261006d"
down_revision = "ed20261006c"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "law", sa.Column("source_urls", sa.JSON(), nullable=False, server_default="[]")
    )
    op.add_column("law", sa.Column("description_source_url", sa.String()))
    op.execute(
        "UPDATE law SET source_urls=json_build_array(source_url) WHERE source_url IS NOT NULL"
    )


def downgrade() -> None:
    op.drop_column("law", "description_source_url")
    op.drop_column("law", "source_urls")
