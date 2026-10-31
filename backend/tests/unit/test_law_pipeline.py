import asyncio
from datetime import datetime, timezone
import io
import json
import zipfile
import pytest
from sqlmodel import select
from app.modules.law.text import clean_law_title, plain_text, normalized_subject
from app.modules.law.sources import (
    parse_rss,
    parse_dossiers,
    parse_scrutins,
    merge_rss,
    LawRecord,
)
from app.modules.law.assembly_votes import assembly_vote_result
from app.modules.law.scraper import persist_records
from app.modules.law.model import Law, LawScrutin


def zipped(documents):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w") as archive:
        for path, document in documents.items():
            archive.writestr(path, json.dumps(document))
    return buffer.getvalue()


@pytest.mark.parametrize(
    "raw,expected",
    [
        (
            "Projet de loi relatif au logement étudiant",
            "Êtes-vous favorable au logement étudiant ?",
        ),
        (
            "Projet de loi relatif aux transports publics",
            "Êtes-vous favorable aux transports publics ?",
        ),
        (
            "Projet de loi portant sur le logement étudiant",
            "Êtes-vous favorable au logement étudiant ?",
        ),
        (
            "Proposition de loi visant à protéger et accompagner les étudiants",
            "Êtes-vous favorable à une loi visant à protéger et accompagner les étudiants ?",
        ),
        (
            "l'ensemble de la proposition de loi visant à protéger les étudiants (première lecture).",
            "Êtes-vous favorable à une loi visant à protéger les étudiants ?",
        ),
        (
            "l'ensemble du projet de loi de financement de la sécurité sociale (texte n° 23).",
            "Êtes-vous favorable à une loi de financement de la sécurité sociale ?",
        ),
        ("", "Êtes-vous favorable à ce texte ?"),
    ],
)
def test_questions_are_grammatical_stable_and_faithful(raw, expected):
    assert clean_law_title(raw) == expected
    assert clean_law_title(expected) == expected


def test_description_keeps_paragraphs_decodes_entities_and_removes_tracking():
    assert (
        plain_text(
            "<p>L’école&nbsp;&amp; les jeunes</p><p>Deuxième paragraphe.</p>\nLien de suivi : https://example.com"
        )
        == "L’école & les jeunes\n\nDeuxième paragraphe."
    )


def test_rss_identity_ignores_tracking_and_never_invents_a_date():
    rss = b"""<rss xmlns:dc="http://purl.org/dc/elements/1.1/"><channel><item>
    <title>Projet de loi relatif au logement</title><link>https://www.vie-publique.fr/loi/123-test?egn=1</link>
    <dc:identifier>123</dc:identifier><dc:description>Un resume</dc:description><pubDate>Tue, 06 Oct 2026 00:00:00 +0200</pubDate>
    </item></channel></rss>"""
    record = parse_rss(rss)[0]
    assert record.key == "vp:123"
    assert record.source_url == "https://www.vie-publique.fr/loi/123-test"
    assert record.vote_date is None
    assert record.status == "pending"


def test_matching_never_assigns_opposite_measure_description():
    record = LawRecord(
        "an:1",
        "Proposition de loi visant à interdire le logement étudiant",
        "https://an.fr",
        "assemblee",
    )
    rss = LawRecord(
        "vp:1",
        "Proposition de loi visant à garantir le logement étudiant",
        "https://vp.fr",
        "vie_publique",
        description="Description différente",
    )
    records = {record.key: record}
    merge_rss(records, [rss], {})
    assert record.description == ""
    assert len(records) == 2


