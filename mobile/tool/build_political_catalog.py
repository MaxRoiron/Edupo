#!/usr/bin/env python3
"""Assemble reviewed research. Never scrape or invent missing assertions.

Run from any directory: python3 mobile/tool/build_political_catalog.py
Research documents remain the editorial source of truth; review updates before
regenerating the asset and run test/political_catalog_test.dart afterwards.
"""
import datetime as dt
import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[2]
RESEARCH = ROOT / 'docs/research/presidentielle-2027'
OUTPUT = ROOT / 'mobile/assets/data/political_parties_2027.json'
CHECKED_AT = '2026-10-20'


def build():
    inputs = [json.loads((RESEARCH / f'{area}.json').read_text()) for area in ('left', 'center', 'right')]
    parties = [party for group in inputs for party in group['parties']]
    assert len({p['id'] for p in parties}) == len(parties), 'Duplicate party IDs'
    for party in parties:
        ids = {s['id'] for s in party['sources']}
        assert len(ids) == len(party['sources']), f"Duplicate sources: {party['id']}"
        assert party['election2027']['status'] in {'declared', 'selection_pending', 'not_verified', 'conditional', 'support', 'withdrawn'}
        records = [*party['leadership'], party['election2027'], *party['election2027']['people'], *party['proposals']]
        for record in records:
            assert record['sourceIds'] and set(record['sourceIds']) <= ids, f"Missing source: {party['id']} {record}"
        assert len({p['id'] for p in party['proposals']}) == len(party['proposals'])
        for source in party['sources']:
            validate_source(source)
    for candidate in inputs[2].get('additionalCandidates', []):
        ids = {s['id'] for s in candidate['sources']}
        for record in [candidate, *candidate['proposals']]:
            assert record['sourceIds'] and set(record['sourceIds']) <= ids
        for source in candidate['sources']:
            validate_source(source)
    rules = inputs[1]['electionRules']
    for source in rules['sources']:
        validate_source(source)
    catalog = {
        'schemaVersion': 1,
        'checkedAt': CHECKED_AT,
        'scope': 'Panorama documentaire de formations françaises actives dans la préparation de 2027, incluant des candidatures annoncées, des soutiens et des partis sans candidat propre vérifié. Les formations sont classées par ordre alphabétique, sans classement de préférence. Le dossier ne constitue pas la liste officielle ni exhaustive des candidats. Les déclarations et propositions retenues sont vérifiées au 20 octobre 2026 ; les incertitudes sont signalées dans chaque fiche.',
        'electionNotice': 'Candidature annoncée ne signifie pas candidature validée. Le Conseil constitutionnel arrêtera la liste officielle après contrôle des conditions, dont au moins 500 présentations d’élus. Ce dossier ne constitue pas cette liste.',
        'sources': rules['sources'],
        'parties': parties,
        'additionalCandidates': inputs[2].get('additionalCandidates', []),
    }
    OUTPUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
    print(f"{len(parties)} formations, {sum(len(p['proposals']) for p in parties)} propositions, {len({s['url'] for p in parties for s in p['sources']})} sources distinctes")


def validate_source(source):
    parsed = urlparse(source['url'])
    assert parsed.scheme == 'https' and parsed.netloc, source
    assert source['checkedAt'] == CHECKED_AT, source
    if source['publishedAt']:
        assert dt.date.fromisoformat(source['publishedAt']) <= dt.date.fromisoformat(CHECKED_AT), source


if __name__ == '__main__':
    build()
