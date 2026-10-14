"""Apply source snapshots transactionally, preserving public IDs and votes."""

from datetime import datetime, timedelta, timezone
from sqlmodel import Session, select
from app.modules.country.model import Country
from app.modules.political_party.model import Domain
from app.core.config import settings
from .model import Law, LawScrutin
from .sources import parse_date, category_for
from .text import clean_law_title, subject_title, relevance_score


def _utc(value):
    if value is None:
        return None
    return (
        value.replace(tzinfo=timezone.utc)
        if value.tzinfo is None
        else value.astimezone(timezone.utc)
    )


def persist_records(session: Session, records: dict, now: datetime) -> dict:
    country = session.exec(select(Country).where(Country.iso_code == "FR")).first()
    if country is None:
        country = Country(name="France", iso_code="FR")
        session.add(country)
    domain = session.exec(select(Domain).where(Domain.name == "Général")).first()
    if domain is None:
        domain = Domain(name="Général")
        session.add(domain)
    session.flush()
    existing = session.exec(select(Law)).all()
    by_id = {law.id: law for law in existing}
    by_key = {law.source_key: law for law in existing if law.source_key}
    by_url = {
        url: law
        for law in existing
        for url in {*law.source_urls, law.source_url}
        if url
    }
    by_uid = {}
    for law in existing:
        uid = law.scrutin_id or (law.legacy_data or {}).get("scrutin_id")
        if uid and uid.startswith("VTAN"):
            by_uid[uid] = law
    scrutin_rows = {item.uid: item for item in session.exec(select(LawScrutin)).all()}
    created, updated = 0, 0
    for key, record in records.items():
        law = by_key.get(key)
        if law and law.merged_into_id:
            law = by_id.get(law.merged_into_id)
        if law is None:
            matches = [by_uid[s["uid"]] for s in record.scrutins if s["uid"] in by_uid]
            matches += [
                by_url[url]
                for url in record.aliases
                if url in by_url and not by_url[url].merged_into_id
            ]
            law = min(matches, key=lambda item: item.id) if matches else None
        fresh = law is None
        if fresh:
            law = Law(
                title="", description="", domain_id=domain.id, country_id=country.id
            )
        previous_description = (
            law.description
            if not law.description.startswith("Le texte original est intitulé")
            else ""
        )
        description = (
            record.description
            or previous_description
            or (
                "Le résumé pédagogique de ce texte n’est pas encore disponible. "
                "Consultez le dossier officiel pour lire le texte et suivre ses étapes."
            )
        )
        activity = record.activity_at
        # If AN is temporarily unavailable, RSS updates must not downgrade an
        # already identified dossier or erase its official result history.
        if law.source == "assemblee" and record.source == "vie_publique":
            law.description = description
            law.description_source_url = record.description_source_url
            law.source_urls = sorted(set(law.source_urls) | record.aliases)
            law.last_seen_at = now
            law.updated_at = now
            session.add(law)
            continue
        values = dict(
            source_key=key,
            source=record.source,
            official_title=record.official_title,
            short_title=subject_title(record.official_title),
            title=clean_law_title(record.official_title),
            description=description,
            source_url=record.source_url,
            status=record.status,
            source_urls=sorted(
                set(law.source_urls) | record.aliases | {record.source_url}
            ),
            description_source_url=record.description_source_url
            or law.description_source_url,
            vote_date=record.vote_date,
            published_at=record.published_at,
            activity_at=activity,
            scrutin_id=record.scrutins[-1]["uid"] if record.scrutins else None,
            category=category_for(record.official_title, description),
            relevance=relevance_score(record.official_title, description),
            is_active=not law.hidden_by_admin
            and record.status != "withdrawn"
            and (activity is None or activity >= now - timedelta(days=365)),
        )
        changed = fresh or any(
            (
                _utc(getattr(law, field)) != _utc(value)
                if field in {"vote_date", "published_at", "activity_at"}
                else getattr(law, field) != value
            )
            for field, value in values.items()
        )
        for field, value in values.items():
            setattr(law, field, value)
        law.last_seen_at = now
        if changed:
            law.updated_at = now
            updated += not fresh
        session.add(law)
        if fresh:
            session.flush()
        by_key[key] = law
        created += fresh
        # Merge only identities proven by official links or exact dossier refs.
        duplicates = {
            item.id: item
            for url in record.aliases
            if (item := by_url.get(url)) is not None
            and item.id != law.id
            and not item.merged_into_id
        }
        from app.modules.user_vote.model import UserVote
        from app.modules.political_party.model import PartyVote
        from .model import VoteResult

        for duplicate in duplicates.values():
            for vote in session.exec(
                select(UserVote).where(UserVote.law_id == duplicate.id)
            ).all():
                current = session.exec(
                    select(UserVote).where(
                        UserVote.law_id == law.id, UserVote.user_id == vote.user_id
                    )
                ).first()
                if current:
                    if vote.id > current.id:
                        current.position_id = vote.position_id
                        session.add(current)
                    session.delete(vote)
                else:
                    vote.law_id = law.id
                    session.add(vote)
            for model in (PartyVote, VoteResult, LawScrutin):
                for row in session.exec(
                    select(model).where(model.law_id == duplicate.id)
                ).all():
                    row.law = law
                    session.add(row)
            duplicate.is_active = False
            duplicate.merged_into_id = law.id
            duplicate.scrutin_id = None
            session.add(duplicate)
        for url in record.aliases:
            by_url[url] = law
        for scrutin in record.scrutins:
            uid = scrutin["uid"]
            row = scrutin_rows.get(uid)
            if row is None:
                row = LawScrutin(
                    uid=uid,
                    law=law,
                    vote_date=parse_date(scrutin["dateScrutin"]),
                    source_url=f'https://www.assemblee-nationale.fr/dyn/{settings.LAW_LEGISLATURE}/scrutins/{scrutin["numero"]}',
                    payload=scrutin,
                )
                scrutin_rows[uid] = row
            row.law = law
            row.payload = scrutin
            session.add(row)
    session.flush()
    return {"created": created, "updated": updated, "records": len(records)}
