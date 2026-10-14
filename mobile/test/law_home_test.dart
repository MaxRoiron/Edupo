import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/services/law_feed_controller.dart';
import 'package:mobile/widgets/law_card.dart';
import 'package:mobile/main.dart';

void main() {
  setUp(() => LawFeedCache.instance.clear());

  testWidgets('Cards display while collection is still pending', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final synchronization = Completer<http.Response>();
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path == '/law/sync') return synchronization.future;
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'title': 'Êtes-vous favorable au logement étudiant ?',
              'description': 'Résumé immédiatement consultable',
              'status': 'pending',
            },
          ]),
          200,
        );
      }),
    );
    await tester.pumpWidget(MaterialApp(home: const HomeScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(synchronization.isCompleted, isFalse);
    expect(
      find.text('Êtes-vous favorable au logement étudiant ?'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // A pending scraper must not keep the renderer animating when idle.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    synchronization.complete(http.Response('{"status":"cached"}', 200));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Long feed creates only nearby cards and settles after scrolling',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      ApiService.setHttpClient(
        MockClient(
          (request) async => http.Response(
            request.url.path == '/law/sync'
                ? '{"status":"cached"}'
                : jsonEncode(
                    List.generate(
                      200,
                      (index) => {
                        'id': index + 1,
                        'title': 'Êtes-vous favorable à la mesure $index ?',
                        'description': 'Résumé de la mesure',
                        'status': 'pending',
                      },
                    ),
                  ),
            200,
          ),
        ),
      );
      await tester.pumpWidget(MaterialApp(home: const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LawCard).evaluate().length, lessThan(12));
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -4000),
        3000,
      );
      await tester.pumpAndSettle();
      final cards = tester.widgetList<LawCard>(find.byType(LawCard)).toList();
      expect(cards.length, lessThan(12));
      expect(int.parse(cards.first.law.id), greaterThan(1));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Switching app tabs retains the law list and scroll position', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    var reads = 0;
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.path == '/law/sync') {
          return http.Response('{"status":"cached"}', 200);
        }
        reads++;
        return http.Response(
          jsonEncode(
            List.generate(
              25,
              (index) => {
                'id': index + 1,
                'title': 'Êtes-vous favorable à la mesure $index ?',
                'description': 'Résumé',
                'status': 'pending',
              },
            ),
          ),
          200,
        );
      }),
    );
    await tester.pumpWidget(const EdupoApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    final scroll = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    final offset = scroll.controller!.offset;
    await tester.tap(find.byIcon(Icons.account_balance_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(scroll.controller!.offset, offset);
    expect(reads, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(scroll.controller!.offset, offset);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Launch synchronizes the feed and searches on the server', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final requests = <http.Request>[];
    ApiService.setHttpClient(
      MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/law/sync') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'title': 'Êtes-vous favorable au logement étudiant ?',
              'description': 'Résumé',
              'status': 'pending',
              'vote_date': null,
              'category': 'Logement',
            },
          ]),
          200,
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    expect(
      requests.any(
        (request) =>
            request.method == 'POST' && request.url.path == '/law/sync',
      ),
      isTrue,
    );
    expect(
      find.text('Êtes-vous favorable au logement étudiant ?'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'logement');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(requests.last.url.queryParameters['q'], 'logement');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Network failure is an error with retry, not an empty feed', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.setHttpClient(
      MockClient(
        (request) async => http.Response(
          request.url.path == '/law/sync'
              ? '{"status":"failed"}'
              : '{"detail":"offline"}',
          request.url.path == '/law/sync' ? 200 : 503,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.text('Aucune loi trouvée.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'A search started during synchronization receives the refreshed snapshot',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final synchronization = Completer<http.Response>();
      var refreshed = false;
      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.path == '/law/sync') return synchronization.future;
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'title': refreshed
                    ? 'Êtes-vous favorable au logement actualisé ?'
                    : 'Êtes-vous favorable au logement initial ?',
                'description': 'Résumé',
                'status': 'pending',
                'category': 'Logement',
              },
            ]),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'logement');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('Êtes-vous favorable au logement initial ?'),
        findsOneWidget,
      );
      refreshed = true;
      synchronization.complete(http.Response('{"status":"ok"}', 200));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Êtes-vous favorable au logement actualisé ?'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
