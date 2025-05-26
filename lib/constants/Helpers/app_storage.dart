import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  // Key for storing the password
  static const String _passwordKey = 'user_password';

  // Save the password to SharedPreferences
  /// Save the password to SharedPreferences.
  ///
  /// This method asynchronously stores the password in SharedPreferences.
  /// It uses the [_passwordKey] key to store the password.
  ///
  /// The method returns a [Future] that completes when the password has been
  /// stored.
  static Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
  }

  // Retrieve the password from SharedPreferences
  /// Retrieve the password from SharedPreferences.
  ///
  /// This method asynchronously retrieves the password from SharedPreferences.
  /// It uses the [_passwordKey] key to retrieve the password.
  ///
  /// The method returns a [Future] that resolves to the password if it exists,
  /// or `null` if the password has not been stored.
  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  // Clear the password from SharedPreferences
  /// Clear the password from SharedPreferences.
  ///
  /// This method asynchronously removes the password from SharedPreferences.
  /// It uses the [_passwordKey] key to remove the password.
  ///
  /// The method returns a [Future] that resolves when the password has been
  /// cleared.
  static Future<void> clearPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordKey);
  }
}
