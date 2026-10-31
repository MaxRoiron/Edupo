import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/account_edit_screen.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/screens/register_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/law_feed_controller.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/widgets/civic_components.dart';
import 'package:mobile/widgets/law_card.dart';
import 'support/design_fixtures.dart';

void main() {
  late DesignFixtures fixture;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'test-session'});
    LawFeedCache.instance.clear();
    fixture = DesignFixtures();
    ApiService.setHttpClient(fixture.client);
  });
  Future<void> show(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(CivicButton, label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> edit(
    WidgetTester tester,
    AccountSection section, {
    bool exists = true,
  }) => show(
    tester,
    AccountEditScreen(
      section: section,
      values: {...fixture.user, ...fixture.personal},
      hasPersonalData: exists,
      professions: DesignFixtures.professions,
      genders: DesignFixtures.genders,
    ),
  );

  testWidgets('Visitor sees sign-in actions without protected API requests', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await show(tester, const ProfileScreen(embedded: true));
    expect(find.text('Vos idées ont\nleur place ici.'), findsOneWidget);
    expect(find.widgetWithText(CivicButton, 'Se connecter'), findsOneWidget);
    expect(fixture.requests, isEmpty);
  });
  testWidgets('Expired non-JSON session returns to the visitor view', (
    tester,
  ) async {
    fixture = DesignFixtures(scenario: 'expired');
    ApiService.setHttpClient(fixture.client);
    await show(tester, const ProfileScreen(embedded: true));
    expect(await AuthService.getToken(), isNull);
    expect(find.text('Vos idées ont\nleur place ici.'), findsOneWidget);
    expect(find.text('Camille.'), findsNothing);
  });
  testWidgets('Sign-in rejection retains entered values and allows retry', (
    tester,
  ) async {
    fixture = DesignFixtures(scenario: 'auth-error');
    ApiService.setHttpClient(fixture.client);
    await show(tester, const LoginScreen());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'camille@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret-pass');
    await tapButton(tester, 'Se connecter');
    expect(
      find.text('Adresse e-mail ou mot de passe incorrect.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'camille@example.test',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller!
          .text,
      'secret-pass',
    );
    expect(fixture.requests.where((r) => r.url.path == '/login').length, 1);
  });
  testWidgets(
    'Sign-in refreshes an embedded visitor account after navigation',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await show(tester, const ProfileScreen(embedded: true));
      await tapButton(tester, 'Se connecter');
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'camille@example.test',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'secret-pass');
      await tapButton(tester, 'Se connecter');
      expect(await AuthService.getToken(), 'local-design-session');
      expect(find.text('Camille.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('Registration validates confirmation before any request', (
    tester,
  ) async {
    await show(tester, const RegisterScreen());
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Camille');
    await tester.enterText(fields.at(1), 'camille@example.test');
    await tester.enterText(fields.at(2), 'secret-pass');
    await tester.enterText(fields.at(3), 'different');
    await tapButton(tester, 'Créer mon compte');
    expect(
      find.text('Les mots de passe ne correspondent pas.'),
      findsOneWidget,
    );
    expect(fixture.requests, isEmpty);
  });
  testWidgets('Failed personal save stays open and preserves unrelated data', (
    tester,
  ) async {
    fixture = DesignFixtures(scenario: 'save-error');
    ApiService.setHttpClient(fixture.client);
    await edit(tester, AccountSection.personal);
    await tester.enterText(find.byType(TextFormField).first, '29');
    await tapButton(tester, 'Enregistrer les modifications');
    expect(find.byType(AccountEditScreen), findsOneWidget);
    expect(
      find.text('Impossible de terminer cette action. Réessayez.'),
      findsOneWidget,
    );
    final request = fixture.requests.single;
    expect(request.method, 'PATCH');
    final payload = jsonDecode(request.body) as Map;
    expect(payload['age'], 29);
    expect(payload['professional_status_id'], 1);
    expect(payload.containsKey('social_status_id'), isFalse);
    expect(payload.containsKey('user_id'), isFalse);
    expect(find.text('Informations enregistrées.'), findsNothing);
  });
  testWidgets('Missing personal record is created with POST', (tester) async {
    await edit(tester, AccountSection.personal, exists: false);
    await tapButton(tester, 'Enregistrer les modifications');
    expect(fixture.requests.single.method, 'POST');
    expect(fixture.requests.single.url.path, '/me/data');
  });

  testWidgets('A concurrent personal record does not report an e-mail conflict', (
    tester,
  ) async {
    fixture = DesignFixtures(scenario: 'save-conflict');
    ApiService.setHttpClient(fixture.client);
    await edit(tester, AccountSection.personal, exists: false);
    await tapButton(tester, 'Enregistrer les modifications');
    expect(
      find.text(
        'Ces informations existent déjà. Actualisez votre profil avant de réessayer.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cette adresse e-mail est déjà utilisée.'), findsNothing);
    expect(find.byType(AccountEditScreen), findsOneWidget);
  });
  testWidgets('Cancelling edit never writes to the API', (tester) async {
    await edit(tester, AccountSection.identity);
    await tester.enterText(find.byType(TextFormField).first, 'Changed');
    await tester.ensureVisible(find.text('Annuler'));
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(fixture.requests, isEmpty);
  });
  testWidgets(
    'Partial profile retains identity without inventing personal values',
    (tester) async {
      fixture = DesignFixtures(scenario: 'partial');
      ApiService.setHttpClient(fixture.client);
      await show(tester, const ProfileScreen(embedded: true));
      expect(find.text('Camille.'), findsOneWidget);
      expect(
        find.text(
          'Certaines informations ne sont pas disponibles pour le moment.',
        ),
        findsOneWidget,
      );
      expect(find.text('Non renseigné'), findsNothing);
      expect(find.text('Réessayer'), findsOneWidget);
    },
  );
  testWidgets('Logout clears private information in the account tab', (
    tester,
  ) async {
    await show(tester, const ProfileScreen(embedded: true));
    await tapButton(tester, 'Se déconnecter');
    await tester.tap(find.widgetWithText(TextButton, 'Se déconnecter'));
    await tester.pumpAndSettle();
    expect(await AuthService.getToken(), isNull);
    expect(find.text('camille@example.test'), findsNothing);
    expect(find.text('Camille.'), findsNothing);
    expect(find.text('Vos idées ont\nleur place ici.'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Mobile layout fits 320px at ${scale * 100}% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final page in <Widget>[
        const EdupoApp(),
        const LoginScreen(),
        const RegisterScreen(),
        const ProfileScreen(embedded: true),
        AccountEditScreen(
          section: AccountSection.personal,
          values: fixture.personal,
          professions: DesignFixtures.professions,
          genders: DesignFixtures.genders,
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: page,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$page at scale $scale');
        final scrolls = find.byType(Scrollable).hitTestable();
        if (scrolls.evaluate().isNotEmpty) {
          await tester.drag(scrolls.first, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$page after scrolling at scale $scale',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
  testWidgets('Reduced motion removes press scaling and route duration', (
    tester,
  ) async {
    late BuildContext localContext;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              localContext = context;
              return Material(
                child: CivicButton(label: 'Test', onPressed: () {}),
              );
            },
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Test')),
    );
    await tester.pump();
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1);
    expect(scale.duration, Duration.zero);
    final route = CivicPageRoute<void>(
      context: localContext,
      builder: (_) => const SizedBox(),
    );
    expect(route.transitionDuration, Duration.zero);
    route.dispose();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Successful identity edit confirms and reloads the profile', (
    tester,
  ) async {
    await show(tester, const ProfileScreen(embedded: true));
    await tester.tap(find.byTooltip('Modifier le compte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Alex');
    await tapButton(tester, 'Enregistrer les modifications');
    expect(find.text('Alex.'), findsOneWidget);
    expect(find.text('Informations enregistrées.'), findsOneWidget);
    final request = fixture.requests.firstWhere((r) => r.method == 'PATCH');
    expect(jsonDecode(request.body), {
      'username': 'Alex',
      'email': 'camille@example.test',
    });
    expect(find.byType(AccountEditScreen), findsNothing);
  });
  testWidgets('Unavailable lists preserve saved reference IDs during an edit', (
    tester,
  ) async {
    await show(
      tester,
      AccountEditScreen(
        section: AccountSection.personal,
        values: fixture.personal,
        hasPersonalData: true,
      ),
    );
    expect(find.text('Valeur enregistrée'), findsWidgets);
    await tapButton(tester, 'Enregistrer les modifications');
    final payload = jsonDecode(fixture.requests.single.body);
    expect(payload['professional_status_id'], 1);
    expect(payload['gender_identity_id'], 2);
  });
  for (final state in ['empty', 'error', 'partial']) {
    testWidgets('Feed $state state fits 320px with 200% text', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      fixture = DesignFixtures(scenario: state);
      ApiService.setHttpClient(fixture.client);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'Changing feed filter returns to the first result with pinned tools',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await show(tester, const HomeScreen());
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1800));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Déjà votées'));
      await tester.pumpAndSettle();
      expect(tester.widget<LawCard>(find.byType(LawCard).first).law.id, '1');
      expect(
        tester.widget<LawCard>(find.byType(LawCard).first).law.isVoted,
        isTrue,
      );
      expect(tester.getTopLeft(find.byType(TextField)).dy, lessThan(150));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
