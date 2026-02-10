import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyCurrency = 'currency';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyBiometrics = 'biometrics_enabled';

  late SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();

  String _currencySymbol = 'RM';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isBiometricsEnabled = false;

  String get currencySymbol => _currencySymbol;
  ThemeMode get themeMode => _themeMode;
  bool get isBiometricsEnabled => _isBiometricsEnabled;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    
    // Load Currency
    _currencySymbol = _prefs.getString(_keyCurrency) ?? 'RM';
    
    // Load Theme
    final themeIndex = _prefs.getInt(_keyThemeMode);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Load Biometrics
    _isBiometricsEnabled = _prefs.getBool(_keyBiometrics) ?? false;
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    await _prefs.setString(_keyCurrency, symbol);
    notifyListeners();
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  Future<bool> toggleBiometrics(bool enable) async {
    if (enable) {
      // Check if device supports it
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;
      
      bool authenticated = false;
      try {
        authenticated = await _auth.authenticate(
          localizedReason: 'Please authenticate to enable biometrics',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
      } catch (e) {
        debugPrint('Biometric auth failed: $e');
        return false;
      }
      
      if (!authenticated) return false;
    }

    _isBiometricsEnabled = enable;
    await _prefs.setBool(_keyBiometrics, enable);
    notifyListeners();
    return true;
  }
}
