import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../utils/global_variable_plant.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF8FAF9);
  static const Color textDark = Color(0xFF2D312E);
}

class PlantCheckPage extends StatefulWidget {
  const PlantCheckPage({super.key});
  @override
  State<PlantCheckPage> createState() => _PlantCheckPageState();
}

class _PlantCheckPageState extends State<PlantCheckPage> with SingleTickerProviderStateMixin {
  String strAnswer = '';
  bool visibleSP = false;
  File? imageFile;
  final imagePicker = ImagePicker();
  late final GenerativeModel _model;
  bool _loading = false;

  final ScrollController _scrollController = ScrollController();
  late AnimationController _scanController;
  final GlobalKey _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: API_KEY,
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeenIntro = prefs.getBool('has_seen_plant_intro_v3') ?? false;

    if (!hasSeenIntro) {
      if (mounted) {
        _showIntroPopup();
        await prefs.setBool('has_seen_plant_intro_v3', true);
      }
    }
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_resultKey.currentContext != null) {
          Scrollable.ensureVisible(
            _resultKey.currentContext!,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  Future<void> _analyzePlant() async {
    if (imageFile == null) {
      _showSnack("Silakan pilih foto tanaman terlebih dahulu.");
      return;
    }

    setState(() {
      _loading = true;
      _scanController.repeat(reverse: true);
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://<IP_ADDRESS_HP>:5000/predict_plant'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile!.path),
      );

      // Menambahkan timeout 15 detik untuk request ke server Flask
      var response = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Koneksi ke server memakan waktu terlalu lama.");
        },
      );

      var responseData = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception("Server Flask error: ${response.statusCode}");
      }

      var jsonData = json.decode(responseData);

      String label = jsonData['prediction']?.toString() ?? 'Tidak diketahui';
      double confidence = (jsonData['confidence'] ?? 0).toDouble();

      String prompt = KEYWORD_PLANT
          .replaceAll('{label}', label)
          .replaceAll('{confidence}', confidence.toStringAsFixed(2));

      // Menambahkan timeout juga untuk response dari Gemini AI
      final responseGemini = await _model.generateContent([
        Content.text(prompt),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Gagal mendapatkan respon AI tepat waktu.");
        },
      );

      setState(() {
        strAnswer = '''
## 📊 Hasil Diagnosa AI
- **Prediksi Kondisi:** $label
- **Tingkat Akurasi:** ${confidence.toStringAsFixed(2)}%

---

${responseGemini.text ?? "Gagal mendapatkan detail analisis."}
''';
        visibleSP = true;
      });

      _scrollToResult();
    } on TimeoutException catch (_) {
      _showSnack("Terjadi kendala koneksi ke server (Waktu habis).");
    } catch (e) {
      log("Error: $e");
      _showSnack("Terjadi kendala koneksi ke server.");
    } finally {
      setState(() {
        _loading = false;
        _scanController.stop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
        title: const Text(
          'Analisis Tanaman',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildUploadArea(),
            const SizedBox(height: 24),
            _buildActionButton(),
            const SizedBox(height: 24),
            _buildInstructionCard(),
            if (visibleSP) _buildResultArea(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
              ),
              onPressed: _analyzePlant,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text("Mulai Analisis Sekarang",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _showPickOptions,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(28),
        color: AppColors.primaryGreen.withOpacity(0.3),
        strokeWidth: 2,
        dashPattern: const [8, 4],
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                if (imageFile != null)
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.file(imageFile!, fit: BoxFit.cover),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.image_search_rounded,
                              color: AppColors.primaryGreen, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text("Ketuk untuk ambil foto tanaman",
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                if (_loading && imageFile != null)
                  AnimatedBuilder(
                    animation: _scanController,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanController.value * 200,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.accentGreen.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2)
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text("Cara Cek Tanaman",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 16),
          _instructionStep("1", "Ambil foto bagian daun atau batang yang ingin diperiksa."),
          _instructionStep("2", "Pastikan pencahayaan cukup agar gejala penyakit terlihat."),
          _instructionStep("3", "Tekan tombol analisis untuk memproses citra tanaman."),
          _instructionStep("4", "Dapatkan informasi jenis, penyakit, dan cara penanganan."),
        ],
      ),
    );
  }

  Widget _instructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
            child: Text(number,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    return Column(
      key: _resultKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(
          children: const [
            Icon(Icons.eco_outlined, color: AppColors.primaryGreen, size: 20),
            SizedBox(width: 8),
            Text("Hasil Analisis Kesehatan",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: MarkdownBody(
            data: strAnswer,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              h2: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              listBullet: const TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ),
      ],
    );
  }

  void _showIntroPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                height: 4,
                width: 40,
                decoration:
                    BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Icon(Icons.eco_rounded, size: 50, color: AppColors.primaryGreen),
            const SizedBox(height: 16),
            const Text("Analisis Tanaman AI",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 12),
            const Text(
                "Unggah foto tanamanmu untuk mengetahui jenis serta diagnosa kesehatannya secara instan.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text("Mengerti"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ambil Gambar Tanaman",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _optionButton(Icons.image_rounded, "Galeri", getFromGallery),
                _optionButton(Icons.camera_alt_rounded, "Kamera", getFromCamera),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _optionButton(IconData icon, String label, Function action) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            action();
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryGreen, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> getFromGallery() async {
    final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 1080, maxHeight: 1080, imageQuality: 75);
    if (pickedFile != null) setState(() => imageFile = File(pickedFile.path));
  }

  Future<void> getFromCamera() async {
    final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera, maxWidth: 1080, maxHeight: 1080, imageQuality: 75);
    if (pickedFile != null) setState(() => imageFile = File(pickedFile.path));
  }
}