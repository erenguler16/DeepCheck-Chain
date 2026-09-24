import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../widgets/glass_card.dart';

// AI tarafından sahte/derin sahtecilik tespit edilip blokzincirine
// mühürlenmesi engellenen şüpheli işlemler bu ekranda listelenir.

class RejectedTransactionsScreen extends StatefulWidget {
  const RejectedTransactionsScreen({super.key});

  @override
  State<RejectedTransactionsScreen> createState() =>
      _RejectedTransactionsScreenState();
}

class _RejectedTransactionsScreenState
    extends State<RejectedTransactionsScreen> {
  List<Map<String, dynamic>> _rejectedList = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRejected();
  }

  Future<void> _loadRejected() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('rejected_history') ?? [];

    setState(() {
      _rejectedList = list
          .map((s) {
            try {
              return jsonDecode(s) as Map<String, dynamic>;
            } catch (_) {
              return null;
            }
          })
          .whereType<Map<String, dynamic>>()
          .toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredList {
    if (_searchQuery.isEmpty) return _rejectedList;
    final q = _searchQuery.toLowerCase();
    return _rejectedList.where((item) {
      final hash = (item['hash'] as String? ?? '').toLowerCase();
      final name = (item['dosya_adi'] as String? ?? '').toLowerCase();
      final ai = (item['ai_sonucu'] as String? ?? '').toLowerCase();
      return hash.contains(q) || name.contains(q) || ai.contains(q);
    }).toList();
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.neonRed.withAlpha(60)),
        ),
        title: const Text(
          'GEÇERSİZ KAYITLARI TEMİZLE',
          style: TextStyle(
            fontFamily: AppTextStyles.fontMono,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.neonRed,
            letterSpacing: 1,
          ),
        ),
        content: const Text(
          'Tüm reddedilen işlem kayıtları silinecek. Emin misiniz?',
          style: TextStyle(
            fontFamily: AppTextStyles.fontMono,
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'İPTAL',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed.withAlpha(30),
              foregroundColor: AppColors.neonRed,
              elevation: 0,
              side: const BorderSide(color: AppColors.neonRed, width: 1),
            ),
            child: const Text(
              'TEMİZLE',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rejected_history');
      _loadRejected();
    }
  }

  void _copyHash(String hash) {
    Clipboard.setData(ClipboardData(text: hash));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.neonRed, width: 1),
        ),
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: AppColors.neonRed, size: 16),
            SizedBox(width: 8),
            Text(
              'Hash panoya kopyalandı',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = _filteredList;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar
            _buildAppBar(),

            // Liste veya Boş Durum
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonRed,
                        strokeWidth: 2,
                      ),
                    )
                  : listToShow.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: listToShow.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildRejectedCard(
                              listToShow[index],
                              listToShow.length - index,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              // Geri Butonu
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.neonRed,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppColors.neonRed.withAlpha(50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Başlık
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'GEÇERSİZ İŞLEMLER',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontMono,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.neonRed,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neonRed.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.neonRed.withAlpha(70),
                            ),
                          ),
                          child: Text(
                            '${_rejectedList.length}',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontMono,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'AI Filtresine Takılan Sahte Girişimler',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Temizle Butonu
              if (_rejectedList.isNotEmpty)
                GestureDetector(
                  onTap: _clearHistory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonRed.withAlpha(20),
                      border: Border.all(
                        color: AppColors.neonRed.withAlpha(70),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'TEMİZLE',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 9,
                        color: AppColors.neonRed,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Arama Kutusu
          if (_rejectedList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neonRed.withAlpha(40)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontMono,
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  icon: Icon(
                    Icons.search,
                    color: AppColors.neonRed.withAlpha(150),
                    size: 16,
                  ),
                  border: InputBorder.none,
                  hintText: 'Hash, dosya adı veya yapay zeka notu ara...',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontMono,
                    fontSize: 10,
                    color: AppColors.textMuted.withAlpha(120),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectedCard(Map<String, dynamic> record, int index) {
    final String hash = record['hash'] ?? '-';
    final String aiSonucu = record['ai_sonucu'] ?? 'Sahte';
    final String guvenOrani = record['guven_orani'] ?? '-';
    final String dosyaAdi = record['dosya_adi'] ?? '-';
    final String zaman = record['zaman'] ?? '';
    final String? imagePath = record['image_path'] as String?;

    return GlassCard(
      borderColor: AppColors.neonRed.withAlpha(70),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kart Başlığı: Thumbnail + Rozetler + Kopyala
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Görsel Küçük Resmi
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.neonRed.withAlpha(100),
                    width: 1.2,
                  ),
                  color: AppColors.surface,
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath != null && File(imagePath).existsSync()
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.gpp_bad_outlined,
                          color: AppColors.neonRed,
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.gpp_bad_outlined,
                        color: AppColors.neonRed,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),

              // Bilgi Rozetleri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Sıra No
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.neonRed.withAlpha(60),
                            ),
                          ),
                          child: Text(
                            '#$index',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontMono,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Durum Rozeti
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neonRed.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.neonRed.withAlpha(120),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.block_rounded,
                                color: AppColors.neonRed,
                                size: 10,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'REDDEDİLDİ',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontMono,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.neonRed,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // AI Analiz Özeti
                    Row(
                      children: [
                        const Icon(
                          Icons.smart_toy_outlined,
                          color: AppColors.neonRed,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'AI: $aiSonucu ${guvenOrani != '-' ? '($guvenOrani)' : ''}',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontMono,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neonRed,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Hash Kopyala Butonu
              IconButton(
                onPressed: () => _copyHash(hash),
                icon: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                tooltip: 'Hash Kopyala',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Güvenlik Açıklaması
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neonRed.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.neonRed.withAlpha(40)),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.shield_outlined,
                  color: AppColors.neonRed,
                  size: 13,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Manipülasyon riski: Hyperledger Fabric defterine mühürlenmedi.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 9,
                      color: AppColors.neonRed,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Hash Kodu (Monospace)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundDeep,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.neonRed.withAlpha(30)),
            ),
            child: Text(
              hash,
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 9.5,
                color: AppColors.gold.withAlpha(200),
                letterSpacing: 0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),

          // Alt Bilgiler: Dosya Adı & Zaman
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (dosyaAdi != '-')
                Expanded(
                  child: Text(
                    dosyaAdi,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (zaman.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      zaman.length > 19 ? zaman.substring(0, 19).replaceAll('T', ' ') : zaman,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonGreen.withAlpha(15),
                border: Border.all(
                  color: AppColors.neonGreen.withAlpha(50),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 48,
                color: AppColors.neonGreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'GEÇERSİZ İŞLEM YOK',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.neonGreen,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tüm analiz edilen içerikler onaylandı veya henüz şüpheli/sahte bir girişim tespit edilmedi.',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
