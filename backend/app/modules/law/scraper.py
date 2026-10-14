"""Idempotent source synchronization, shared by startup, clients and admins."""

import asyncio
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone, timedelta
import hashlib
import logging
from pathlib import Path
import re
import time

import httpx
from sqlalchemy import text as sql_text, update
from sqlmodel import Session, select
from app.core.config import settings
from app.core.database import engine
from .model import Law, LawSyncState
from .sources import (
    OfficialLinks,
    parse_dossiers,
    parse_scrutins,
    parse_rss,
    merge_rss,
    zip_documents,
)
from .text import clean_law_title  # compatibility for existing callers

from .repository import persist_records

logger = logging.getLogger(__name__)
SYNC_LOCK = 0x45445550
# A new parser/formatter release must reprocess unchanged official snapshots.
PROCESSOR_VERSION = hashlib.sha256(
    b"".join(
        Path(__file__).with_name(name).read_bytes()
        for name in ("text.py", "sources.py", "repository.py")
    )
).hexdigest()
_task: asyncio.Task | None = None


def source_urls() -> dict[str, str]:
    base = f"https://data.assemblee-nationale.fr/static/openData/repository/{settings.LAW_LEGISLATURE}"
    return {
        "rss": "https://www.vie-publique.fr/lois-feeds.xml",
        "dossiers": base + "/loi/dossiers_legislatifs/Dossiers_Legislatifs.json.zip",
        "scrutins": base + "/loi/scrutins/Scrutins.json.zip",
        "organes": base
        + "/amo/deputes_actifs_mandats_actifs_organes/AMO10_deputes_actifs_mandats_actifs_organes.json.zip",
    }


def _download(name: str, url: str, state: dict) -> tuple[bytes, dict]:
    folder = Path(settings.LAW_SOURCE_CACHE_DIR)
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / f"{settings.LAW_LEGISLATURE}-{name}"
    cached = path.read_bytes() if path.exists() else None
    cached_hash = hashlib.sha256(cached).hexdigest() if cached is not None else None
    # Disk writes precede the database transaction. Only a snapshot whose hash
    # was committed with its laws may use conditional HTTP requests.
    committed_cache = cached_hash is not None and cached_hash == state.get(
        "content_hash"
    )
    headers = {"User-Agent": "Edupo/1.0 (education citoyenne; official open data)"}
    if committed_cache:
        if state.get("etag"):
            headers["If-None-Match"] = state["etag"]
        if state.get("modified"):
            headers["If-Modified-Since"] = state["modified"]
    for attempt in range(3):
        try:
            with httpx.Client(
                timeout=settings.LAW_SYNC_TIMEOUT_SECONDS, follow_redirects=True
            ) as client:
                with client.stream("GET", url, headers=headers) as response:
                    if response.status_code == 304:
                        if not committed_cache:
                            raise ValueError("Réponse 304 sans snapshot validé en base")
                        return cached, {**state, "not_modified": True}
                    response.raise_for_status()
                    chunks, size = [], 0
                    for chunk in response.iter_bytes():
                        size += len(chunk)
                        if size > 64 * 1024 * 1024:
                            raise ValueError("Réponse officielle trop volumineuse")
                        chunks.append(chunk)
                    content = b"".join(chunks)
                    # Validate before replacing a previously valid disk cache.
                    if name == "rss":
                        parse_rss(content)
                    else:
                        next(zip_documents(content))
                    content_hash = hashlib.sha256(content).hexdigest()
                    if cached_hash != content_hash:
                        temporary = path.with_suffix(".tmp")
                        temporary.write_bytes(content)
                        temporary.replace(path)
                    return content, {
                        "etag": response.headers.get("etag"),
                        "modified": response.headers.get("last-modified"),
                        "content_hash": content_hash,
                        "not_modified": content_hash == state.get("content_hash"),
                    }
        except (httpx.HTTPError, ValueError, OSError) as error:
            if attempt == 2:
                raise RuntimeError(
                    f"{name}: source indisponible ou invalide"
                ) from error
            time.sleep(2**attempt)
    raise RuntimeError(name)


