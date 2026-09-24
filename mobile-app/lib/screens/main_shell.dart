import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/cyber_grid_painter.dart';
import 'shield_screen.dart';
import 'verify_screen.dart';
import 'notary_screen.dart';
import 'system_status_screen.dart';

// Bottom Navigation Bar + 4 Sayfa Yönetimi

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  String? _verifyInitialHash;

  void _navigateToVerify(String hash) {
    setState(() {
      _verifyInitialHash = hash;
      _selectedIndex = 1;
    });
  }

  final List<String> _titles = [
    'FOTOĞRAF MÜHÜRLEME',
    'BLOKZİNCİR SORGULAMA',
    'BLOKZİNCİRİ DEFTERİ',
    'SİSTEM DURUMU',
  ];

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return ShieldScreen(
          onNavigateToVerify: _navigateToVerify,
        );
      case 1:
        return VerifyScreen(
          key: ValueKey(_verifyInitialHash ?? 'verify_screen_default'),
          initialHash: _verifyInitialHash,
          onInitialHashConsumed: () {
            _verifyInitialHash = null;
          },
        );
      case 2:
        return NotaryScreen(
          onNavigateToVerify: _navigateToVerify,
        );
      case 3:
      default:
        return const SystemStatusScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberGridBackground(
        gridColor: AppColors.gold,
        child: SafeArea(
          child: Column(
            children: [
              // Dinamik sistem başlığı
              _buildSystemHeader(),

              // Sayfa içeriği
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedIndex),
                    child: _buildCurrentPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSystemHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withAlpha(30),
            width: 1,
          ),
        ),
        color: AppColors.backgroundDeep.withAlpha(200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Canlı durum noktası
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withAlpha(100),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'DEEPCHECK // ${_titles[_selectedIndex]}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontMono,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.neonGreen.withAlpha(80),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ZERO-TRUST',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.neonGreen.withAlpha(200),
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep,
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withAlpha(40),
            width: 1.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            if (index == 1 && _selectedIndex != 1) {
              _verifyInitialHash = null;
            }
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 10,
        unselectedFontSize: 9,
        selectedLabelStyle: const TextStyle(
          fontFamily: AppTextStyles.fontMono,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTextStyles.fontMono,
          letterSpacing: 1,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_outlined),
            activeIcon: _buildActiveIcon(Icons.verified),
            label: 'MÜHÜRLE',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.manage_search_outlined),
            activeIcon: _buildActiveIcon(Icons.manage_search),
            label: 'SORGULA',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: _buildActiveIcon(Icons.receipt_long),
            label: 'DEFTER',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sensors_outlined),
            activeIcon: _buildActiveIcon(Icons.sensors),
            label: 'SİSTEM',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.gold.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withAlpha(30),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.gold),
    );
  }
}