def test_official_reference_groups_readings_and_retains_promulgation():
    dossier = {
        "@xsi:type": "DossierLegislatif_Type",
        "uid": "DL1",
        "titreDossier": {
            "titre": "Projet de loi relatif au logement",
            "titreChemin": "logement",
        },
        "actesLegislatifs": {
            "acteLegislatif": [
                {"dateActe": "2026-10-01", "voteRefs": {"voteRef": ["VT1", "VT2"]}},
                {
                    "@xsi:type": "Promulgation_Type",
                    "dateActe": "2026-10-04T00:00:00+02:00",
                },
            ]
        },
    }
    records, references = parse_dossiers(
        zipped({"json/dossierParlementaire/a.json": {"dossierParlementaire": dossier}}),
        17,
    )
    docs = {
        f"json/{uid}.json": {
            "scrutin": {
                "uid": uid,
                "numero": str(number),
                "titre": "l'ensemble du projet de loi relatif au logement (première lecture)",
                "dateScrutin": date,
                "sort": {"code": "adopté"},
            }
        }
        for uid, number, date in [("VT1", 1, "2026-10-01"), ("VT2", 2, "2026-10-03")]
    }
    parse_scrutins(zipped(docs), records, references, 17)
    assert len(records) == 1
    record = records["an:DL1"]
    assert record.status == "promulgated"
    assert len(record.scrutins) == 2
    assert record.vote_date.day == 3
    assert record.published_at.day == 4


def test_counts_preserve_official_abstentions_and_non_voters():
    scrutin = {
        "sort": {"code": "adopté"},
        "syntheseVote": {
            "nombreVotants": "3",
            "decompte": {"pour": "1", "contre": "1", "abstentions": "1"},
        },
        "ventilationVotes": {
            "organe": {
                "groupes": {
                    "groupe": {
                        "organeRef": "G",
                        "nombreMembresGroupe": "4",
                        "vote": {
                            "decompteVoix": {
                                "pour": "1",
                                "contre": "1",
                                "abstentions": "1",
                            },
                            "decompteNominatif": {
                                "pours": {"votant": {"acteurRef": "A"}},
                                "contres": {"votant": {"acteurRef": "B"}},
                                "abstentions": {"votant": {"acteurRef": "C"}},
                                "nonVotants": {"votant": {"acteurRef": "D"}},
                            },
                        },
                    }
                }
            }
        },
    }
    result = assembly_vote_result(
        scrutin,
        {"G": {"abbreviation": "SOC", "name": "Socialistes", "color": "#ff0000"}},
    )
    assert result["summary"]["votants"] == 3
    assert result["summary"]["abstentions"] == 1
    assert result["summary"]["nonVotants"] == 574
    assert len(result["votes"]) == 577


def test_upsert_updates_existing_text_without_duplicate_or_false_date(session):
    now = datetime(2026, 10, 6, tzinfo=timezone.utc)
    record = LawRecord(
        "vp:123",
        "Projet de loi relatif au logement étudiant",
        "https://www.vie-publique.fr/loi/123",
        "vie_publique",
        description="Résumé",
        activity_at=now,
    )
    first = persist_records(session, {record.key: record}, now)
    session.commit()
    record.description = "Résumé actualisé"
    second = persist_records(session, {record.key: record}, now)
    session.commit()
    laws = session.exec(select(Law)).all()
    assert first["created"] == 1 and second["created"] == 0
    assert len(laws) == 1 and laws[0].description == "Résumé actualisé"
    assert laws[0].vote_date is None
    assert laws[0].official_title == record.official_title


def test_startup_refresh_is_shared_and_client_cancellation_does_not_cancel_job(
    monkeypatch,
):
    from app.modules.law import scraper

    monkeypatch.setattr(scraper.settings, "LAW_SYNC_ENABLED", True)
    calls = []
    import time

    def sync(force):
        calls.append(force)
        time.sleep(0.02)
        return {"status": "ok"}

    monkeypatch.setattr(scraper, "_sync_once", sync)
    monkeypatch.setattr(scraper, "_task", None)

    async def run():
        first = asyncio.create_task(scraper.synchronize_laws())
        second = asyncio.create_task(scraper.synchronize_laws())
        await asyncio.sleep(0.005)
        first.cancel()
        with pytest.raises(asyncio.CancelledError):
            await first
        assert await second == {"status": "ok"}

    asyncio.run(run())
    assert len(calls) == 1


