import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color textDark = Color(0xFF2D312E);
  static const Color textGrey = Color.fromARGB(255, 69, 69, 69);
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController controller = PageController();
  int index = 0;

  final List<Map<String, dynamic>> slides = [
    {
      "isIcon": false,
      "data": "assets/images/welcome_logo.png",
      "title": "Selamat Datang di Petani AI",
      "desc": "Siap membantu merawat tanamanmu \nmenjadi lebih cerdas dan mudah."
    },
    {
      "isIcon": false,
       "data": "assets/images/asistentanaman.png",
      "title": "Asisten Tanaman",
      "desc":
          "Diagnosa Penyakit Tanaman Anda dan Temukan Solusi Penanganan Yang Tepat Agar Kembali Sehat."
    },
    {
      "isIcon": false,
      "data": "assets/images/cepatakurat.png",
      "title": "Cepat & Akurat",
      "desc":
          "Dapatkan hasil analisis kesehatan tanaman hanya dalam hitungan detik."
    },
  ];

  void goLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.1, end: 1.0).animate(curve),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Tombol Lewati
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: goLogin,
                  child: const Text(
                    "Lewati",
                    style: TextStyle(
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ),
            ),

      
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => index = i),
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                
                    child: TweenAnimationBuilder(
                      key: ValueKey(i),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          // Efek gambar dan teks bergeser dari bawah ke atas
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (slides[i]["isIcon"])
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      slides[i]["data"] as IconData,
                                      size: 80,
                                      color: AppColors.primaryGreen,
                                    ),
                                  )
                                else
                                  Image.asset(
                                    slides[i]["data"] as String,
                                    height: 170,
                                    fit: BoxFit.contain,
                                  ),
                                const SizedBox(height: 40),
                                Text(
                                  slides[i]["title"] as String,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  slides[i]["desc"] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textGrey,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Indikator Titik (Dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: index == i ? 20 : 6,
                  decoration: BoxDecoration(
                    color: index == i
                        ? AppColors.primaryGreen
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Tombol Utama
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (index == slides.length - 1) {
                      goLogin();
                    } else {
                      controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      index == slides.length - 1 ? "Mulai Sekarang" : "Lanjut",
                      key: ValueKey<int>(index),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}