import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

class ApiConfig {
  /// Base URL du backend.
  /// - Web (Chrome) : localhost directement
  /// - Émulateur Android : 10.0.2.2 pointe vers localhost de la machine hôte
  /// - iOS Simulator / Linux Desktop : localhost
  /// - Appareil physique : remplacer par l'IP locale (ex: 192.168.x.x)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
