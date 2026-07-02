import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import '/utils/global_variable_plant.dart';
import 'camera_page.dart';
import '../../main.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF8FAF9);
  static const Color textDark = Color(0xFF2D312E);
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  late final GenerativeModel _model;
  bool _isAnalyzing = false;
  File? _lastCapturedImage;
  String _analysisResult = '';
  late AnimationController _scanController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview', // Menggunakan versi stabil terbaru
      apiKey: API_KEY,
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInternalCamera();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openInternalCamera() async {
    try {
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraPage(
            camera: backCamera,
            onImageCaptured: (imageFile) {
              setState(() {
                _lastCapturedImage = imageFile;
                _analysisResult = ''; 
              });
              _analyzeWithFlaskAndGemini(imageFile);
            },
          ),
        ),
      );

      if (_lastCapturedImage == null && mounted && !_isAnalyzing) {
        Navigator.pop(context);
      }
    } catch (e) {
      log("Error Kamera: $e");
      _showSnack("Gagal memuat kamera.");
    }
  }

  Future<void> _analyzeWithFlaskAndGemini(File image) async {
    setState(() {
      _isAnalyzing = true;
      _scanController.repeat(reverse: true);
    });

    try {
      // --- TAHAP 1: API FLASK (Timeout 15 Detik) ---
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://<IP_ADDRESS_HP>:5000/predict_plant'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException("Koneksi ke server prediksi gagal."),
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception("Server Flask error: ${response.statusCode}");
      }

      var jsonData = json.decode(response.body);
      String label = jsonData['prediction'] ?? "Unknown";
      double confidence = (jsonData['confidence'] ?? 0).toDouble();

      // --- TAHAP 2: GEMINI AI (Timeout 15 Detik) ---
      String prompt = KEYWORD_PLANT
          .replaceAll('{label}', label)
          .replaceAll('{confidence}', confidence.toStringAsFixed(2));

      final responseGemini = await _model.generateContent([
        Content.text(prompt),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException("Gagal mendapatkan analisis AI tepat waktu."),
      );

      if (mounted) {
        setState(() {
          _analysisResult = '''
## 🔍 Hasil Identifikasi
- **Nama/Kondisi:** $label
- **Tingkat Keyakinan:** ${confidence.toStringAsFixed(2)}%

---

${responseGemini.text ?? "Gagal mendapatkan detail analisis."}
''';
        });
        _scrollToResult();
      }
    } on TimeoutException catch (e) {
      _showSnack(e.message ?? "Waktu koneksi habis.");
    } catch (e) {
      log("Error Analisis: $e");
      _showSnack("Terjadi kendala koneksi atau server.");
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        _scanController.stop();
      }
    }
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        centerTitle: true,
        title: const Text("Analisis Tanaman AI", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildImageContainer(),
            const SizedBox(height: 24),

            if (!_isAnalyzing && _lastCapturedImage != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openInternalCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGreen),
                  label: const Text("Ambil Ulang Foto", 
                    style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                ),
              ),

            if (_analysisResult.isNotEmpty || _isAnalyzing) ...[
              const SizedBox(height: 32),
              Row(
                key: _resultKey,
                children: const [
                  Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 24),
                  SizedBox(width: 10),
                  Text("Laporan Kesehatan AI", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: _isAnalyzing 
                  ? Column(
                      children: const [
                        CircularProgressIndicator(color: AppColors.primaryGreen),
                        SizedBox(height: 16),
                        Text("Menganalisis kondisi tanaman...", style: TextStyle(color: Colors.grey)),
                      ],
                    )
                  : MarkdownBody(
                      data: _analysisResult,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                        h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryGreen, height: 2),
                        listBullet: const TextStyle(color: AppColors.primaryGreen),
                        strong: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ),
              ),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(28),
      color: AppColors.primaryGreen.withOpacity(0.3),
      strokeWidth: 2,
      dashPattern: const [8, 4],
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              if (_lastCapturedImage != null)
                Image.file(_lastCapturedImage!, 
                    width: double.infinity, height: double.infinity, fit: BoxFit.cover)
              else
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_enhance_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("Membuka Kamera...", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              if (_isAnalyzing)
                AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanController.value * 280,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          boxShadow: [
                            BoxShadow(color: AppColors.accentGreen.withOpacity(0.6), 
                              blurRadius: 12, spreadRadius: 2),
                          ],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}