def test_repeated_upsert_does_not_change_editorial_timestamp(session):
    now = datetime(2026, 10, 6, tzinfo=timezone.utc)
    record = LawRecord(
        "vp:1",
        "Projet de loi relatif au logement",
        "https://www.vie-publique.fr/loi/1",
        "vie_publique",
        description="Résumé",
        activity_at=now,
    )
    persist_records(session, {record.key: record}, now)
    session.commit()
    law = session.exec(select(Law)).one()
    stamp = law.updated_at
    later = datetime(2026, 10, 7, tzinfo=timezone.utc)
    result = persist_records(session, {record.key: record}, later)
    session.commit()
    assert result["created"] == result["updated"] == 0
    assert law.updated_at == stamp


def test_source_failure_preserves_official_status_and_vote_identity(
    session, monkeypatch
):
    from app.modules.law import scraper

    now = datetime.now(timezone.utc)
    record = LawRecord(
        "an:1",
        "Projet de loi relatif au logement",
        "https://www.assemblee-nationale.fr/dyn/17/dossiers/1",
        "assemblee",
        status="adopted",
        description="Ancien résumé",
        activity_at=now,
        aliases={"https://www.vie-publique.fr/loi/1"},
    )
    record.scrutins = [
        {"uid": "VTANR5L17V1", "numero": "1", "dateScrutin": "2026-10-01"}
    ]
    record.vote_date = now
    persist_records(session, {record.key: record}, now)
    session.commit()
    rss = b"<rss><channel><item><title>Projet de loi relatif au logement</title><link>https://www.vie-publique.fr/loi/1</link><description>Resume actualise</description></item></channel></rss>"

    def download(name, url, state):
        if name == "rss":
            return rss, {}
        raise RuntimeError("source down")

    monkeypatch.setattr(scraper, "engine", session.get_bind())
    monkeypatch.setattr(scraper, "_download", download)
    monkeypatch.setattr(scraper, "_rss_links", lambda entry: (entry.key, set()))
    result = scraper._sync_once(True)
    session.expire_all()
    law = session.exec(select(Law)).one()
    assert result["status"] == "partial"
    assert law.status == "adopted" and law.scrutin_id == "VTANR5L17V1"
    assert law.description == "Resume actualise"
    assert law.source_key == "an:1"
    assert len(session.exec(select(LawScrutin)).all()) == 1


def test_conditional_download_reuses_valid_snapshot(monkeypatch, tmp_path):
    from app.modules.law import scraper
    import httpx

    monkeypatch.setattr(scraper.settings, "LAW_SOURCE_CACHE_DIR", str(tmp_path))
    snapshot = b"<rss><channel><item><title>Loi du 1 octobre 2026</title><link>https://www.vie-publique.fr/loi/1</link></item></channel></rss>"
    (tmp_path / "17-rss").write_bytes(snapshot)
    real_client = httpx.Client

    def respond(request):
        assert request.headers["if-none-match"] == "v1"
        return httpx.Response(304)

    monkeypatch.setattr(
        scraper.httpx,
        "Client",
        lambda **kwargs: real_client(transport=httpx.MockTransport(respond), **kwargs),
    )
    content, headers = scraper._download(
        "rss",
        "https://www.vie-publique.fr/lois-feeds.xml",
        {"etag": "v1", "content_hash": scraper.hashlib.sha256(snapshot).hexdigest()},
    )
    assert content == snapshot and headers["etag"] == "v1"


