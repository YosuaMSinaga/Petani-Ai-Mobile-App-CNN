import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF8FAF9);
  static const Color textDark = Color(0xFF2D312E);
}

class TentangPage extends StatelessWidget {
  const TentangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Tentang Petani AI",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryGreen, AppColors.accentGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Logo Aplikasi Tanpa Card/Container Putih
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Image.asset(
                  'assets/images/about.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.eco_rounded,
                      size: 100,
                      color: AppColors.primaryGreen,
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            const Text(
              "Petani AI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
                letterSpacing: 1,
              ),
            ),
            const Text(
              "Versi 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 25),
            
            // Pengertian Tanpa Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Solusi cerdas berbasis kecerdasan buatan untuk membantu petani mendeteksi hama dan penyakit tanaman serta analisis tanah secara instan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Konten Informasi Teknis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Informasi Teknis ResNet-50
                  _buildAboutCard(
                    title: "Teknologi CNN ResNet-50",
                    content: "Aplikasi ini ditenagai oleh Convolutional Neural Network (CNN) dengan arsitektur ResNet-50 untuk mengenali pola penyakit tanaman dengan akurasi tinggi.",
                    icon: Icons.biotech_rounded,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 16),

                  _buildAboutCard(
                    title: "Analisis Kondisi Tanah",
                    content: "Selain deteksi penyakit, sistem ini mampu menganalisis parameter kondisi tanah untuk memberikan rekomendasi pemupukan dan perawatan yang tepat.",
                    icon: Icons.grass_rounded, // Fixed error: menggunakan huruf kecil
                  ),
                  const SizedBox(height: 16),

                  _buildAboutCard(
                    title: "Cara Kerja AI",
                    content: "Model AI memindai tekstur, warna, dan struktur piksel pada foto untuk memberikan diagnosa instan terkait kesehatan tanaman Anda.",
                    icon: Icons.settings_input_component_rounded,
                  ),
                  const SizedBox(height: 16),

                  _buildAboutCard(
                    title: "Tujuan Kami",
                    content: "Meningkatkan hasil panen dengan memberikan diagnosa cepat agar penanganan tanaman dilakukan tepat waktu dan efisien.",
                    icon: Icons.track_changes_rounded,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Text(
              "Dikembangkan oleh",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Text(
              "Yosua Marcelinus Sinaga",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard({
    required String title,
    required String content,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primaryGreen.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isHighlight 
            ? Border.all(color: AppColors.primaryGreen.withOpacity(0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHighlight ? AppColors.primaryGreen : AppColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isHighlight ? Colors.white : AppColors.accentGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isHighlight ? AppColors.primaryGreen : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}