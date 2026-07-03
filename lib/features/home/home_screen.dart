import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// Import halaman terkait
import 'profile_page.dart'; 
import '../detection/plant_check_page.dart';
import '../detection/land_check_page.dart';
import 'all_news_page.dart';
import '../../core/session/user_session.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF8FAF9);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF2D312E);
}

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Map<String, dynamic> currentUserData;
  
  String _temperature = "--°C";
  String _description = "Memuat...";
  String _iconUrl = "";
  bool _loadingWeather = true;

  List<dynamic> _articles = [];
  bool _loadingNews = true;

  late PageController _pageController;
  late ScrollController _scrollController;
  double _blurOpacity = 0.0;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    currentUserData = Map<String, dynamic>.from(widget.user ?? {});
    _pageController = PageController(viewportFraction: 0.88);
    _scrollController = ScrollController();
    
    _scrollController.addListener(() {
      double offset = _scrollController.offset;
      double newOpacity = (offset / 40).clamp(0.0, 1.0);
      if (newOpacity != _blurOpacity) {
        setState(() => _blurOpacity = newOpacity);
      }
    });

    _refreshData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadingNews = true;
      _loadingWeather = true;
    });
    await Future.wait([_fetchWeather(), _fetchNews()]);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  Future<void> _fetchWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      const apiKey = "API_KEY_KAMU";
      final url = Uri.parse(
          "https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey&lang=id");
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temperature = "${(data['main']['temp'] as num).toDouble().toStringAsFixed(1)}°C";
          _description = data['weather'][0]['description'];
          _iconUrl = "https://openweathermap.org/img/wn/${data['weather'][0]['icon']}@2x.png";
          _loadingWeather = false;
        });
      }
    } catch (_) {
      setState(() => _loadingWeather = false);
    }
  }

  Future<void> _fetchNews() async {
    const apiKey = "API_KEY_KAMU";
    final url = Uri.parse("https://newsapi.org/v2/everything?q=pertanian+Indonesia&language=id&sortBy=publishedAt&pageSize=10&apiKey=$apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var rawArticles = json.decode(response.body)['articles'] ?? [];
        List<dynamic> filtered = rawArticles.where((a) => a['urlToImage'] != null).toList();
        setState(() {
          _articles = filtered;
          _loadingNews = false;
        });
        _startAutoSlide();
      }
    } catch (_) {
      setState(() => _loadingNews = false);
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _pageController.hasClients && _articles.isNotEmpty) {
        _currentPage = (_currentPage + 1) % _articles.length;
        _pageController.animateToPage(_currentPage,
            duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
      }
    });
  }

  Widget _buildHeader() {
    final String displayName = currentUserData['name'] ?? currentUserData['username'] ?? "Petani";
    final String? photoData = currentUserData['photo'] ?? currentUserData['photo_url'];

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Halo $displayName,", 
                style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
              Text(_getGreeting(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ProfilePage(user: currentUserData))
              );
              final updatedUser = await UserSession.getUser();
              if (updatedUser != null) {
                setState(() {
                  currentUserData = Map<String, dynamic>.from(updatedUser);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.1), width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.accentGreen.withOpacity(0.1),
                backgroundImage: photoData != null && photoData.isNotEmpty
                    ? (photoData.startsWith('http') 
                        ? NetworkImage(photoData) as ImageProvider
                        : MemoryImage(base64Decode(photoData))) 
                    : null,
                child: photoData == null || photoData.isEmpty
                  ? const Icon(Icons.person_outline_rounded, color: AppColors.primaryGreen, size: 28)
                  : null,
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: _buildHeader(),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primaryGreen,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildWeatherCard(size),
                        const SizedBox(height: 32),
                        _buildSectionTitle("Layanan Utama"),
                        const SizedBox(height: 16),
                        _buildQuickActions(context),
                        const SizedBox(height: 32),
                        _buildSectionTitle(
                          "Berita Pertanian",
                          hasViewAll: true,
                          onViewAllTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const AllNewsPage())),
                        ),
                        const SizedBox(height: 16),
                        _buildNewsSection(size),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool hasViewAll = false, VoidCallback? onViewAllTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        if (hasViewAll)
          GestureDetector(
            onTap: onViewAllTap,
            child: const Text("Lihat Semua",
                style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildWeatherCard(Size size) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGreen.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          _loadingWeather
              ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : (_iconUrl.isNotEmpty
                  ? Image.network(_iconUrl, width: 60)
                  : const Icon(Icons.cloud_queue_rounded, color: Colors.white, size: 50)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_description.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const Text("Lokasi Anda saat ini", style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Text(_temperature,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _quickButton("Cek Lahan", Icons.landscape_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LandCheckPage())))),
        const SizedBox(width: 16),
        Expanded(
            child: _quickButton("Cek Tanaman", Icons.eco_rounded,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlantCheckPage())))),
      ],
    );
  }

  Widget _quickButton(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primaryGreen, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection(Size size) {
    if (_loadingNews) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primaryGreen)));
    if (_articles.isEmpty) return const Text("Tidak ada berita pertanian terbaru.");
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _articles.length,
        itemBuilder: (context, index) => _buildNewsCard(_articles[index]),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    final String imageUrl = article['urlToImage']?.toString() ?? "";

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailPage(article: article))),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter)),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Text(
            article['title'] ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> article;
  const NewsDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final String publishedAt = article['publishedAt'] != null 
        ? article['publishedAt'].toString().substring(0, 10) 
        : "Baru saja";

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // AppBar dengan Efek Parallax
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppColors.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  article['urlToImage'] != null
                      ? Image.network(article['urlToImage'], fit: BoxFit.cover)
                      : Container(color: AppColors.accentGreen),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black54, Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Konten Utama
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Kategori & Tanggal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "INFO PERTANIAN",
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(publishedAt, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Judul Berita
                  Text(
                    article['title'] ?? "",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Identitas Penulis/Sumber
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.accentGreen,
                        child: Icon(Icons.person, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        article['source']?['name'] ?? "Warta Tani",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),

                  // Deskripsi Singkat (Ditebalkan)
                  Text(
                    article['description'] ?? "",
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kalimat Berita (String Kalimat Panjang)
                  const Text(
                    "Sektor pertanian di Indonesia kini tengah memasuki era baru dengan pemanfaatan teknologi kecerdasan buatan. Transformasi digital ini memungkinkan para petani untuk memonitor kesehatan tanaman serta kondisi unsur hara tanah secara real-time langsung melalui smartphone mereka.",
                    style: TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Selain efisiensi biaya, penerapan teknologi AI seperti deteksi penyakit berbasis citra digital mampu menekan angka gagal panen hingga 30%. Melalui data yang akurat, petani dapat memberikan dosis pupuk yang tepat sasaran, sehingga keberlanjutan lingkungan tetap terjaga tanpa mengurangi kualitas hasil panen nasional.",
                    style: TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Pemerintah terus mendorong kolaborasi antara startup teknologi pertanian dengan kelompok tani lokal di seluruh pelosok tanah air. Langkah ini diharapkan mampu memperkuat ketahanan pangan nasional di tengah tantangan perubahan iklim global yang kian tidak menentu saat ini.",
                    style: TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
                  ),

                  const SizedBox(height: 40),

                  // Tombol Baca Selengkapnya
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => launchUrl(Uri.parse(article['url'])),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Baca Artikel Lengkap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 10),
                          Icon(Icons.open_in_new, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
