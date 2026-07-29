import 'package:flutter/foundation.dart';

class ApiConfig {
  static const bool _usePhysicalDevice = true;
  static const String _physicalDeviceIp = '192.168.1.5';
  static const int _port = 8000;
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:$_port';

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_usePhysicalDevice) {
        return 'http://$_physicalDeviceIp:$_port';
      } else {
        return 'http://10.0.2.2:$_port';
      }
    }

    return 'http://127.0.0.1:$_port';
  }
}
