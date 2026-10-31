"""Delete citizen opinions together with their owner's account."""

from alembic import op

revision = "ed20261006f"
down_revision = "ed20261006e"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_constraint("uservote_user_id_fkey", "uservote", type_="foreignkey")
    op.create_foreign_key(
        "uservote_user_id_fkey",
        "uservote",
        "user",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )


def downgrade() -> None:
    op.drop_constraint("uservote_user_id_fkey", "uservote", type_="foreignkey")
    op.create_foreign_key(
        "uservote_user_id_fkey", "uservote", "user", ["user_id"], ["id"]
    )
