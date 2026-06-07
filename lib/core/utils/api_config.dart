import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'CHPA_API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _trimTrailingSlash(_configuredBaseUrl);
    }

    if (kIsWeb) {
      final uri = Uri.base;
      final isLocalHost = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '::1';

      if (isLocalHost) {
        return '${uri.scheme}://${uri.host}:3000/api';
      }

      return '${_trimTrailingSlash(uri.origin)}/api';
    }

    return 'http://localhost:3000/api';
  }

  static String _trimTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
