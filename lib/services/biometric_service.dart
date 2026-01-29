import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // Check if device supports biometrics
  Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Check if device has biometric enrolled
  Future<bool> deviceSupportsDeviceCredential() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Authenticate using biometrics
  Future<bool> authenticate() async {
    try {
      bool isAuthenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to login to Outflow',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  // Save email and password securely for biometric login
  Future<void> saveBiometricCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Note: In production, use flutter_secure_storage or similar
      // This is a basic example - DO NOT use for sensitive data in production
      await prefs.setString('biometric_email', email);
      await prefs.setBool('biometric_enabled', true);

      // In production, encrypt the password using flutter_secure_storage
      // For now, we'll rely on Firebase to validate the email
    } catch (e) {
      throw Exception('Failed to save biometric credentials: $e');
    }
  }

  // Get saved email for biometric login
  Future<String?> getBiometricEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('biometric_email');
    } catch (e) {
      return null;
    }
  }

  // Check if biometric login is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Disable biometric login
  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      await prefs.remove('biometric_email');
    } catch (e) {
      throw Exception('Failed to disable biometric: $e');
    }
  }

  // Get user-friendly biometric name
  Future<String> getBiometricName() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) {
        return 'Biometric';
      }
      if (biometrics.contains(BiometricType.face)) {
        return 'Face';
      }
      if (biometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      }
      if (biometrics.contains(BiometricType.iris)) {
        return 'Iris';
      }
      return 'Biometric';
    } catch (e) {
      return 'Biometric';
    }
  }
}
