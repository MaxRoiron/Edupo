"""Official-source adapters. No network or database work during parsing."""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from html.parser import HTMLParser
import io
import json
import re
import zipfile
import xml.etree.ElementTree as ET
from .text import (
    canonical_url,
    plain_text,
    normalized_subject,
    subject_title,
    relevance_score,
)


@dataclass
class LawRecord:
    key: str
    official_title: str
    source_url: str
    source: str
    status: str = "pending"
    description: str = ""
    vote_date: datetime | None = None
    published_at: datetime | None = None
    activity_at: datetime | None = None
    scrutins: list[dict] = field(default_factory=list)
    aliases: set[str] = field(default_factory=set)
    description_source_url: str | None = None


def parse_date(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        date = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        try:
            date = parsedate_to_datetime(value)
        except (ValueError, TypeError):
            return None
    return (
        date.replace(tzinfo=timezone.utc)
        if date.tzinfo is None
        else date.astimezone(timezone.utc)
    )


def as_list(value) -> list:
    return value if isinstance(value, list) else [value] if value else []


def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)


def zip_documents(content: bytes, prefix: str = "json/"):
    with zipfile.ZipFile(io.BytesIO(content)) as archive:
        if sum(info.file_size for info in archive.infolist()) > 512 * 1024 * 1024:
            raise ValueError("Archive officielle trop volumineuse")
        for name in archive.namelist():
            if name.startswith(prefix) and name.endswith(".json"):
                yield json.loads(archive.read(name))


def parse_dossiers(
    content: bytes, legislature: int
) -> tuple[dict[str, LawRecord], dict[str, str]]:
    records: dict[str, LawRecord] = {}
    votes: dict[str, str] = {}
    for document in zip_documents(content, "json/dossierParlementaire/"):
        dossier = document.get("dossierParlementaire") or {}
        if dossier.get("@xsi:type") != "DossierLegislatif_Type":
            continue
        uid = dossier.get("uid")
        title = plain_text((dossier.get("titreDossier") or {}).get("titre"))
        if not uid or not title:
            continue
        slug = (dossier.get("titreDossier") or {}).get("titreChemin") or uid
        url = f"https://www.assemblee-nationale.fr/dyn/{legislature}/dossiers/{slug}"
        record = LawRecord(
            f"an:{uid}", title, url, "assemblee", aliases={canonical_url(url)}
        )
        dates = []
        for act in walk(dossier.get("actesLegislatifs")):
            date = parse_date(act.get("dateActe"))
            if date:
                dates.append(date)
            if act.get("@xsi:type") == "Promulgation_Type" and date:
                record.status = "promulgated"
                # Publication is a French calendar date, not the preceding UTC day.
                record.published_at = parse_date(act["dateActe"][:10])
            if (
                act.get("@xsi:type") == "RetraitInitiative_Type"
                and record.status != "promulgated"
            ):
                record.status = "withdrawn"
            for vote_uid in as_list((act.get("voteRefs") or {}).get("voteRef")):
                if isinstance(vote_uid, str):
                    votes[vote_uid] = record.key
        record.activity_at = max(dates) if dates else None
        records[record.key] = record
    return records, votes


def parse_scrutins(
    content: bytes,
    records: dict[str, LawRecord],
    references: dict[str, str],
    legislature: int,
) -> None:
    # Exact normalized title is a conservative fallback for missing official refs.
    titles: dict[str, list[str]] = {}
    for key, record in records.items():
        titles.setdefault(normalized_subject(record.official_title), []).append(key)
    for document in zip_documents(content):
        scrutin = document.get("scrutin") or {}
        title = scrutin.get("titre") or ""
        if not re.search(
            r"(?i)l'ensemble (?:du projet|de la proposition) de loi", title
        ):
            continue
        uid = scrutin.get("uid")
        date = parse_date(scrutin.get("dateScrutin"))
        if not uid or not date:
            continue
        key = references.get(uid)
        if key is None:
            candidates = titles.get(normalized_subject(title), [])
            if len(candidates) == 1:
                key = candidates[0]
        # Unlinked readings are grouped by exact subject, never by a few words.
        if key is None:
            import hashlib

            key = (
                f"an-subject:{legislature}:"
                + hashlib.sha256(normalized_subject(title).encode()).hexdigest()
            )
            if key not in records:
                records[key] = LawRecord(
                    key,
                    subject_title(title),
                    f'https://www.assemblee-nationale.fr/dyn/{legislature}/scrutins/{scrutin.get("numero")}',
                    "assemblee",
                )
        records[key].scrutins.append(scrutin)
    for record in records.values():
        record.scrutins.sort(
            key=lambda s: (s["dateScrutin"], int(s.get("numero") or 0))
        )
        if record.scrutins:
            latest = record.scrutins[-1]
            record.vote_date = parse_date(latest["dateScrutin"])
            record.activity_at = max(
                filter(None, [record.activity_at, record.vote_date])
            )
            if record.status not in {"promulgated", "withdrawn"}:
                result = (latest.get("sort") or {}).get("code")
                record.status = {"adopté": "adopted", "rejeté": "rejected"}.get(
                    result, "unknown"
                )


