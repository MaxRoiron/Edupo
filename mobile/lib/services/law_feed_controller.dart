import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/law.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Small public-data cache: instant tab revisits, always revalidated online.
class LawFeedCache {
  static final instance = LawFeedCache();
  static const maxEntries = 8;
  final Map<String, List<Law>> _pages = {};

  String _key(String group, String query) =>
      '${ApiConfig.baseUrl}\u0000$group\u0000$query';

  List<Law>? read(String group, String query) {
    final key = _key(group, query);
    final page = _pages.remove(key);
    if (page != null) _pages[key] = page;
    return page;
  }

  void write(String group, String query, List<Law> laws) {
    final key = _key(group, query);
    _pages.remove(key);
    _pages[key] = List.unmodifiable(laws);
    while (_pages.length > maxEntries) {
      _pages.remove(_pages.keys.first);
    }
  }

  void clear() => _pages.clear();
}

/// Reading the feed never waits for the scraper. Old requests cannot replace
/// a newer search, and a background update never discards paginated results.
class LawFeedController extends ChangeNotifier {
  LawFeedController({LawFeedCache? cache, bool Function()? canApplyUpdate})
    : _cache = cache ?? LawFeedCache.instance,
      _canApplyUpdate = canApplyUpdate ?? (() => true);

  static const pageSize = 25;
  final LawFeedCache _cache;
  final bool Function() _canApplyUpdate;
  List<Law> laws = const [];
  String group = 'pending';
  String query = '';
  bool loading = true;
  bool loadingMore = false;
  bool syncing = false;
  bool hasMore = false;
  bool updatesAvailable = false;
  String? error;
  String? syncWarning;
  int _version = 0;
  bool _disposed = false;
  Future<void>? _latestLoad;
  Future<void>? _synchronization;

  Future<void> refresh({bool sync = false, bool preservePosition = false}) {
    if (!preservePosition) updatesAvailable = false;
    final load = _load(preservePosition: preservePosition);
    _latestLoad = load;
    if (sync) unawaited(synchronize());
    return load;
  }

  Future<void> select({String? group, String? query}) {
    final nextGroup = group ?? this.group;
    final nextQuery = query ?? this.query;
    if (nextGroup == this.group && nextQuery == this.query) {
      return Future.value();
    }
    this.group = nextGroup;
    this.query = nextQuery;
    laws = _cache.read(this.group, this.query) ?? const [];
    hasMore = laws.length == pageSize;
    return refresh();
  }

  Future<void> loadMore() {
    if (loading || loadingMore || !hasMore) return Future.value();
    final load = _load(more: true);
    _latestLoad = load;
    return load;
  }

  static Object _snapshot(Law law) => (
    law.id,
    law.title,
    law.description,
    law.status,
    law.category,
    law.voteDate,
    law.publishedAt,
    law.scrutinId,
    law.sourceUrl,
    law.officialTitle,
    law.descriptionSourceUrl,
  );

  Future<void> _load({bool more = false, bool preservePosition = false}) async {
    final version = ++_version;
    final requestedGroup = group;
    final requestedQuery = query;
    final offset = more ? laws.length : 0;
    if (!more && laws.isEmpty) {
      laws = _cache.read(group, query) ?? const [];
    }
    error = null;
    loading = !more;
    loadingMore = more;
    notifyListeners();
    try {
      final response = await ApiService.getAllLaws(
        group: requestedGroup,
        query: requestedQuery,
        offset: offset,
        limit: pageSize,
      );
      if (_disposed || version != _version) return;
      if (!response.success) {
        error = response.message;
        return;
      }
      final items = (response.data!['list'] as List)
          .map((item) => Law.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      if (more) {
        final ids = laws.map((law) => law.id).toSet();
        laws = List.unmodifiable([
          ...laws,
          ...items.where((law) => ids.add(law.id)),
        ]);
      } else {
        _cache.write(requestedGroup, requestedQuery, items);
        // Resuming the app must read the database even when the server's
        // scraper cache is fresh. Do not replace a list being browsed.
        if (preservePosition &&
            (laws.length > pageSize || !_canApplyUpdate())) {
          if (!listEquals(
            laws.take(pageSize).map(_snapshot).toList(),
            items.map(_snapshot).toList(),
          )) {
            updatesAvailable = true;
          }
          return;
        }
        laws = List.unmodifiable(items);
      }
      hasMore = items.length == pageSize;
    } catch (_) {
      if (!_disposed && version == _version) {
        error = 'Les données reçues sont invalides. Réessayez.';
      }
    } finally {
      if (!_disposed && version == _version) {
        loading = loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> synchronize() =>
      _synchronization ??= _synchronize().whenComplete(() {
        _synchronization = null;
      });

  Future<void> _synchronize() async {
    syncing = true;
    notifyListeners();
    try {
      final update = await ApiService.synchronizeLaws();
      if (_disposed) return;
      syncWarning = update.success ? null : update.message;
      final status = update.data?['status'];
      final changed =
          (update.success || status == 'partial') &&
          status != 'disabled' &&
          update.data?['not_modified'] != true &&
          (status != 'cached' || laws.isEmpty);
      if (changed) {
        // Do not reuse an HTTP read that started before the import committed.
        await _latestLoad;
        if (_disposed) return;
        if (laws.length <= pageSize && _canApplyUpdate()) {
          await refresh();
        } else {
          updatesAvailable = true;
        }
      }
    } finally {
      if (!_disposed) {
        syncing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
