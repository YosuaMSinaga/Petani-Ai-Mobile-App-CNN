import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/detection/scanpage.dart';
import '../../features/home/profile_page.dart';

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic>? user; 

  const MainNavigation({super.key, this.user});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(user: widget.user),
      ProfilePage(user: widget.user),
    ];
  }

  void _changeTab(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B5E20);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      /// Tombol Kamera Tengah
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          backgroundColor: primaryColor,
          elevation: 4,
          shape: const CircleBorder(),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScanPage(),
              ),
            );
          },
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: SafeArea(
        child: Container(
          height: 62,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: "Beranda",
                  isActive: _selectedIndex == 0,
                  activeColor: primaryColor,
                  onTap: () => _changeTab(0),
                ),
              ),

              const SizedBox(width: 50),

              Expanded(
                child: _NavItem(
                  icon: Icons.person_rounded,
                  label: "Profil",
                  isActive: _selectedIndex == 1,
                  activeColor: primaryColor,
                  onTap: () => _changeTab(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? activeColor : Colors.grey.shade400,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.w500,
              color:
                  isActive ? activeColor : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}