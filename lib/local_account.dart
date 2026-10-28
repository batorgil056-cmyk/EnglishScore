import 'package:shared_preferences/shared_preferences.dart';

/// Last email submitted through this device's demo sign-in/registration form.
/// This is a local profile, not a verified account or authentication token.
/// Passwords are never stored here.
class LocalAccount {
  static const emailKey = 'englishscore.local_account.email.v1';

  static Future<String?> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(emailKey)?.trim();
    return email == null || email.isEmpty ? null : email;
  }

  static Future<void> saveEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(email, 'email');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(emailKey, trimmed)) {
      throw StateError('Unable to save the local account email');
    }
  }
}
