import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Crée un client HTTP adapté à la plateforme.
/// Sur le web, utilise BrowserClient avec withCredentials = false
/// pour éviter les problèmes CORS avec la Fetch API.
http.Client createHttpClient() {
  if (kIsWeb) {
    return BrowserClient()..withCredentials = false;
  }
  return http.Client();
}
