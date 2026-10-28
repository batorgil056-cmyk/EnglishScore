import 'local_account.dart';

/// In-memory demo session only; never restored from the saved profile email.
/// There is no server authentication or server token to revoke in this app.
class DemoSession {
  static String? _email;
  static String? get email => _email;
  static bool get isSignedIn => _email != null;

  static Future<void> signIn(String email) async {
    await LocalAccount.saveEmail(email);
    _email = email.trim();
  }

  static void signOut() {
    _email = null;
  }
}
