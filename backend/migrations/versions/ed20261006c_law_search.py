"""Index French full-text searches and paginated status feeds."""

from alembic import op

revision = "ed20261006c"
down_revision = "ed20261006b"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        "CREATE INDEX ix_law_search ON law USING GIN (to_tsvector('french', coalesce(title, '') || ' ' || coalesce(description, '')))"
    )
    op.execute(
        "CREATE INDEX ix_law_status_activity ON law (status, activity_at DESC, id DESC) WHERE is_active"
    )


def downgrade() -> None:
    op.drop_index("ix_law_status_activity", table_name="law")
    op.drop_index("ix_law_search", table_name="law")