def _rss_links(entry) -> tuple[str, set[str]]:
    # Sources are fixed trusted URLs from the official RSS, never user input.
    if not re.match(r"^https://www\.vie-publique\.fr/loi/", entry.source_url):
        return entry.key, set()
    folder = Path(settings.LAW_SOURCE_CACHE_DIR)
    cache = folder / (
        "article-" + hashlib.sha256(entry.source_url.encode()).hexdigest()
    )
    # Dossier links are stable; refresh the cached mapping at least daily.
    if cache.exists() and time.time() - cache.stat().st_mtime < 86400:
        return entry.key, set(cache.read_text().splitlines())
    try:
        with httpx.Client(timeout=5, follow_redirects=True) as client:
            response = client.get(entry.source_url)
            response.raise_for_status()
        parser = OfficialLinks()
        parser.feed(response.text)
        cache.write_text("\n".join(sorted(parser.links)))
        return entry.key, parser.links
    except httpx.HTTPError:
        logger.warning("Lien de dossier indisponible pour %s", entry.key)
        return entry.key, (
            set(cache.read_text().splitlines()) if cache.exists() else set()
        )


def _sync_once(force: bool = False) -> dict:
    now = datetime.now(timezone.utc)
    with engine.connect() as connection:
        postgres = connection.dialect.name == "postgresql"
        if (
            postgres
            and not connection.execute(
                sql_text("SELECT pg_try_advisory_lock(:key)"), {"key": SYNC_LOCK}
            ).scalar()
        ):
            connection.rollback()
            return {"status": "busy", "message": "Synchronisation déjà en cours"}
        connection.commit()
        try:
            with Session(bind=connection) as session:
                states = {
                    state.source: state
                    for state in session.exec(select(LawSyncState)).all()
                }
                last = states.get("sync")
                attempt = last.last_attempt_at if last else None
                if attempt and attempt.tzinfo is None:
                    attempt = attempt.replace(tzinfo=timezone.utc)
                if (
                    not force
                    and attempt
                    and last.etag == PROCESSOR_VERSION
                    and (now - attempt).total_seconds()
                    < settings.LAW_SYNC_COOLDOWN_SECONDS
                ):
                    return {
                        "status": "cached",
                        "last_success_at": last.last_success_at,
                        "message": last.error,
                    }
                last = last or LawSyncState(source="sync")
                last.last_attempt_at = now
                session.add(last)
                session.commit()
                headers = {
                    key: {
                        "etag": value.etag,
                        "modified": value.modified,
                        "content_hash": value.content_hash,
                    }
                    for key, value in states.items()
                }
                contents, errors, response_headers = {}, {}, {}
                with ThreadPoolExecutor(max_workers=4) as executor:
                    futures = {
                        name: executor.submit(
                            _download, name, url, headers.get(name, {})
                        )
                        for name, url in source_urls().items()
                    }
                    for name, future in futures.items():
                        try:
                            contents[name], response_headers[name] = future.result()
                        except Exception:
                            errors[name] = (
                                f"Source {name} indisponible; données précédentes conservées"
                            )
                            logger.exception("Échec du téléchargement %s", name)
                if (
                    not force
                    and not errors
                    and last.last_success_at
                    and last.error is None
                    and last.etag == PROCESSOR_VERSION
                    and all(
                        metadata.get("not_modified")
                        for metadata in response_headers.values()
                    )
                ):
                    completed = datetime.now(timezone.utc)
                    last.last_attempt_at = last.last_success_at = completed
                    session.add(last)
                    for name, metadata in response_headers.items():
                        state = states.get(name) or LawSyncState(source=name)
                        state.etag = metadata.get("etag", state.etag)
                        state.modified = metadata.get("modified", state.modified)
                        state.content_hash = metadata.get(
                            "content_hash", state.content_hash
                        )
                        state.last_attempt_at = state.last_success_at = completed
                        state.error = None
                        session.add(state)
                    session.execute(
                        update(Law)
                        .where(
                            Law.source.in_(["assemblee", "vie_publique"]),
                            Law.activity_at < now - timedelta(days=365),
                        )
                        .values(is_active=False)
                    )
                    session.commit()
                    connection.commit()
                    return {
                        "status": "ok",
                        "not_modified": True,
                        "created": 0,
                        "updated": 0,
                        "records": 0,
                        "errors": {},
                        "last_success_at": completed,
                    }
                records = {}
                if "dossiers" in contents and "scrutins" in contents:
                    records, references = parse_dossiers(
                        contents["dossiers"], settings.LAW_LEGISLATURE
                    )
                    parse_scrutins(
                        contents["scrutins"],
                        records,
                        references,
                        settings.LAW_LEGISLATURE,
                    )
                if "rss" in contents:
                    rss = parse_rss(contents["rss"])
                    with ThreadPoolExecutor(max_workers=4) as executor:
                        links = dict(executor.map(_rss_links, rss))
                    merge_rss(records, rss, links)
                # Per-source atomic transaction: a failure never deactivates its prior feed.
                result = (
                    persist_records(session, records, now)
                    if records
                    else {"created": 0, "updated": 0, "records": 0}
                )
                if "dossiers" in contents and "scrutins" in contents:
                    for old in session.exec(
                        select(Law).where(
                            Law.source == "assemblee", Law.is_active == True
                        )
                    ).all():
                        if old.source_key not in records:
                            old.is_active = False
                            session.add(old)
                # RSS is a rolling feed: absence from it does not imply withdrawal.
                completed = datetime.now(timezone.utc)
                last.last_attempt_at = completed
                for name, metadata in response_headers.items():
                    state = states.get(name) or LawSyncState(source=name)
                    state.last_success_at = completed
                    state.last_attempt_at = completed
                    state.error = None
                    state.etag, state.modified = metadata.get("etag"), metadata.get(
                        "modified"
                    )
                    state.content_hash = metadata.get("content_hash")
                    session.add(state)
                for name, error in errors.items():
                    state = states.get(name) or LawSyncState(source=name)
                    state.last_attempt_at, state.error = now, error
                    session.add(state)
                last.etag = PROCESSOR_VERSION
                last.error = "; ".join(errors.values()) or None
                if records and not errors:
                    last.last_success_at = completed
                session.add(last)
                session.commit()
                connection.commit()
                result.update(
                    status=(
                        "partial"
                        if errors and records
                        else "failed" if errors else "ok"
                    ),
                    errors=errors,
                    last_success_at=last.last_success_at,
                )
                logger.info("Synchronisation lois: %s", result)
                return result
        except Exception:
            connection.rollback()
            logger.exception("Synchronisation annulée, données précédentes conservées")
            with Session(bind=connection) as session:
                state = session.get(LawSyncState, "sync") or LawSyncState(source="sync")
                state.etag = PROCESSOR_VERSION
                state.last_attempt_at, state.error = (
                    now,
                    "Synchronisation échouée; données précédentes conservées",
                )
                session.add(state)
                session.commit()
                connection.commit()
            return {
                "status": "failed",
                "errors": {
                    "sync": "Synchronisation échouée; données précédentes conservées"
                },
            }
        finally:
            if postgres:
                connection.execute(
                    sql_text("SELECT pg_advisory_unlock(:key)"), {"key": SYNC_LOCK}
                )
                connection.commit()


async def _coordinated_sync(force: bool) -> dict:
    result = await asyncio.to_thread(_sync_once, force)
    # Other workers share the PostgreSQL lock. Wait for their snapshot instead
    # of presenting an empty feed on the first cold launch.
    for _ in range(120):
        if result.get("status") != "busy":
            return result
        await asyncio.sleep(1)
        result = await asyncio.to_thread(_sync_once, False)
    return result


async def synchronize_laws(force: bool = False) -> dict:
    global _task
    if not settings.LAW_SYNC_ENABLED:
        return {"status": "disabled"}
    if _task is None or _task.done():
        _task = asyncio.create_task(_coordinated_sync(force))
    # A client disconnect must not cancel a shared synchronization.
    return await asyncio.shield(_task)


async def periodic_law_scraper() -> None:
    while True:
        await synchronize_laws()
        await asyncio.sleep(settings.LAW_SYNC_INTERVAL_SECONDS)


async def scrape_and_sync_laws() -> dict:
    return await synchronize_laws()


async def resync_voted_laws() -> dict:
    return await synchronize_laws(force=True)
