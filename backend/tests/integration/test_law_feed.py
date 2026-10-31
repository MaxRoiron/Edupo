from datetime import datetime
from sqlmodel import select
from app.modules import Country, Domain, Law
from app.modules.user_vote.model import UserVote


def law_fixture(session, status="pending", active=True):
    country = Country(name="France", iso_code="FR")
    domain = Domain(name="Général")
    session.add(country)
    session.add(domain)
    session.commit()
    law = Law(
        title="Êtes-vous favorable au logement étudiant ?",
        description="Résumé",
        country_id=country.id,
        domain_id=domain.id,
        status=status,
        is_active=active,
        source_key="vp:1",
        activity_at=datetime(2026, 10, 6),
    )
    session.add(law)
    session.commit()
    session.refresh(law)
    return law


def test_pending_feed_does_not_depend_on_a_date_and_hides_archives(client, session):
    law = law_fixture(session)
    assert client.get("/law?group=pending").json()[0]["id"] == law.id
    assert client.get("/law?group=voted").json() == []
    law.is_active = False
    session.add(law)
    session.commit()
    assert client.get("/law").json() == []


def test_search_and_pagination_validation(client, session):
    law_fixture(session)
    assert len(client.get("/law?q=logement&limit=1").json()) == 1
    assert client.get("/law?q=absent").json() == []
    assert client.get("/law?offset=1").json() == []
    assert client.get("/law?limit=201").status_code == 422
    assert client.get("/law?q=%25").json() == []


def test_vote_requires_login_persists_and_updates_without_duplicate(
    client, auth_user, session, test_user
):
    law = law_fixture(session)
    client.headers.clear()
    assert (
        client.put(f"/law/{law.id}/my-vote", json={"position": "pour"}).status_code
        == 401
    )
    from app.core import create_access_token

    client.headers["Authorization"] = "Bearer " + create_access_token(
        {"user_id": test_user.id}
    )
    assert (
        client.put(f"/law/{law.id}/my-vote", json={"position": "pour"}).json()[
            "position"
        ]
        == "pour"
    )
    assert (
        client.put(f"/law/{law.id}/my-vote", json={"position": "contre"}).json()[
            "position"
        ]
        == "contre"
    )
    assert client.get(f"/law/{law.id}/my-vote").json()["position"] == "contre"
    assert len(session.exec(select(UserVote)).all()) == 1
    assert (
        client.put(f"/law/{law.id}/my-vote", json={"position": "invalid"}).status_code
        == 422
    )
    law.status = "adopted"
    session.add(law)
    session.commit()
    assert (
        client.put(f"/law/{law.id}/my-vote", json={"position": "pour"}).status_code
        == 409
    )


def test_admin_resync_requires_admin(client, auth_user, test_user):
    client.headers.clear()
    assert client.post("/admin/law/resync-voted").status_code == 401
    from app.core import create_access_token

    client.headers["Authorization"] = "Bearer " + create_access_token(
        {"user_id": test_user.id}
    )
    assert client.post("/admin/law/resync-voted").status_code == 403
    # Invalid official vote IDs are a 404, never a synthetic result.
    assert client.get("/law/assembly_votes/not-a-real-uid").status_code == 404


def test_account_deletion_removes_citizen_votes(auth_user, session):
    law = law_fixture(session)
    assert (
        auth_user.put(f"/law/{law.id}/my-vote", json={"position": "pour"}).status_code
        == 200
    )
    assert auth_user.delete("/me").status_code == 200
    assert session.exec(select(UserVote)).all() == []


def test_unverified_archive_is_not_publicly_readable(client, session):
    law = law_fixture(session, active=False)
    law.source = 'legacy'; session.add(law); session.commit()
    assert client.get(f'/law/{law.id}').status_code == 404