def test_uncommitted_disk_snapshot_is_reprocessed_after_interruption(
    monkeypatch, tmp_path
):
    from app.modules.law import scraper
    import httpx

    monkeypatch.setattr(scraper.settings, "LAW_SOURCE_CACHE_DIR", str(tmp_path))
    snapshot = b"<rss><channel><item><title>Loi du 1 octobre 2026</title><link>https://www.vie-publique.fr/loi/1</link></item></channel></rss>"
    (tmp_path / "17-rss").write_bytes(snapshot)
    real_client = httpx.Client

    def respond(request):
        assert "if-none-match" not in request.headers
        assert "if-modified-since" not in request.headers
        return httpx.Response(200, content=snapshot, headers={"etag": "v2"})

    monkeypatch.setattr(
        scraper.httpx,
        "Client",
        lambda **kwargs: real_client(transport=httpx.MockTransport(respond), **kwargs),
    )
    content, metadata = scraper._download(
        "rss",
        "https://www.vie-publique.fr/lois-feeds.xml",
        {
            "etag": "v1",
            "modified": "old",
            "content_hash": "previous-committed-snapshot",
        },
    )
    assert content == snapshot
    assert metadata["not_modified"] is False
    assert metadata["content_hash"] == scraper.hashlib.sha256(snapshot).hexdigest()


def test_invalid_download_never_overwrites_good_cache(monkeypatch, tmp_path):
    from app.modules.law import scraper
    import httpx

    monkeypatch.setattr(scraper.settings, "LAW_SOURCE_CACHE_DIR", str(tmp_path))
    monkeypatch.setattr(scraper.time, "sleep", lambda _: None)
    path = tmp_path / "17-rss"
    path.write_bytes(b"previous valid snapshot")
    real_client = httpx.Client
    monkeypatch.setattr(
        scraper.httpx,
        "Client",
        lambda **kwargs: real_client(
            transport=httpx.MockTransport(
                lambda _: httpx.Response(200, text="<html>no feed</html>")
            ),
            **kwargs,
        ),
    )
    with pytest.raises(RuntimeError):
        scraper._download("rss", "https://www.vie-publique.fr/lois-feeds.xml", {})
    assert path.read_bytes() == b"previous valid snapshot"


def test_dossier_links_merge_rss_and_retain_identity_redirects(session, test_user):
    now = datetime(2026, 10, 6, tzinfo=timezone.utc)
    rss = LawRecord(
        "vp:1",
        "Projet de loi relatif au logement",
        "https://www.vie-publique.fr/loi/1",
        "vie_publique",
        description="Résumé",
        activity_at=now,
        aliases={"https://www.vie-publique.fr/loi/1"},
    )
    persist_records(session, {rss.key: rss}, now)
    session.commit()
    rss_id = session.exec(select(Law)).one().id
    from app.modules.law.services import save_citizen_vote, read_citizen_vote

    save_citizen_vote(session, rss_id, test_user.id, "pour")
    dossier = LawRecord(
        "an:1",
        "Réforme du logement",
        "https://www.assemblee-nationale.fr/dyn/17/dossiers/1",
        "assemblee",
        activity_at=now,
        aliases={"https://www.assemblee-nationale.fr/dyn/17/dossiers/1"},
    )
    persist_records(session, {dossier.key: dossier}, now)
    session.commit()
    # An exact official link, not a fuzzy word match, establishes the identity.
    merge_rss({dossier.key: dossier}, [rss], {rss.key: dossier.aliases})
    persist_records(session, {dossier.key: dossier}, now)
    session.commit()
    session.expire_all()
    from app.modules.law.services import read_law

    old = session.get(Law, rss_id)
    assert old.merged_into_id is not None and not old.is_active
    assert read_law(session, rss_id).source_key == "an:1"
    assert read_citizen_vote(session, rss_id, test_user.id)["position"] == "pour"
    assert len(session.exec(select(Law).where(Law.is_active == True)).all()) == 1


