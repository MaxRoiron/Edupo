"""Preserve old imports, introduce source identity and official vote history.

Revision ID: ed20261006
Revises: 1f726fc15d84
"""

from alembic import op
import sqlalchemy as sa

revision = "ed20261006"
down_revision = "1f726fc15d84"
branch_labels = None
depends_on = None


def upgrade() -> None:
    for column in [
        sa.Column("official_title", sa.String()),
        sa.Column("short_title", sa.String()),
        sa.Column("source_key", sa.String()),
        sa.Column("source", sa.String(), nullable=False, server_default="manual"),
        sa.Column("status", sa.String(), nullable=False, server_default="unknown"),
        sa.Column("relevance", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()
        ),
        sa.Column("last_seen_at", sa.DateTime()),
        sa.Column("published_at", sa.DateTime()),
        sa.Column("legacy_data", sa.JSON()),
    ]:
        op.add_column("law", column)
    # No law is deleted. Unverified imports are archived until the official
    # adapters can re-identify them; fabricated dates never remain live dates.
    connection = op.get_bind()
    rows = connection.execute(sa.text("SELECT * FROM law")).mappings().all()
    from app.modules.law.text import (
        clean_law_title,
        plain_text,
        subject_title,
        canonical_url,
    )
    import re

    for row in rows:
        original = dict(row)
        for key, value in original.items():
            if hasattr(value, "isoformat"):
                original[key] = value.isoformat()
        title = row["title"]
        match = re.search(
            r"Le texte original est intitulé : '(.*?)'\.\s*\nVote effectué",
            row["description"],
            re.S,
        )
        official = match.group(1) if match else title
        source_url = row["source_url"]
        link = re.search(
            r"https?://www\.vie-publique\.fr/loi/[^\s<]+", row["description"]
        )
        if link and not source_url:
            source_url = canonical_url(link.group())
        imported = bool(row["scrutin_id"] or row.get("subtitle"))
        connection.execute(
            sa.text("""UPDATE law SET official_title=:official,
            short_title=:short, title=:title, description=:description,
            source_key=:key, source=:source, status='unknown', source_url=:url,
            vote_date=NULL, scrutin_id=NULL, is_active=:active, legacy_data=CAST(:legacy AS JSON)
            WHERE id=:id"""),
            {
                "official": official,
                "short": subject_title(official),
                "title": clean_law_title(official),
                "description": plain_text(row["description"]),
                "key": f"legacy:{row['id']}" if imported else None,
                "source": "legacy" if imported else "manual",
                "url": source_url,
                "active": False if imported else row["is_active"],
                "legacy": __import__("json").dumps(original, ensure_ascii=False),
                "id": row["id"],
            },
        )
    op.drop_column("law", "subtitle")
    op.create_index("ix_law_source_key", "law", ["source_key"], unique=True)
    op.create_index("ix_law_status", "law", ["status"])
    op.create_index("ix_law_feed", "law", ["is_active", "status", "updated_at"])
    op.drop_index("ix_law_scrutin_id", table_name="law")
    op.create_index("ix_law_scrutin_id", "law", ["scrutin_id"], unique=True)
    op.create_table(
        "lawscrutin",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("uid", sa.String(), nullable=False),
        sa.Column("law_id", sa.Integer(), sa.ForeignKey("law.id"), nullable=False),
        sa.Column("vote_date", sa.DateTime(), nullable=False),
        sa.Column("source_url", sa.String(), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
    )
    op.create_index("ix_lawscrutin_uid", "lawscrutin", ["uid"], unique=True)
    op.create_index("ix_lawscrutin_law_id", "lawscrutin", ["law_id"])
    op.create_table(
        "lawsyncstate",
        sa.Column("source", sa.String(), primary_key=True),
        sa.Column("last_success_at", sa.DateTime()),
        sa.Column("last_attempt_at", sa.DateTime()),
        sa.Column("error", sa.String()),
        sa.Column("etag", sa.String()),
        sa.Column("modified", sa.String()),
    )
    # Keep the latest existing choice if historical duplicates exist.
    connection.execute(
        sa.text(
            "DELETE FROM uservote a USING uservote b WHERE a.user_id=b.user_id AND a.law_id=b.law_id AND a.id<b.id"
        )
    )
    op.create_unique_constraint(
        "uq_uservote_user_law", "uservote", ["user_id", "law_id"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_uservote_user_law", "uservote", type_="unique")
    op.drop_table("lawsyncstate")
    op.drop_table("lawscrutin")
    op.add_column("law", sa.Column("subtitle", sa.String()))
    op.execute(
        "UPDATE law SET subtitle=legacy_data->>'subtitle' WHERE legacy_data IS NOT NULL"
    )
    op.drop_index("ix_law_source_key", table_name="law")
    op.drop_index("ix_law_status", table_name="law")
    op.drop_index("ix_law_feed", table_name="law")
    op.drop_index("ix_law_scrutin_id", table_name="law")
    op.create_index("ix_law_scrutin_id", "law", ["scrutin_id"])
    for column in [
        "official_title",
        "short_title",
        "source_key",
        "source",
        "status",
        "relevance",
        "updated_at",
        "last_seen_at",
        "published_at",
        "legacy_data",
    ]:
        op.drop_column("law", column)
