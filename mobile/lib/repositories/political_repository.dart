import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/political_party.dart';

/// One immutable, offline snapshot per app session. Loading is lazy and failed
/// reads are evicted so the retry action can actually perform a new read.
class PoliticalRepository {
  PoliticalRepository({Future<String> Function()? loadAsset})
    : _loadAsset =
          loadAsset ??
          (() =>
              rootBundle.loadString('assets/data/political_parties_2027.json'));
  static final instance = PoliticalRepository();
  final Future<String> Function() _loadAsset;
  Future<PoliticalCatalog>? _cached;
  Future<PoliticalCatalog> load() => _cached ??= _read();
  Future<PoliticalCatalog> _read() async {
    try {
      return PoliticalCatalog.fromJson(
        jsonDecode(await _loadAsset()) as Map<String, dynamic>,
      );
    } catch (_) {
      _cached = null;
      rethrow;
    }
  }
}