def test_group_counts_without_nominal_votes_still_render_truthful_positions():
    scrutin = {
        "syntheseVote": {
            "nombreVotants": "3",
            "decompte": {"pour": "2", "contre": "0", "abstentions": "1"},
        },
        "ventilationVotes": {
            "organe": {
                "groupes": {
                    "groupe": {
                        "organeRef": "G",
                        "nombreMembresGroupe": "5",
                        "vote": {
                            "decompteVoix": {
                                "pour": "2",
                                "contre": "0",
                                "abstentions": "1",
                            },
                            "decompteNominatif": None,
                        },
                    }
                }
            }
        },
    }
    result = assembly_vote_result(
        scrutin,
        {"G": {"abbreviation": "SOC", "name": "Socialistes", "color": "#ff0000"}},
    )
    assert sum(v["position"] == "pour" for v in result["votes"]) == 2
    assert sum(v["position"] == "abstention" for v in result["votes"]) == 1
    assert result["summary"]["nonVotants"] == 574


def test_client_waits_for_another_worker_snapshot(monkeypatch):
    from app.modules.law import scraper

    calls = []

    def sync(force):
        calls.append(force)
        return {"status": "busy"} if len(calls) == 1 else {"status": "cached"}

    monkeypatch.setattr(scraper, "_sync_once", sync)
    assert asyncio.run(scraper._coordinated_sync(False)) == {"status": "cached"}
    assert calls == [False, False]


def test_administrative_hiding_survives_source_refresh(session):
    now = datetime(2026, 10, 6, tzinfo=timezone.utc)
    record = LawRecord(
        "vp:1",
        "Projet de loi relatif au logement",
        "https://www.vie-publique.fr/loi/1",
        "vie_publique",
        activity_at=now,
    )
    persist_records(session, {record.key: record}, now)
    session.commit()
    from app.modules.law.services import delete_law

    law = session.exec(select(Law)).one()
    delete_law(session, law.id)
    persist_records(session, {record.key: record}, now)
    session.commit()
    assert law.hidden_by_admin and not law.is_active


def test_unchanged_sources_skip_reprocessing_but_are_revalidated(session, monkeypatch):
    from app.modules.law import scraper
    from app.modules.law.model import LawSyncState

    state = LawSyncState(
        source="sync",
        last_success_at=datetime(2026, 1, 1),
        last_attempt_at=datetime(2026, 1, 1),
        etag=scraper.PROCESSOR_VERSION,
    )
    session.add(state)
    session.commit()
    calls = []

    def download(name, url, state):
        calls.append(name)
        return b"already validated cache", {"not_modified": True}

    monkeypatch.setattr(scraper, "engine", session.get_bind())
    monkeypatch.setattr(scraper, "_download", download)
    monkeypatch.setattr(
        scraper,
        "parse_dossiers",
        lambda *args: pytest.fail("Unchanged sources must not be parsed again"),
    )
    result = scraper._sync_once(False)
    assert result["status"] == "ok" and result["not_modified"]
    assert len(calls) == 4


def test_unlinked_subject_identity_is_namespaced_by_legislature():
    document = zipped(
        {
            "json/a.json": {
                "scrutin": {
                    "uid": "VT1",
                    "numero": "1",
                    "titre": "l'ensemble du projet de loi relatif au logement",
                    "dateScrutin": "2026-10-01",
                }
            }
        }
    )
    first, second = {}, {}
    parse_scrutins(document, first, {}, 17)
    parse_scrutins(document, second, {}, 18)
    assert set(first).isdisjoint(second)


def test_technical_legacy_description_is_not_kept_as_an_explanation(session):
    now = datetime(2026, 10, 6, tzinfo=timezone.utc)
    record = LawRecord(
        "vp:1",
        "Projet de loi relatif au logement",
        "https://www.vie-publique.fr/loi/1",
        "vie_publique",
        activity_at=now,
    )
    persist_records(session, {record.key: record}, now)
    session.commit()
    law = session.exec(select(Law)).one()
    law.description = "Le texte original est intitulé : 'un titre'. Vote effectué..."
    session.add(law)
    session.commit()
    persist_records(session, {record.key: record}, now)
    session.commit()
    assert "résumé pédagogique" in law.description
    assert not law.description.startswith("Le texte original")


def test_double_encoded_html_is_plain_text():
    assert plain_text("&amp;lt;p&amp;gt;Texte&amp;lt;/p&amp;gt;") == "Texte"
