import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/political_party.dart';
import 'package:mobile/models/political_portraits.dart';
import 'package:mobile/repositories/political_repository.dart';
import 'package:mobile/theme/political_identity.dart';

void main() {
  final raw = File(
    'assets/data/political_parties_2027.json',
  ).readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final catalog = PoliticalCatalog.fromJson(json);

  test(
    'catalogue : chaque affirmation renvoie à une source datée avec URL HTTPS',
    () {
      expect(catalog.parties.length, greaterThanOrEqualTo(20));
      expect(
        catalog.parties.map((p) => p.id).toSet().length,
        catalog.parties.length,
      );
      final cutoff = DateTime.parse(catalog.checkedAt);
      for (final party in catalog.parties) {
        final ids = party.sources.map((s) => s.id).toSet();
        expect(ids.length, party.sources.length, reason: party.id);
        final assertions = [
          ...party.leadership.map((p) => p.sourceIds),
          party.election2027.sourceIds,
          ...party.election2027.people.map((p) => p.sourceIds),
          ...party.proposals.map((p) => p.sourceIds),
        ];
        for (final references in assertions) {
          expect(references, isNotEmpty, reason: party.id);
          expect(
            ids.containsAll(references),
            isTrue,
            reason: '${party.id}: $references',
          );
        }
        for (final proposal in party.proposals) {
          expect(proposal.context, isNotEmpty);
          expect(proposal.detail, isNotEmpty);
        }
        for (final source in party.sources) {
          final uri = Uri.parse(source.url);
          expect(uri.scheme, 'https');
          expect(uri.host, isNotEmpty);
          expect(source.checkedAt, catalog.checkedAt);
          if (source.publishedAt != null) {
            expect(
              DateTime.parse(source.publishedAt!).isAfter(cutoff),
              isFalse,
              reason: source.url,
            );
          }
        }
      }
    },
  );

  test(
    'dirigeant, candidat, soutien et candidature retirée restent distincts',
    () {
      final byId = {for (final p in catalog.parties) p.id: p};
      expect(byId['lfi']!.leadership.first.name, 'Manuel Bompard');
      expect(byId['lfi']!.election2027.people.first.name, 'Jean-Luc Mélenchon');
      expect(
        byId['ps']!.leadership.map((p) => p.name),
        isNot(contains('Karim Bouamrane')),
      );
      expect(byId['horizons']!.leadership.first.name, 'Christophe Béchu');
      expect(byId['modem']!.election2027.isDeclared, isFalse);
      expect(byId['npa-anticapitaliste']!.election2027.status, 'support');
      expect(byId['apres']!.election2027.status, 'withdrawn');
    },
  );

  test('tri neutre, recherche insensible aux accents et personnes', () {
    final names = catalog.parties
        .map((p) => normalizePoliticalSearch(p.name))
        .toList();
    expect(names, orderedEquals([...names]..sort()));
    expect(
      catalog.parties.singleWhere((p) => p.id == 'lfi').matches('MELENCHON'),
      isTrue,
    );
    expect(
      catalog.parties
          .singleWhere((p) => p.id == 'ecologistes')
          .matches('ecologistes'),
      isTrue,
    );
  });

  test(
    'tous les partis ont un repère et les portraits libres sont traçables',
    () {
      final names = {
        for (final party in catalog.parties)
          ...party.leadership.map((person) => person.name),
        for (final party in catalog.parties)
          ...party.election2027.people.map((person) => person.name),
      };
      expect(politicalIdentities.keys.toSet(), {
        for (final party in catalog.parties) party.id,
      });
      expect(
        politicalPortraits.keys.toSet(),
        names.difference({'Selma Labib'}),
      );
      for (final portrait in politicalPortraits.values) {
        expect(
          File(portrait.asset).existsSync(),
          isTrue,
          reason: portrait.asset,
        );
        expect(Uri.parse(portrait.sourceUrl).host, 'commons.wikimedia.org');
        expect(portrait.author, isNotEmpty);
        expect(portrait.license, isNotEmpty);
        if (portrait.license != 'CC0' && portrait.license != 'Public domain') {
          expect(Uri.parse(portrait.licenseUrl).scheme, 'https');
        }
      }
    },
  );

  test('version inconnue refusée', () {
    expect(
      () => PoliticalCatalog.fromJson({...json, 'schemaVersion': 999}),
      throwsFormatException,
    );
  });

  test('lecture paresseuse mutualisée et réutilisée sans réseau', () async {
    var reads = 0;
    final repository = PoliticalRepository(
      loadAsset: () async {
        reads++;
        return raw;
      },
    );
    expect(reads, 0);
    final first = repository.load();
    expect(identical(first, repository.load()), isTrue);
    await first;
    await repository.load();
    expect(reads, 1);
  });

  test('une erreur de lecture peut être réessayée', () async {
    var reads = 0;
    final repository = PoliticalRepository(
      loadAsset: () async {
        reads++;
        if (reads == 1) throw const FormatException('unreadable');
        return raw;
      },
    );
    await expectLater(repository.load(), throwsFormatException);
    expect((await repository.load()).parties, isNotEmpty);
    expect(reads, 2);
  });
}
