"""merge partyvote and law heads

Revision ID: a4c81e7d2f90
Revises: 5360b77ec63d, ed20261006g
Create Date: 2026-11-24

"""
from typing import Sequence, Union


# revision identifiers, used by Alembic.
revision: str = 'a4c81e7d2f90'
down_revision: Union[str, Sequence[str], None] = ('5360b77ec63d', 'ed20261006g')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
