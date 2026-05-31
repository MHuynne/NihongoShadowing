import 'package:flutter/foundation.dart';

/// =========================================================
/// CẤU HÌNH API TRUNG TÂM — Chỉ cần sửa ở ĐÂY khi đổi môi trường.
/// =========================================================
class ApiConfig {
  // ─── Bước 1: Chọn chế độ ──────────────────────────────────────────────────
  //
  //   Emulator  → set _usePhysicalDevice = false
  //   Máy thật  → set _usePhysicalDevice = true, sau đó đổi _physicalDeviceIp
  //
  static const bool _usePhysicalDevice = true;

  // ─── Bước 2: IP máy tính (chỉ cần điền khi _usePhysicalDevice = true) ─────
  //
  //   Xem IP bằng lệnh: ipconfig  (Windows) / ifconfig (Mac/Linux)
  //   Lấy địa chỉ IPv4 của card mạng Wifi đang kết nối cùng điện thoại.
  //
  static const String _physicalDeviceIp = '172.20.10.8';

  // ─── Port server FastAPI ───────────────────────────────────────────────────
  static const int _port = 8000;

  // ─── baseUrl tự động chọn theo môi trường ─────────────────────────────────
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:$_port';

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_usePhysicalDevice) {
        // Máy thật: dùng IP LAN của máy tính
        return 'http://$_physicalDeviceIp:$_port';
      } else {
        // Emulator AVD: 10.0.2.2 là alias trỏ về localhost máy tính
        return 'http://10.0.2.2:$_port';
      }
    }

    return 'http://127.0.0.1:$_port';
  }
}
