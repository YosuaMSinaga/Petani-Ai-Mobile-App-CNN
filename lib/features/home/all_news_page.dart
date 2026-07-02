import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Pastikan path import NewsDetailPage ini sesuai dengan struktur folder Anda
import '../../features/home/home_screen.dart'; 

class AllNewsPage extends StatefulWidget {
  const AllNewsPage({super.key});

  @override
  State<AllNewsPage> createState() => _AllNewsPageState();
}

class _AllNewsPageState extends State<AllNewsPage> {
  List<dynamic> _articles = [];
  bool _loadingNews = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() => _loadingNews = true);
    
    const apiKey = "b96e85babd4843018ce9c686f53733ac";
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    // QUERY DIPERBANYAK:
    // 1. Everything: Mencari semua berita terkait ekosistem tani & pangan (Max 100)
    final urlEverything = Uri.parse(
        "https://newsapi.org/v2/everything?q=(pertanian OR peternakan OR agribisnis OR hidroponik OR pangan OR nelayan OR perkebunan)&language=id&sortBy=publishedAt&pageSize=100&apiKey=$apiKey&v=$timestamp"
    );
    
    // 2. Top Headlines Business: Berita ekonomi/bisnis Indonesia (Max 100)
    final urlBusiness = Uri.parse(
        "https://newsapi.org/v2/top-headlines?country=id&category=business&pageSize=100&apiKey=$apiKey&v=$timestamp"
    );

    // 3. Top Headlines Science: Berita sains/lingkungan Indonesia (Max 100)
    final urlScience = Uri.parse(
        "https://newsapi.org/v2/top-headlines?country=id&category=science&pageSize=100&apiKey=$apiKey&v=$timestamp"
    );

    try {
      // Menjalankan 3 request secara paralel agar cepat
      final responses = await Future.wait([
        http.get(urlEverything),
        http.get(urlBusiness),
        http.get(urlScience)
      ]);

      List<dynamic> combined = [];

      for (var response in responses) {
        if (response.statusCode == 200) {
          var articles = json.decode(response.body)['articles'] ?? [];
          // Filter: Hanya ambil yang punya gambar, judul valid, dan bukan konten terhapus
          combined.addAll(articles.where((a) => 
              a['urlToImage'] != null && 
              a['urlToImage'].toString().isNotEmpty &&
              a['title'] != null &&
              a['title'] != "[Removed]"));
        }
      }

      // MENGHAPUS DUPLIKAT: Berdasarkan judul agar daftar berita bersih
      final seenTitles = <String>{};
      combined.retainWhere((article) => seenTitles.add(article['title'].toString().trim()));

      // ACAK URUTAN: Agar berita pertanian dan umum tercampur rata
      combined.shuffle(Random());
      
      if (mounted) {
        setState(() {
          _articles = combined;
          _loadingNews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingNews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B5E20);
    const Color textDark = Color(0xFF2D312E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          "Eksplorasi Berita",
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryGreen),
            onPressed: _fetchNews,
          )
        ],
      ),
      body: _loadingNews 
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : RefreshIndicator(
              onRefresh: _fetchNews,
              color: primaryGreen,
              child: _articles.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text("Tidak ada berita ditemukan.")),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      itemCount: _articles.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildNewsCard(context, _articles[index], primaryGreen, textDark);
                      },
                    ),
            ),
    );
  }

  Widget _buildNewsCard(BuildContext context, dynamic article, Color primaryGreen, Color textDark) {
    final String imageUrl = article['urlToImage']?.toString() ?? "";
    final String sourceName = article['source']?['name'] ?? "Berita Terkini";

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsDetailPage(article: article)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                imageUrl,
                width: 110, 
                height: 110, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 110, height: 110, color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Konten Teks
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Sumber Berita
                  Text(
                    sourceName.toUpperCase(),
                    style: TextStyle(color: primaryGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  // Judul
                  Text(
                    article['title'] ?? "Tanpa Judul",
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  // Deskripsi Singkat
                  Text(
                    article['description'] ?? "Tekan untuk membaca berita lengkap hari ini.",
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}