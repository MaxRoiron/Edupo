#!/bin/sh
set -eu
alembic upgrade head
if [ "${EDUPO_RELOAD:-true}" = "true" ]; then
    exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
fi
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers "${WEB_CONCURRENCY:-1}"
