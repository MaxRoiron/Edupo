import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/law.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/law_feed_controller.dart';

http.Response page(int offset, {int count = 25, String label = 'mesure'}) =>
    http.Response(
      jsonEncode(
        List.generate(
          count,
          (index) => {
            'id': offset + index + 1,
            'title': 'Êtes-vous favorable à la $label ${offset + index} ?',
            'description': 'Résumé',
            'status': 'pending',
          },
        ),
      ),
      200,
    );

void main() {
  test(
    'Resuming revalidates the database without discarding paginated cards',
    () async {
      var changed = false;
      ApiService.setHttpClient(
        MockClient((request) async {
          final offset = int.parse(request.url.queryParameters['offset']!);
          return page(
            offset,
            label: changed ? 'nouvelle mesure' : 'mesure initiale',
          );
        }),
      );
      final feed = LawFeedController(cache: LawFeedCache());
      await feed.refresh();
      await feed.loadMore();
      final previous = feed.laws;
      changed = true;
      await feed.refresh(preservePosition: true);
      expect(feed.laws.length, 50);
      expect(identical(previous, feed.laws), isTrue);
      expect(feed.updatesAvailable, isTrue);
      await feed.refresh();
      expect(feed.laws.first.title, contains('nouvelle mesure'));
      feed.dispose();
    },
  );
  test(
    'A partial import refreshes available data while keeping its warning',
    () async {
      final sync = Completer<http.Response>();
      var refreshed = false;
      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.path == '/law/sync') return sync.future;
          return page(
            0,
            label: refreshed ? 'mesure actualisée' : 'mesure initiale',
          );
        }),
      );
      final feed = LawFeedController(cache: LawFeedCache());
      await feed.refresh(sync: true);
      refreshed = true;
      sync.complete(http.Response('{"status":"partial","records":1}', 200));
      await feed.synchronize();
      expect(feed.laws.first.title, contains('actualisée'));
      expect(feed.syncWarning, isNotNull);
      feed.dispose();
    },
  );
  test(
    'A slow collection does not delay the first page or a manual refresh',
    () async {
      final sync = Completer<http.Response>();
      var collections = 0;
      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.path == '/law/sync') {
            collections++;
            return sync.future;
          }
          return page(0);
        }),
      );
      final feed = LawFeedController(cache: LawFeedCache());
      await feed.refresh(sync: true);
      expect(feed.laws.length, 25);
      expect(feed.syncing, isTrue);
      await feed.refresh(sync: true);
      expect(collections, 1);
      sync.complete(http.Response('{"status":"cached"}', 200));
      await feed.synchronize();
      feed.dispose();
    },
  );

  test('A delayed search response cannot overwrite a newer query', () async {
    final slow = Completer<http.Response>();
    ApiService.setHttpClient(
      MockClient((request) async {
        if (request.url.queryParameters['q'] == 'ancien') return slow.future;
        return page(0, count: 1, label: 'nouvelle recherche');
      }),
    );
    final feed = LawFeedController(cache: LawFeedCache());
    final previous = feed.select(query: 'ancien');
    await feed.select(query: 'nouveau');
    slow.complete(page(0, label: 'ancienne recherche'));
    await previous;
    expect(feed.query, 'nouveau');
    expect(feed.laws.single.title, contains('nouvelle recherche'));
    feed.dispose();
  });

  test(
    'Background updates retain all loaded pages and offer an explicit refresh',
    () async {
      final sync = Completer<http.Response>();
      final offsets = <int>[];
      ApiService.setHttpClient(
        MockClient((request) async {
          if (request.url.path == '/law/sync') return sync.future;
          final offset = int.parse(request.url.queryParameters['offset']!);
          offsets.add(offset);
          return page(offset);
        }),
      );
      final feed = LawFeedController(cache: LawFeedCache());
      await feed.refresh(sync: true);
      await feed.loadMore();
      sync.complete(http.Response('{"status":"ok","updated":1}', 200));
      await feed.synchronize();
      expect(feed.laws.length, 50);
      expect(feed.updatesAvailable, isTrue);
      expect(offsets, [0, 25]);
      await feed.refresh();
      expect(feed.laws.length, 25);
      expect(feed.updatesAvailable, isFalse);
      feed.dispose();
    },
  );

  test(
    'Cached cards stay readable during revalidation and a network failure',
    () async {
      final cache = LawFeedCache();
      ApiService.setHttpClient(MockClient((_) async => page(0)));
      final first = LawFeedController(cache: cache);
      await first.refresh();
      first.dispose();
      final network = Completer<http.Response>();
      ApiService.setHttpClient(MockClient((_) => network.future));
      final reopened = LawFeedController(cache: cache);
      final revalidation = reopened.refresh();
      expect(reopened.laws.length, 25);
      expect(reopened.loading, isTrue);
      network.complete(http.Response('offline', 503));
      await revalidation;
      expect(reopened.laws.length, 25);
      expect(reopened.error, isNotNull);
      reopened.dispose();
    },
  );

  test(
    'Search caching stays bounded when many different queries are entered',
    () {
      final cache = LawFeedCache();
      const law = Law(
        id: '1',
        title: 'Question',
        description: '',
        category: 'Loi',
      );
      for (var index = 0; index < 30; index++) {
        cache.write('pending', 'query $index', [law]);
      }
      expect(cache.read('pending', 'query 0'), isNull);
      expect(cache.read('pending', 'query 22'), isNotNull);
      expect(cache.read('pending', 'query 29'), isNotNull);
    },
  );

  test(
    'An update arriving during scrolling does not replace visible cards',
    () async {
      final sync = Completer<http.Response>();
      ApiService.setHttpClient(
        MockClient(
          (request) async =>
              request.url.path == '/law/sync' ? sync.future : page(0),
        ),
      );
      final feed = LawFeedController(
        cache: LawFeedCache(),
        canApplyUpdate: () => false,
      );
      await feed.refresh(sync: true);
      final original = feed.laws;
      sync.complete(http.Response('{"status":"ok","created":1}', 200));
      await feed.synchronize();
      expect(identical(original, feed.laws), isTrue);
      expect(feed.updatesAvailable, isTrue);
      feed.dispose();
    },
  );
}
