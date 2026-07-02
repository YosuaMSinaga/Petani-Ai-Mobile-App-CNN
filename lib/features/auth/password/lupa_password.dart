import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF00A313);
  static const Color softGrey = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF2D312E);
}

// --- HALAMAN 1: LUPA PASSWORD (INPUT EMAIL) ---
class LupaPasswordPage extends StatefulWidget {
  const LupaPasswordPage({super.key});

  @override
  State<LupaPasswordPage> createState() => _LupaPasswordPageState();
}

class _LupaPasswordPageState extends State<LupaPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleResetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnack("Silakan masukkan email Anda", Colors.orange);
      return;
    }

    if (!email.contains('@')) {
      _showSnack("Format email tidak valid", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://<IP_ADDRESS_HP>:5000/check_email"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (data["success"] == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordPage(email: email),
            ),
          );
        }
      } else {
        _showSnack(data["message"] ?? "Email tidak terdaftar", Colors.redAccent);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Koneksi server gagal", Colors.redAccent);
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
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGreen,
                  AppColors.primaryGreen.withOpacity(0.8),
                  AppColors.accentGreen.withOpacity(0.6),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.elliptical(200, 30),
                bottomRight: Radius.elliptical(200, 30),
              ),
            ),
          ),
          Positioned(
            top: 45,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/lupapassword.png',
                            height: 160,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.email_outlined, size: 100, color: AppColors.primaryGreen),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Lupa Password?",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Jangan khawatir! Masukkan email Anda di bawah untuk mendapatkan link pemulihan.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 69, 69, 69), height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _emailController,
                            label: "Email Terdaftar",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 24),
                          _buildPrimaryButton(
                            onPressed: _isLoading ? () {} : _handleResetPassword,
                            text: "Validasi Email",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.softGrey, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- HALAMAN 2: RESET PASSWORD (INPUT PASSWORD BARU) ---
class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;

  Future<void> _handleUpdate() async {
    if (_newPassController.text.length < 6) {
      _showSnack("Password minimal 6 karakter", Colors.redAccent);
      return;
    }

    if (_newPassController.text != _confirmPassController.text) {
      _showSnack("Konfirmasi password tidak cocok", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://<IP_ADDRESS_HP>:5000/reset_password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "password": _newPassController.text,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (data["success"] == true) {
        _showSnack("Password berhasil diperbarui!", AppColors.accentGreen);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });
      } else {
        _showSnack(data["message"] ?? "Gagal memperbarui password", Colors.redAccent);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Koneksi server gagal", Colors.redAccent);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.8), AppColors.accentGreen.withOpacity(0.6)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.elliptical(200, 30),
                bottomRight: Radius.elliptical(200, 30),
              ),
            ),
          ),
          Positioned(
            top: 45,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_reset_rounded, size: 100, color: AppColors.primaryGreen),
                          const SizedBox(height: 20),
                          const Text(
                            "Password Baru",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Buat password baru untuk akun\n${widget.email}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _newPassController,
                            label: "Password Baru",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPassController,
                            label: "Konfirmasi Password",
                            icon: Icons.lock_clock_outlined,
                            isPassword: true,
                          ),
                          const SizedBox(height: 24),
                          _buildPrimaryButton(
                            onPressed: _isLoading ? () {} : _handleUpdate,
                            text: "Update Password",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 5)),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.softGrey, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _isObscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
          suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}