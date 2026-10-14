import 'package:http/http.dart' as http;

/// package:http selects its browser/native implementation with conditional
/// imports. BrowserClient defaults to withCredentials=false for Bearer auth.
http.Client createHttpClient() => http.Client();
