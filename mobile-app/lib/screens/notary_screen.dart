import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../widgets/hash_text_animator.dart';
import 'rejected_transactions_screen.dart';

// Mühürlenmiş hash'lerin siber log/geçmiş sayfası


class NotaryScreen extends StatefulWidget {
  final void Function(String hash)? onNavigateToVerify;

  const NotaryScreen({super.key, this.onNavigateToVerify});

  @override
  State<NotaryScreen> createState() => _NotaryScreenState();
}

class _NotaryScreenState extends State<NotaryScreen> {
  List<Map<String, dynamic>> _history = [];
  int _rejectedCount = 0;
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa her gösterildiğinde geçmişi yenile
    _loadHistory();
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_searchQuery.isEmpty) return _history;
    final q = _searchQuery.toLowerCase();
    return _history.where((item) {
      final hash = (item['hash'] as String? ?? '').toLowerCase();
      final name = (item['dosya_adi'] as String? ?? '').toLowerCase();
      final ai = (item['ai_sonucu'] as String? ?? '').toLowerCase();
      return hash.contains(q) || name.contains(q) || ai.contains(q);
    }).toList();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyStrings =
        prefs.getStringList('seal_history') ?? [];
    final List<String> rejectedStrings =
        prefs.getStringList('rejected_history') ?? [];

    if (mounted) {
      setState(() {
        _history = historyStrings
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
        _rejectedCount = rejectedStrings.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.gold.withAlpha(40)),
        ),
        title: Text(
          'GEÇMİŞİ TEMİZLE',
          style: TextStyle(
            fontFamily: AppTextStyles.fontMono,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
            letterSpacing: 1,
          ),
        ),
        content: Text(
          'Tüm mühür kayıtları silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontMono,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İPTAL',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'SİL',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                color: AppColors.neonRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('seal_history');
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = _filteredHistory;

    return Column(
      children: [
        // Üst bilgi çubuğu & arama
        _buildHeader(),

        // Liste
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.gold,
                    strokeWidth: 2,
                  ),
                )
              : listToShow.isEmpty
                  ? _buildEmptyState()
                  : _buildBlockchainList(listToShow),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BLOKZİNCİRİ DEFTERİ',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_history.length} BLOK KAYDI',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              if (_history.isNotEmpty)
                GestureDetector(
                  onTap: _clearHistory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.neonRed.withAlpha(60),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'TEMİZLE',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 9,
                        color: AppColors.neonRed.withAlpha(180),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Geçersiz / Reddedilen İşlemler Butonu
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RejectedTransactionsScreen(),
                ),
              );
              _loadHistory();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.neonRed.withAlpha(_rejectedCount > 0 ? 90 : 40),
                  width: 1.2,
                ),
                boxShadow: _rejectedCount > 0
                    ? [
                        BoxShadow(
                          color: AppColors.neonRed.withAlpha(25),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.neonRed,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'GEÇERSİZ İŞLEMLER KAYDI',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonRed,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
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
                      '$_rejectedCount KAYIT',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonRed,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.neonRed,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withAlpha(40)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontMono,
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  icon: Icon(Icons.search,
                      size: 16, color: AppColors.gold.withAlpha(150)),
                  hintText: 'Hash, dosya adı veya durum ara...',
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontMono,
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.search_off : Icons.link_off,
            size: 56,
            color: AppColors.gold.withAlpha(40),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'SONUÇ BULUNAMADI' : 'BLOKZİNCİRİ DEFTERİ BOŞ',
            style: TextStyle(
              fontFamily: AppTextStyles.fontMono,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Farklı bir anahtar kelime ile aramayı deneyin'
                : 'Mühürle sayfasından fotoğraf mühürleyerek blok ekleyin',
            style: TextStyle(
              fontFamily: AppTextStyles.fontMono,
              fontSize: 10,
              color: AppColors.textMuted.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainList(List<Map<String, dynamic>> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final record = list[index];
        final String ai = (record['ai_sonucu'] as String? ?? '').toLowerCase();
        final bool isFake = ai.contains('sahte') || ai.contains('fake');
        final bool isAuthentic = !isFake &&
            (record['is_authentic'] == true ||
                ai.contains('gerçek') ||
                ai.contains('gercek'));
        final bool isSealed = !isFake && (record['is_sealed'] == true);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildBlockCard(record, index, isAuthentic, isSealed),
        );
      },
    );
  }

  Widget _buildBlockCard(
      Map<String, dynamic> record, int index, bool isAuthentic, bool isSealed) {
    final Color accentColor =
        isSealed ? AppColors.neonGreen : AppColors.neonRed;
    final String hash = record['hash'] ?? '---';
    final String aiSonucu = record['ai_sonucu'] ?? 'Bilinmiyor';
    final String zaman = record['zaman'] ?? '-';
    final String? imagePath = record['image_path'] as String?;
    final String? guvenOrani = record['guven_orani'] as String?;

    return GestureDetector(
      onTap: () {
        // Hash'i panoya kopyala
        Clipboard.setData(ClipboardData(text: hash));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              side: BorderSide(color: AppColors.gold.withAlpha(40)),
            ),
            content: Text(
              'Hash panoya kopyalandı',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                color: AppColors.gold,
                fontSize: 11,
              ),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: accentColor.withAlpha(30),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(8),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Üst satır: thumbnail + blok no + durum + butonlar ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fotoğraf thumbnail
                _buildThumbnail(imagePath, isSealed),
                const SizedBox(width: 12),

                // Blok bilgisi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Blok numarası ve mühür durumu
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${_history.length - index}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontMono,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Mühür durumu rozeti
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: accentColor.withAlpha(50),
                              ),
                            ),
                            child: Text(
                              isSealed ? 'MÜHÜRLÜ' : 'MÜHÜRLENMEDİ',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontMono,
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // AI sonucu etiketi
                      Row(
                        children: [
                          Icon(
                            Icons.smart_toy,
                            size: 11,
                            color: isAuthentic
                                ? AppColors.neonGreen
                                : AppColors.neonRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI: $aiSonucu',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontMono,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isAuthentic
                                  ? AppColors.neonGreen
                                  : AppColors.neonRed,
                            ),
                          ),
                          if (guvenOrani != null && guvenOrani != '-') ...[
                            const SizedBox(width: 6),
                            Text(
                              '($guvenOrani)',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontMono,
                                fontSize: 8,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Sorgula butonu → Sorgula sayfasına yönlendirir
                Column(
                  children: [
                    if (widget.onNavigateToVerify != null)
                      GestureDetector(
                        onTap: () => widget.onNavigateToVerify!(hash),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neonBlue.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.neonBlue.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.manage_search_rounded,
                                size: 12,
                                color: AppColors.neonBlue,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'SORGULA',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontMono,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neonBlue,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.content_copy,
                      size: 13,
                      color: AppColors.textMuted.withAlpha(120),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Hash
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(6),
              ),
              child: HashTextAnimator(
                targetHash: hash,
                duration: const Duration(milliseconds: 800),
                style: TextStyle(
                  fontFamily: AppTextStyles.fontMono,
                  fontSize: 9,
                  color: AppColors.gold.withAlpha(200),
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Alt bilgiler: zaman + mühür durumu uyarısı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(Icons.access_time, zaman),
                if (!isSealed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonRed.withAlpha(15),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppColors.neonRed.withAlpha(40),
                      ),
                    ),
                    child: Text(
                      '⚠ BLOKZİNCİRE YAZILMADI',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neonRed.withAlpha(200),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Fotoğraf küçük resmi
  Widget _buildThumbnail(String? imagePath, bool isSealed) {
    final bool hasImage =
        imagePath != null && File(imagePath).existsSync();

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSealed
              ? AppColors.neonGreen.withAlpha(50)
              : AppColors.neonRed.withAlpha(50),
          width: 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: hasImage
            ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderIcon(isSealed),
              )
            : _buildPlaceholderIcon(isSealed),
      ),
    );
  }

  Widget _buildPlaceholderIcon(bool isSealed) {
    return Center(
      child: Icon(
        isSealed ? Icons.photo_rounded : Icons.photo_outlined,
        size: 22,
        color: AppColors.textMuted.withAlpha(80),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: AppTextStyles.fontMono,
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
