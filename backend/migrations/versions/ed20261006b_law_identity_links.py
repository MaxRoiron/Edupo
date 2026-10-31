"""Track legislative activity and explicit, lossless identity redirects."""

from alembic import op
import sqlalchemy as sa

revision = "ed20261006b"
down_revision = "ed20261006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("law", sa.Column("activity_at", sa.DateTime()))
    op.add_column(
        "law", sa.Column("merged_into_id", sa.Integer(), sa.ForeignKey("law.id"))
    )
    op.create_index("ix_law_activity_at", "law", ["activity_at"])
    op.execute(
        "UPDATE law SET activity_at=COALESCE(vote_date,published_at,updated_at) WHERE source != 'legacy'"
    )


def downgrade() -> None:
    op.drop_index("ix_law_activity_at", table_name="law")
    op.drop_column("law", "merged_into_id")
    op.drop_column("law", "activity_at")
