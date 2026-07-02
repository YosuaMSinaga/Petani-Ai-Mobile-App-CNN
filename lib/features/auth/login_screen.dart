import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/password/lupa_password.dart';
import 'register_screen.dart';
import '../../core/navigation/main_navigation.dart';
import '../../core/session/user_session.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF00A313);
  static const Color softGrey = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF2D312E);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // KONFIGURASI GOOGLE SIGN IN
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // ================= LOGIN API MANUAL =================
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Email dan password wajib diisi", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://<IP_ADDRESS_HP>:5000/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await UserSession.saveUser(data["user"]);
        
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigation(user: data["user"]),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showSnack(data["message"] ?? "Login gagal", Colors.redAccent);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Koneksi ke server gagal", Colors.redAccent);
    }
  }

  // ================= GOOGLE LOGIN (SINKRON DENGAN FLASK) =================
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // Memaksa sign out agar dialog pemilihan akun selalu muncul
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Mengirim data ke backend Flask (Endpoint google_login)
      final response = await http.post(
        Uri.parse("http://<IP_ADDRESS_HP>:5000/google_login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": googleUser.displayName ?? "User Petani AI",
          "email": googleUser.email,
          "google_id": googleUser.id,
          "photo": googleUser.photoUrl ?? "",
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        // Simpan data user ke session lokal
        await UserSession.saveUser(data["user"]);

        if (!mounted) return;
        setState(() => _isLoading = false);
        
        // Pindah ke MainNavigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigation(user: data["user"]),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showSnack(data["message"] ?? "Google login gagal", Colors.redAccent);
      }
    } catch (e) {
      debugPrint("GOOGLE LOGIN ERROR: ${e.toString()}");
      setState(() => _isLoading = false);
      _showSnack("Google Sign In gagal terhubung ke server", Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Hero(
                      tag: 'logo',
                      child: Image.asset(
                        'assets/images/welcome_logo.png',
                        height: 85,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Selamat Datang",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Masuk ke akun Petani AI Anda",
                      style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 69, 69, 69)),
                    ),
                    const SizedBox(height: 28),

                    _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LupaPasswordPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Lupa Password?",
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    _buildPrimaryButton(
                      onPressed: _isLoading ? () {} : _login,
                      text: "Masuk",
                    ),

                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "atau",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    
                    const SizedBox(height: 16),

                    _buildGoogleButton(),

                    const SizedBox(height: 24),
                    
                    _buildFooter(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                    strokeWidth: 5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required VoidCallback onPressed, required String text}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _loginWithGoogle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/google.png", width: 18, errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata)),
            const SizedBox(width: 10),
            const Text(
              "Masuk dengan Google",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return RichText(
      text: TextSpan(
        text: "Belum punya akun? ",
        style: const TextStyle(color: Colors.grey, fontSize: 14),
        children: [
          TextSpan(
            text: "Daftar Sekarang",
            style: const TextStyle(
              color: AppColors.accentGreen,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
          ),
        ],
      ),
    );
  }
}