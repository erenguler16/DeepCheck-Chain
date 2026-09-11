import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants.dart';
import '../models/analysis_result.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';

// ═══════════════════════════════════════════════════════════════════
// SAYFA: BLOKZİNCİRİ SORGULAMA – Hash Doğrulama & Kayıt Kontrolü
// "Kayıtlı" veya "Kayıtsız" sonucunu gösterir.
// ═══════════════════════════════════════════════════════════════════

class VerifyScreen extends StatefulWidget {
  final String? initialHash;

  const VerifyScreen({super.key, this.initialHash});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final TextEditingController _hashController = TextEditingController();
  bool _isLoading = false;
  VerifyResult? _verifyResult;
  String? _errorMessage;
  String? _searchedHash;
  List<Map<String, dynamic>> _recentSeals = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialHash != null && widget.initialHash!.isNotEmpty) {
      _hashController.text = widget.initialHash!;
      // Otomatik sorgula
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyHash();
      });
    }
    _loadRecentSeals();
  }

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSeals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history = prefs.getStringList('seal_history') ?? [];
      setState(() {
        _recentSeals = history
            .take(5)
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _hashController.text = data.text!.trim();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Panodaki hash yapıştırıldı',
            style: TextStyle(fontFamily: AppTextStyles.fontMono),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.surfaceLight,
        ),
      );
    }
  }

  Future<void> _verifyHash([String? customHash]) async {
    final targetHash = (customHash ?? _hashController.text).trim();
    if (targetHash.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen sorgulamak için bir SHA-256 hash kodu girin',
            style: TextStyle(fontFamily: AppTextStyles.fontMono),
          ),
          backgroundColor: AppColors.neonRed,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verifyResult = null;
      _searchedHash = targetHash;
    });

    try {
      final result = await ApiService.verifyMedia(targetHash);
      if (mounted) {
        setState(() {
          _verifyResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bilgi Başlığı
          _buildInfoBanner(),

          const SizedBox(height: AppSpacing.lg),

          // Hash Giriş Alanı
          _buildHashInputField(),

          const SizedBox(height: AppSpacing.md),

          // Hızlı Butonlar (Son Mühürlenen / Pano)
          _buildQuickButtons(),

          const SizedBox(height: AppSpacing.lg),

          // Sorgulama Butonu
          _buildQueryButton(),

          const SizedBox(height: AppSpacing.xl),

          // Yükleniyor Göstergesi
          if (_isLoading) _buildLoadingState(),

          // Hata Mesajı
          if (_errorMessage != null) _buildErrorCard(),

          // Sonuç Kartı (Kayıtlı veya Kayıtsız)
          if (_verifyResult != null && !_isLoading) _buildResultCard(),

          const SizedBox(height: AppSpacing.xl),

          // Son Mühürlenmiş Hash Kısayolları
          if (_recentSeals.isNotEmpty) _buildRecentSealsSection(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return GlassCard(
      borderColor: AppColors.neonBlue.withAlpha(50),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neonBlue.withAlpha(80)),
            ),
            child: const Icon(
              Icons.manage_search,
              color: AppColors.neonBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLOKZİNCİRİ DOĞRULAMA',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SHA-256 kodunu girerek fotoğrafın Hyperledger blokzincirinde mühürlü olup olmadığını sorgulayın.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontMono,
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashInputField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _verifyResult != null
              ? (_verifyResult!.isRegistered
                  ? AppColors.neonGreen.withAlpha(120)
                  : AppColors.neonRed.withAlpha(120))
              : AppColors.gold.withAlpha(60),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _verifyResult != null
                ? (_verifyResult!.isRegistered
                    ? AppColors.neonGreen.withAlpha(20)
                    : AppColors.neonRed.withAlpha(20))
                : Colors.transparent,
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              'SHA-256 HASH KODU',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.gold.withAlpha(180),
                letterSpacing: 1.2,
              ),
            ),
          ),
          TextField(
            controller: _hashController,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontMono,
              fontSize: 13,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Örn: a3f8c2e1b4d5... veya pano içeriği',
              hintStyle: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hashController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.textMuted,
                      onPressed: () {
                        setState(() {
                          _hashController.clear();
                          _verifyResult = null;
                          _errorMessage = null;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.content_paste, size: 18),
                    color: AppColors.gold,
                    tooltip: 'Panodan Yapıştır',
                    onPressed: _pasteFromClipboard,
                  ),
                ],
              ),
            ),
            onSubmitted: (_) => _verifyHash(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButtons() {
    return Row(
      children: [
        if (_recentSeals.isNotEmpty) ...[
          Expanded(
            child: GestureDetector(
              onTap: () {
                final lastHash = _recentSeals.first['hash'] as String?;
                if (lastHash != null) {
                  _hashController.text = lastHash;
                  _verifyHash(lastHash);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withAlpha(40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, color: AppColors.gold, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Son Mührü Getir',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontMono,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Örnek test hash'i
              const testHash =
                  'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
              _hashController.text = testHash;
              _verifyHash(testHash);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neonBlue.withAlpha(40)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.data_exploration,
                      color: AppColors.neonBlue, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Test Hash Dene',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueryButton() {
    return GestureDetector(
      onTap: _isLoading ? null : () => _verifyHash(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [AppColors.surfaceLight, AppColors.surface]
                : [AppColors.gold, AppColors.goldDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            if (!_isLoading)
              BoxShadow(
                color: AppColors.gold.withAlpha(80),
                blurRadius: 14,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              color: _isLoading ? AppColors.textMuted : AppColors.background,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              'BLOKZİNCİRDE SORGULA',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: _isLoading ? AppColors.textMuted : AppColors.background,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.gold,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Hyperledger Blokzinciri Defteri Taranıyor...',
            style: TextStyle(
              fontFamily: AppTextStyles.fontMono,
              fontSize: 11,
              color: AppColors.gold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return GlassCard(
      borderColor: AppColors.neonRed.withAlpha(80),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.neonRed, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BAĞLANTI VEYA SORGULAMA HATASI',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontMono,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontMono,
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _verifyResult!;
    final isRegistered = result.isRegistered;
    final color = isRegistered ? AppColors.neonGreen : AppColors.neonRed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(50),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durum Rozeti (KAYITLI vs KAYITSIZ)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  isRegistered ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRegistered
                          ? 'KAYITLI // DOĞRULANDI'
                          : 'KAYITSIZ // BULUNAMADI',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRegistered
                          ? 'Bu medya Hyperledger blokzincirinde mühürlenmiştir.'
                          : 'Bu hash koduna ait blokzincir kaydı bulunamadı.',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: color.withAlpha(50), height: 1),
          const SizedBox(height: 16),

          // Hash Kodu Görüntüleme
          Text(
            'Sorgulanan Hash:',
            style: TextStyle(
              fontFamily: AppTextStyles.fontMono,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.backgroundDeep,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _searchedHash ?? _hashController.text,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 10,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 14, color: AppColors.gold),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: _searchedHash ?? _hashController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hash panoya kopyalandı'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Detay Bilgileri
          if (isRegistered && result.veri != null) ...[
            if (result.veri!['dosya_adi'] != null)
              _buildDetailRow('Dosya Adı', '${result.veri!['dosya_adi']}'),
            if (result.veri!['zaman'] != null || result.veri!['timestamp'] != null)
              _buildDetailRow('Mühür Zamanı',
                  '${result.veri!['zaman'] ?? result.veri!['timestamp']}'),
            if (result.veri!['ai_sonucu'] != null)
              _buildDetailRow(
                  'Yapay Zeka Analizi', '${result.veri!['ai_sonucu']}'),
            if (result.veri!['tx_id'] != null)
              _buildDetailRow('Blok Tx ID', '${result.veri!['tx_id']}'),
          ] else if (!isRegistered) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neonRed.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neonRed.withAlpha(40)),
              ),
              child: Text(
                'UYARI: Sıfır Güven (Zero-Trust) prensibi uyarınca, blokzincirinde teyit edilemeyen medya içeriğinin sahte ya da manipüle edilmiş olma ihtimali yüksektir.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontMono,
                  fontSize: 10,
                  color: AppColors.neonRed.withAlpha(220),
                  height: 1.4,
                ),
              ),
            ),
          ],

          if (result.mesaj != null && result.mesaj!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Sunucu Yanıtı: ${result.mesaj}',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 10,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SON MÜHÜRLENMİŞ FOTOĞRAFLAR',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Tıkla & Sorgula',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentSeals.length,
          itemBuilder: (context, index) {
            final seal = _recentSeals[index];
            final hash = seal['hash'] as String? ?? '';
            final name = seal['dosya_adi'] as String? ?? 'Medya';
            final time = seal['zaman'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  _hashController.text = hash;
                  _verifyHash(hash);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock, color: AppColors.gold, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontMono,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hash,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontMono,
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (time.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontMono,
                                    fontSize: 8,
                                    color: AppColors.gold.withAlpha(150),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.gold.withAlpha(120),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
