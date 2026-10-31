import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/political_party.dart';
import 'package:mobile/repositories/political_repository.dart';
import 'package:mobile/screens/programs_screen.dart';
import 'package:mobile/screens/program_detail_screen.dart';
import 'package:mobile/screens/politician_detail_screen.dart';
import 'package:mobile/screens/text_reader_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/political_components.dart';

void main() {
  final raw = File(
    'assets/data/political_parties_2027.json',
  ).readAsStringSync();
  final catalog = PoliticalCatalog.fromJson(jsonDecode(raw));
  final party = catalog.parties.singleWhere((p) => p.id == 'lfi');
  Future<void> show(
    WidgetTester tester,
    Widget page, {
    double width = 390,
    double scale = 1,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
          ),
          child: child!,
        ),
        home: page,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  ProgramsScreen feed() => ProgramsScreen(
    repository: PoliticalRepository(loadAsset: () async => raw),
  );

  testWidgets('recherche, aucun résultat, réinitialisation et vue mesures', (
    tester,
  ) async {
    await show(tester, feed());
    await tester.enterText(find.byType(TextField), 'Mélenchon');
    await tester.pumpAndSettle();
    expect(find.text('La France insoumise'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zz-introuvable');
    await tester.pumpAndSettle();
    expect(find.text('Aucun résultat pour ces critères.'), findsOneWidget);
    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.tap(find.text('Mesures'));
    await tester.enterText(find.byType(TextField), 'Mélenchon');
    await tester.pumpAndSettle();
    expect(find.byType(ProposalCard), findsWidgets);
    await tester.enterText(find.byType(TextField), 'nucléaire');
    await tester.pumpAndSettle();
    expect(find.byType(ProposalCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cartes compactes, couleur et drapeau politique visibles', (
    tester,
  ) async {
    await show(tester, feed());
    final card = find.byKey(const ValueKey('party-card-debout'));
    expect(card, findsOneWidget);
    expect(tester.getSize(card).height, lessThan(250));
    expect(find.text('Gauche'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtre des candidatures, liste paresseuse, recherche épinglée', (
    tester,
  ) async {
    await show(tester, feed());
    expect(
      find.byType(PartyMark).evaluate().length,
      lessThan(catalog.parties.length),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(TextField)).dy, lessThan(40));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), 'Bompard');
    await tester.pumpAndSettle();
    final resultMark = find.byWidgetPredicate(
      (w) => w is PartyMark && w.party.id == 'lfi',
    );
    expect(
      tester.getTopLeft(resultMark).dy,
      greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
    );
    tester.view.resetViewInsets();
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Candidatures déclarées'));
    await tester.tap(find.text('Candidatures déclarées'));
    await tester.enterText(find.byType(TextField), 'MoDem');
    await tester.pumpAndSettle();
    expect(find.text('Aucun résultat pour ces critères.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      greaterThanOrEqualTo(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chargement, erreur et véritable réessai du catalogue', (
    tester,
  ) async {
    final pending = Completer<String>();
    await show(
      tester,
      ProgramsScreen(
        repository: PoliticalRepository(loadAsset: () => pending.future),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    var reads = 0;
    await show(
      tester,
      ProgramsScreen(
        key: const ValueKey('retry'),
        repository: PoliticalRepository(
          loadAsset: () async {
            if (++reads == 1) throw const FormatException('test');
            return raw;
          },
        ),
      ),
    );
    expect(find.text('Le dossier n’a pas pu être chargé.'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('La politique,\nen clair.'), findsOneWidget);
    expect(reads, 2);
  });

  testWidgets('parti → personnes → retour, proposition et sources', (
    tester,
  ) async {
    await show(tester, ProgramDetailScreen(party: party));
    await tester.ensureVisible(find.text('Qui dirige ce parti ?'));
    await tester.tap(find.text('Qui dirige ce parti ?'));
    await tester.pumpAndSettle();
    expect(find.text('Manuel Bompard'), findsOneWidget);
    expect(find.text('La direction du parti'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portrait-image-Manuel Bompard')),
      findsOneWidget,
    );
    await tester.tap(find.text('Crédit photo').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Wikimedia Commons'), findsWidgets);
    await tester.tap(find.byTooltip('Fermer le crédit photo'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(ProposalCard).first, 300);
    await tester.tap(find.byType(ProposalCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(TextReaderScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byWidgetPredicate(
        (w) =>
            w is SourceTile &&
            w.source.id == party.proposals.first.sourceIds.first,
      ),
      450,
      scrollable: find
          .descendant(
            of: find.byType(TextReaderScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('Consulté le'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filtrer les propositions par thème', (tester) async {
    await show(tester, ProgramDetailScreen(party: party));
    final themeChip = find.byWidgetPredicate(
      (w) => w is PoliticalChoiceChip && w.label == 'Retraites',
    );
    await tester.ensureVisible(themeChip);
    await tester.pumpAndSettle();
    await tester.tap(themeChip);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.byType(ProposalCard), findsOneWidget);
    expect(
      tester.widget<ProposalCard>(find.byType(ProposalCard)).proposal.theme,
      'Retraites',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('personne sans portrait réutilisable : état explicite', (
    tester,
  ) async {
    final npa = catalog.parties.singleWhere(
      (party) => party.id == 'npa-revolutionnaires',
    );
    await show(tester, PoliticianDetailScreen(party: npa));
    expect(find.text('Selma Labib'), findsWidgets);
    expect(
      find.text('Portrait indisponible en licence réutilisable.'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  for (final screen in ['feed', 'party', 'people', 'proposal']) {
    testWidgets('$screen : largeur 320, texte 200 %, mouvement réduit', (
      tester,
    ) async {
      final page = switch (screen) {
        'feed' => feed(),
        'party' => ProgramDetailScreen(party: party),
        'people' => PoliticianDetailScreen(party: party),
        _ => TextReaderScreen(party: party, proposal: party.proposals.first),
      };
      await show(tester, page, width: 320, scale: 2, reduced: true);
      for (var i = 0; i < 6; i++) {
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -650));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'contrôles accessibles : libellés, contraste et cibles tactiles',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await show(tester, feed());
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await show(tester, ProgramDetailScreen(party: party));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('échec ouverture de source : lien copiable', (tester) async {
    await show(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openPoliticalSource(context, 'invalid-source'),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Impossible d’ouvrir cette source.'), findsOneWidget);
    expect(find.text('Copier le lien'), findsOneWidget);
  });

  testWidgets('lecture publique, catalogue vide et sources en feuille', (
    tester,
  ) async {
    final empty = jsonDecode(raw) as Map<String, dynamic>;
    empty['parties'] = [];
    await show(
      tester,
      ProgramsScreen(
        repository: PoliticalRepository(
          loadAsset: () async => jsonEncode(empty),
        ),
      ),
    );
    expect(find.text('Le dossier est encore vide.'), findsOneWidget);
    await show(tester, Scaffold(body: SourcesButton(sources: party.sources)));
    await tester.tap(find.byType(SourcesButton));
    await tester.pumpAndSettle();
    expect(find.text('Les sources'), findsOneWidget);
    expect(find.textContaining('Consulté le'), findsWidgets);
    await tester.tap(find.byTooltip('Fermer les sources'));
    await tester.pumpAndSettle();
    expect(find.text('Les sources'), findsNothing);
  });
}
