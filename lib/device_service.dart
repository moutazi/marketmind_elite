// lib/services/device_service.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static final DeviceService _i = DeviceService._();
  factory DeviceService() => _i;
  DeviceService._();

  static const _kUUID = 'device_uuid';
  String? _cachedUUID;

  /// Returns a stable UUID tied to this device installation.
  Future<String> getDeviceUUID() async {
    if (_cachedUUID != null) return _cachedUUID!;

    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString(_kUUID);

    if (stored == null) {
      // Try hardware ID first
      try {
        final info  = DeviceInfoPlugin();
        final android = await info.androidInfo;
        stored = android.id; // Android hardware ID
      } catch (_) {
        stored = const Uuid().v4();
      }
      await prefs.setString(_kUUID, stored!);
    }

    _cachedUUID = stored;
    return stored;
  }

  /// Block screenshots and screen recordings — SECURITY CRITICAL
  Future<void> enableContentShield() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  Future<void> disableContentShield() async {
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }
}
