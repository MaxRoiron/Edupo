import os
from pydantic import computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_SERVER: str
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str

    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    LAW_SOURCE_CACHE_DIR: str = ".cache/laws"
    LAW_SYNC_ENABLED: bool = True
    LAW_SYNC_INTERVAL_SECONDS: int = 21600
    LAW_SYNC_COOLDOWN_SECONDS: int = 60
    LAW_LEGISLATURE: int = 17
    LAW_SYNC_TIMEOUT_SECONDS: int = 30

    @computed_field
    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+psycopg2://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"


settings = Settings()
DATABASE_URL = settings.DATABASE_URL
