import sys
import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

# Ajout du répertoire racine du projet au sys.path pour les imports
# On suppose que alembic est lancé depuis le dossier 'backend'
sys.path.insert(0, os.getcwd())

# Import de SQLModel et des modèles
from sqlmodel import SQLModel
from app.core.config import settings
# Import de tous les modèles pour qu'ils soient connus d'Alembic
from app.modules import User, ProfessionalStatus, SocialStatus, GenderIdentities, UserData, Country, Institution, InstitutionType, Power

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# On utilise l'URL de base de données de notre configuration
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
target_metadata = SQLModel.metadata

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    # On crée l'engine à partir de notre URL
    from sqlmodel import create_engine
    connectable = create_engine(settings.DATABASE_URL)

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
