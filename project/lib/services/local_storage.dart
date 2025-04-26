
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    bool success = await prefs.setString('auth_token', token);

    if (success) {
      print("✅ Token stored successfully!");
    } else {
      print("⚠️ Failed to store token!");
    }
  }

  static Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();

  // Add a small delay to ensure data is loaded properly
  await Future.delayed(Duration(milliseconds: 500));

  String? token = prefs.getString('auth_token');

  if (token == null || token.isEmpty) {
    print("⚠️ No token found in local storage.");
    return null;
  } else {
    print("✅ Retrieved Token: $token");
    return token;
  }
}
static Future<void> clearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');  // Clear the token
  await prefs.remove('user_pages');  // Clear pages data if needed
  await prefs.remove('user_data');   // Clear user data
  print("🗑️ Token and user data cleared!");
}

static Future<Map<String, dynamic>?> getUser() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');

    if (userJson == null || userJson.isEmpty) {
      print("⚠️ No user data found in local storage.");
      return null;
    }

    // Parse the JSON string to a Map
    final userData = Map<String, dynamic>.from(
      jsonDecode(userJson) as Map
    );

    print("✅ Retrieved user data: ${userData['email']}");
    return userData;
  } catch (e) {
    print("❌ Error retrieving user data: $e");
    return null;
  }
}

static Future<void> saveUser(Map<String, dynamic> userData) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(userData);

    bool success = await prefs.setString('user_data', userJson);

    if (success) {
      print("✅ User data stored successfully!");
    } else {
      print("⚠️ Failed to store user data!");
    }
  } catch (e) {
    print("❌ Error saving user data: $e");
  }
}

}

