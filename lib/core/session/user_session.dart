import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _keyUser = "user_data";

  // Fungsi untuk menyimpan data user saat login
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_keyUser, jsonEncode(userData));
  }

  // Fungsi untuk mengambil data user
  static Future<Map<String, dynamic>?> getUser() async {
    final pref = await SharedPreferences.getInstance();
    String? userData = pref.getString(_keyUser);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  // 🔥 FUNGSI BARU: Untuk update foto profil saja tanpa hapus data lain
  static Future<void> updatePhoto(String base64Image) async {
    final pref = await SharedPreferences.getInstance();
    String? userData = pref.getString(_keyUser);
    
    if (userData != null) {
      // 1. Ambil data lama dan ubah jadi Map
      Map<String, dynamic> userMap = jsonDecode(userData);
      
      // 2. Update field 'photo' saja
      userMap['photo'] = base64Image;
      
      // 3. Simpan kembali ke SharedPreferences
      await pref.setString(_keyUser, jsonEncode(userMap));
    }
  }

  // Fungsi untuk logout
  static Future<void> logout() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_keyUser);
  }
}