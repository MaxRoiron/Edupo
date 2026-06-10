"""merge

Revision ID: 234647c8e9eb
Revises: cf648fe60467, e68dac8d0026
Create Date: 2026-03-19 14:16:45.976810

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '234647c8e9eb'
down_revision: Union[str, Sequence[str], None] = ('cf648fe60467', 'e68dac8d0026')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
