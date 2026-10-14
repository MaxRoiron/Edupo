"""Official counts and separately rendered non-voting seats."""

from pathlib import Path
import re
from .sources import as_list, zip_documents
from app.core.config import settings

_organes: dict = {}
_stamp: float | None = None
POSITIONS = {
    "GDR": 1,
    "LFI-NFP": 2,
    "EcoS": 3,
    "SOC": 4,
    "LIOT": 5,
    "EPR": 6,
    "Dem": 7,
    "HOR": 8,
    "DR": 9,
    "UDR": 10,
    "RN": 11,
    "NI": 12,
}


def political_groups() -> dict:
    global _organes, _stamp
    path = Path(settings.LAW_SOURCE_CACHE_DIR) / f"{settings.LAW_LEGISLATURE}-organes"
    if not path.exists():
        return {}
    stamp = path.stat().st_mtime
    if stamp != _stamp:
        groups = {}
        for document in zip_documents(path.read_bytes(), "json/organe/"):
            group = document.get("organe") or {}
            if group.get("codeType") == "GP":
                groups[group["uid"]] = {
                    "abbreviation": group.get("libelleAbrege") or "?",
                    "name": group.get("libelle") or "Groupe inconnu",
                    "color": group.get("couleurAssociee") or "#808080",
                }
        _organes, _stamp = groups, stamp
    return _organes


def assembly_vote_result(scrutin: dict, organes: dict) -> dict:
    groups, votes, seen = [], [], set()
    for group in as_list(
        (
            ((scrutin.get("ventilationVotes") or {}).get("organe") or {}).get("groupes")
            or {}
        ).get("groupe")
    ):
        uid = group.get("organeRef")
        info = organes.get(uid, {})
        abbr = info.get("abbreviation", "?")
        color = info.get("color", "#808080")
        if not re.fullmatch(r"#[a-fA-F0-9]{6}", color):
            color = "#808080"
        data = group.get("vote") or {}
        counts = data.get("decompteVoix") or {}
        groups.append(
            {
                "organeRef": uid,
                "abbreviation": abbr,
                "name": info.get("name", "Groupe inconnu"),
                "color": color,
                "politicalPosition": POSITIONS.get(abbr, 50),
                **{
                    key: int(counts.get(key) or 0)
                    for key in ("pour", "contre", "abstentions")
                },
                "nonVotants": int(counts.get("nonVotants") or 0)
                + int(counts.get("nonVotantsVolontaires") or 0),
            }
        )
        nominal = data.get("decompteNominatif") or {}
        for name, position in [
            ("pours", "pour"),
            ("contres", "contre"),
            ("abstentions", "abstention"),
            ("nonVotants", "non_votant"),
            ("nonVotantsVolontaires", "non_votant"),
        ]:
            for person in as_list((nominal.get(name) or {}).get("votant")):
                actor = person.get("acteurRef")
                if not actor or actor in seen:
                    continue
                seen.add(actor)
                votes.append(
                    {
                        "acteurRef": actor,
                        "position": position,
                        "groupe": abbr,
                        "organeRef": uid,
                        "color": color,
                        "politicalPosition": POSITIONS.get(abbr, 50),
                        "seat": person.get("numPlace"),
                    }
                )
        # Some ballots publish group counts without all nominal votes. Render
        # those counts as anonymous seats, never as fake named individual votes.
        for official, position in [
            ("pour", "pour"),
            ("contre", "contre"),
            ("abstentions", "abstention"),
        ]:
            named = sum(
                v.get("organeRef") == uid and v["position"] == position for v in votes
            )
            votes.extend(
                {
                    "acteurRef": "",
                    "position": position,
                    "groupe": abbr,
                    "organeRef": uid,
                    "color": color,
                    "politicalPosition": POSITIONS.get(abbr, 50),
                }
                for _ in range(max(0, int(counts.get(official) or 0) - named))
            )
        # Missing members have not cast an abstention. Retain the group colors.
        missing = max(
            0,
            int(group.get("nombreMembresGroupe") or 0)
            - sum(v.get("organeRef") == uid for v in votes),
        )
        votes.extend(
            {
                "acteurRef": "",
                "position": "non_votant",
                "groupe": abbr,
                "organeRef": uid,
                "color": color,
                "politicalPosition": POSITIONS.get(abbr, 50),
            }
            for _ in range(missing)
        )
    missing = max(0, 577 - len(votes))
    votes.extend(
        {
            "acteurRef": "",
            "position": "non_votant",
            "groupe": "Non renseigné",
            "color": "#C8CCD2",
            "politicalPosition": 99,
        }
        for _ in range(missing)
    )
    synthesis = scrutin.get("syntheseVote") or {}
    counts = synthesis.get("decompte") or {}
    summary = {
        key: int(counts.get(key) or 0) for key in ("pour", "contre", "abstentions")
    }
    official_voters = int(synthesis.get("nombreVotants") or sum(summary.values()))
    summary.update(
        votants=official_voters,
        nonVotants=max(0, len(votes) - official_voters),
        totalSeats=len(votes),
        sort=(scrutin.get("sort") or {}).get("code") or "",
        vote_date=scrutin.get("dateScrutin"),
    )
    return {
        "summary": summary,
        "groups": sorted(groups, key=lambda g: g["politicalPosition"]),
        "votes": sorted(votes, key=lambda v: v["politicalPosition"]),
    }