def parse_rss(content: bytes) -> list[LawRecord]:
    root = ET.fromstring(content)
    dc = "{http://purl.org/dc/elements/1.1/}"
    records = []
    for item in root.findall(".//item"):
        title = plain_text(item.findtext("title"))
        link = item.findtext("link") or item.findtext("guid") or ""
        if not title or not link:
            continue
        url = canonical_url(link)
        identifier = item.findtext(dc + "identifier") or url
        kind = plain_text(item.findtext(dc + "type")).lower()
        status = (
            "promulgated"
            if re.match(r"(?i)^loi (?:du|n°)", title) or kind == "loi"
            else (
                "pending"
                if "projet de loi" in kind
                or "proposition de loi" in kind
                or re.match(r"(?i)^(?:projet|proposition) de loi", title)
                else "unknown"
            )
        )
        published = None
        if status == "promulgated":
            match = re.match(r"(?i)^loi du (\d{1,2})(?:er)? (\w+) (\d{4})", title)
            months = {
                "janvier": 1,
                "février": 2,
                "mars": 3,
                "avril": 4,
                "mai": 5,
                "juin": 6,
                "juillet": 7,
                "août": 8,
                "septembre": 9,
                "octobre": 10,
                "novembre": 11,
                "décembre": 12,
            }
            if match and match[2].lower() in months:
                try:
                    published = datetime(
                        int(match[3]),
                        months[match[2].lower()],
                        int(match[1]),
                        tzinfo=timezone.utc,
                    )
                except ValueError:
                    pass
        records.append(
            LawRecord(
                "vp:" + identifier,
                title,
                url,
                "vie_publique",
                status,
                plain_text(
                    item.findtext(dc + "description") or item.findtext("description")
                ),
                published_at=published,
                activity_at=parse_date(item.findtext("pubDate")),
                aliases={url},
                description_source_url=url,
            )
        )
    if not records:
        raise ValueError("Flux RSS sans fiches législatives")
    return records


class OfficialLinks(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list) -> None:
        if tag != "a":
            return
        url = dict(attrs).get("href", "")
        if re.match(
            r"^https?://(?:www\.)?assemblee-nationale\.fr/dyn/\d+/dossiers/", url
        ):
            self.links.add(canonical_url(url))


def merge_rss(
    records: dict[str, LawRecord], rss: list[LawRecord], links: dict[str, set[str]]
) -> None:
    by_url = {url: key for key, record in records.items() for url in record.aliases}
    by_title: dict[str, list[str]] = {}
    for key, record in records.items():
        by_title.setdefault(normalized_subject(record.official_title), []).append(key)
    for entry in rss:
        candidates = {
            by_url[url] for url in links.get(entry.key, set()) if url in by_url
        }
        if not candidates:
            candidates = set(by_title.get(normalized_subject(entry.official_title), []))
        if len(candidates) == 1:
            target = records[next(iter(candidates))]
            target.description = entry.description
            target.description_source_url = entry.source_url
            target.aliases.add(entry.source_url)
            # Dossier events are authoritative for status and publication dates.
        else:
            records[entry.key] = entry


def category_for(title: str, description: str) -> str:
    text = normalized_subject(title + " " + description)
    themes = [
        ("Éducation", ("etudiant", "ecole", "enseignement", "education", "universite")),
        ("Santé", ("sante", "malade", "ivg", "fin de vie")),
        ("Écologie", ("climat", "environnement", "ecologie")),
        (
            "Numérique",
            ("numerique", "reseaux", "internet", "intelligence artificielle"),
        ),
        ("Logement", ("logement", "loyer")),
        ("Travail", ("emploi", "travail", "chomage")),
        ("Économie", ("finances", "budget", "fiscal", "securite sociale")),
        ("Intérieur", ("securite", "justice", "police")),
        ("Transports", ("transport", "permis")),
    ]
    for category, keywords in themes:
        if any(re.search(r"\b" + word + r"\b", text) for word in keywords):
            return category
    return "Législation"
