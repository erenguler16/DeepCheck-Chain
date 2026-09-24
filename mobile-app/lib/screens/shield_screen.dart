import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants.dart';
import '../models/analysis_result.dart';
import '../services/api_service.dart';
import '../widgets/scanning_overlay.dart';
import '../widgets/neon_result_card.dart';
import '../widgets/glass_card.dart';

// FOTOĞRAF MÜHÜRLEME

class ShieldScreen extends StatefulWidget {
  final void Function(String hash)? onNavigateToVerify;

  const ShieldScreen({super.key, this.onNavigateToVerify});

  @override
  State<ShieldScreen> createState() => _ShieldScreenState();
}

class _ShieldScreenState extends State<ShieldScreen>
    with SingleTickerProviderStateMixin {
  File? _capturedFile;
  bool _isProcessing = false;
  AnalysisResult? _result;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (file == null) return;
      await _processImage(File(file.path));
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null) return;
      await _processImage(File(file.path));
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _processImage(File file) async {
    setState(() {
      _capturedFile = file;
      _isProcessing = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.uploadMedia(file);
      await _saveToHistory(result);

      if (mounted) {
        setState(() {
          _result = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic error) {
    if (mounted) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('ApiException: ', '');
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveToHistory(AnalysisResult result) async {
    try {
      // AI sonucu sahte diyorsa KESİNLİKLE mühürleme!
      final bool isSealed;
      if (result.isFake) {
        isSealed = false; // AI Sahte dedi → ASLA mühürleme!
      } else if (result.isAuthentic) {
        isSealed = true; // AI Gerçek dedi → Blokzincirine mühürle
      } else {
        // AI tespit edememişse veya şüpheliyse mühürleme
        isSealed = false;
      }

      final prefs = await SharedPreferences.getInstance();
      final hash = result.hashKodu ?? 'HASH_HESAPLANAMADI';

      final record = jsonEncode({
        'hash': hash,
        'ai_sonucu': result.aiSonucu ?? 'Bilinmiyor',
        'guven_orani': result.guvenOrani ?? '-',
        'dosya_adi': result.dosyaAdi ?? '-',
        'zaman': result.zaman ?? DateTime.now().toIso8601String(),
        'is_authentic': result.isAuthentic,
        'is_sealed': isSealed,
        'image_path': _capturedFile?.path,
      });

      if (isSealed) {
        // Gerçek fotoğraf → Blokzinciri Defteri (seal_history)
        final List<String> history = prefs.getStringList('seal_history') ?? [];
        history.insert(0, record);
        if (history.length > 50) history.removeLast();
        await prefs.setStringList('seal_history', history);
      } else {
        // Sahte veya şüpheli fotoğraf → Geçersiz İşlemler (rejected_history)
        final List<String> rejected =
            prefs.getStringList('rejected_history') ?? [];
        rejected.insert(0, record);
        if (rejected.length > 50) rejected.removeLast();
        await prefs.setStringList('rejected_history', rejected);
      }
    } catch (_) {}
  }

  void _reset() {
    setState(() {
      _capturedFile = null;
      _isProcessing = false;
      _result = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Bilgilendirme Başlık Kartı
          _buildHeaderBanner(),

          const SizedBox(height: AppSpacing.lg),

          // 2. Siber Vizör (Ana Medya & Tarama Çerçevesi)
          _buildCyberViewfinder(),

          const SizedBox(height: AppSpacing.lg),

          // 3. Eylem Bölümü (Fotoğraf Seçilmediyse: Kamera + Galeri Butonları)
          if (_result == null && !_isProcessing) _buildActionButtons(),

          // 4. İşlem Sırasında İlerleme Paneli
          if (_isProcessing) _buildProcessingState(),

          // 5. Hata Mesajı
          if (_errorMessage != null) _buildErrorCard(),

          // 6. Sonuç Kartı ve Aksiyonlar
          if (_result != null) _buildResultSection(),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return GlassCard(
      borderColor: AppColors.gold.withAlpha(50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withAlpha(70)),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOTOĞRAFI BLOKZİNCİRİNE MÜHÜRLE',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontMono,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kamera veya galeriden medya aktarın; yapay zeka analiz edip Hyperledger Fabric ağına mühürlesin.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontMono,
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberViewfinder() {
    return Container(
      width: double.infinity,
      height: 290,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _isProcessing
              ? AppColors.gold
              : (_result != null
                  ? (_result!.isAuthentic
                      ? AppColors.neonGreen
                      : AppColors.neonRed)
                  : AppColors.gold.withAlpha(50)),
          width: _isProcessing ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isProcessing
                ? AppColors.gold.withAlpha(40)
                : (_result != null
                    ? (_result!.isAuthentic
                        ? AppColors.neonGreen.withAlpha(30)
                        : AppColors.neonRed.withAlpha(30))
                    : AppColors.gold.withAlpha(15)),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg - 1.5),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            // Fotoğraf Görüntüsü
            if (_capturedFile != null)
              Image.file(
                _capturedFile!,
                fit: BoxFit.cover,
              ),

            // Boş Durum: Animasyonlu Hologram Kalkan
            if (_capturedFile == null && !_isProcessing)
              _buildEmptyHologramContent(),

            // Tarama Çizgisi Overlay
            ScanningOverlay(isScanning: _isProcessing),

            // Siber Köşe İşaretleri (HUD Brackets)
            _buildHudCornerBrackets(),

            // Mühürlendi Filigran Rozeti
            if (_result != null && !_isProcessing) _buildSealBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHologramContent() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withAlpha(15),
                  border: Border.all(
                    color: AppColors.gold.withAlpha(60),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withAlpha(25),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.security,
                    size: 46,
                    color: AppColors.gold.withAlpha(220),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'MEDYA BEKLENİYOR',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.0,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Aşağıdaki butonlardan seçim yapın',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 10,
                color: AppColors.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHudCornerBrackets() {
    const double bracketSize = 16.0;
    const double bracketThickness = 2.5;
    final Color bracketColor = _isProcessing ? AppColors.gold : AppColors.neonBlue;

    return Stack(
      children: [
        // Sol Üst
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: bracketColor, width: bracketThickness),
                left: BorderSide(color: bracketColor, width: bracketThickness),
              ),
            ),
          ),
        ),
        // Sağ Üst
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: bracketColor, width: bracketThickness),
                right: BorderSide(color: bracketColor, width: bracketThickness),
              ),
            ),
          ),
        ),
        // Sol Alt
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: bracketColor, width: bracketThickness),
                left: BorderSide(color: bracketColor, width: bracketThickness),
              ),
            ),
          ),
        ),
        // Sağ Alt
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: bracketColor, width: bracketThickness),
                right: BorderSide(color: bracketColor, width: bracketThickness),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSealBadge() {
    final isFake = _result!.isFake;
    final isAuthentic = _result!.isAuthentic;
    final isOk = !isFake && isAuthentic;
    final color = isOk ? AppColors.neonGreen : AppColors.neonRed;

    return Positioned(
      top: 14,
      left: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.backgroundDeep.withAlpha(220),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(60),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOk ? Icons.verified : Icons.warning_rounded,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              isOk
                  ? 'BLOKZİNCİRE MÜHÜRLENDİ'
                  : 'MANİPÜLASYON / REDDEDİLDİ',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 1. Kamera Butonu (Gold Vurgu)
        Expanded(
          child: GestureDetector(
            onTap: _captureFromCamera,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withAlpha(70),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt, color: AppColors.background, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'KAMERA İLE ÇEK',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.background,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. Galeri Butonu (Siber Cam Buton)
        Expanded(
          child: GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.neonBlue.withAlpha(120),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonBlue.withAlpha(25),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.photo_library,
                      color: AppColors.neonBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'GALERİDEN SEÇ',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neonBlue,
                      letterSpacing: 1.2,
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

  Widget _buildProcessingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gold.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(width: 14),
              Text(
                'MÜHÜRLEME PROTOKOLÜ ÇALIŞIYOR...',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontMono,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Yapay Zeka (CNN/ViT) ile Deepfake Taraması Yapılıyor\n2. SHA-256 Hash Hesaplanıp Hyperledger Fabric Ağına Mühürleniyor',
            style: TextStyle(
              fontFamily: AppTextStyles.fontMono,
              fontSize: 10,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          borderColor: AppColors.neonRed.withAlpha(80),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.neonRed, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İŞLEM HATASI',
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
        ),
        const SizedBox(height: AppSpacing.md),
        _buildResetButton(),
      ],
    );
  }

  Widget _buildResultSection() {
    return Column(
      children: [
        if (_result!.isFake)
          NeonResultCard(
            isAuthentic: false,
            title: '❌ MANİPÜLASYON TESPİT EDİLDİ',
            subtitle: 'Deepfake Tespit Edildi — Mühürleme Reddedildi',
            hashCode_: _result!.hashKodu,
            confidence: _result!.guvenOrani,
          )
        else if (_result!.isAuthentic)
          NeonResultCard(
            isAuthentic: true,
            title: '✅ GERÇEK VE ONAYLI',
            subtitle: 'Hyperledger Ağına Mühürlendi (SHA-256)',
            hashCode_: _result!.hashKodu,
            confidence: _result!.guvenOrani,
          )
        else
          NeonResultCard(
            isAuthentic: false,
            title: _result!.isSuccess ? '⚠️ ŞÜPHELİ / BELİRSİZ' : '❌ İŞLEM REDDEDİLDİ',
            subtitle: _result!.durum,
            hashCode_: _result!.hashKodu,
            confidence: _result!.guvenOrani,
          ),

        const SizedBox(height: AppSpacing.md),

        // Bu Hash'i Blokzincirde Doğrula / Sorgula Butonu
        if (_result!.hashKodu != null && widget.onNavigateToVerify != null) ...[
          GestureDetector(
            onTap: () => widget.onNavigateToVerify!(_result!.hashKodu!),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.neonBlue, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonBlue.withAlpha(40),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.manage_search_rounded,
                      color: AppColors.neonBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'BU HASH\'İ BLOKZİNCİRDE SORGULA',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.neonBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Yeni Mühürleme Yap
        _buildResetButton(),
      ],
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _reset,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        borderColor: AppColors.textMuted.withAlpha(40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.refresh, color: AppColors.textSecondary, size: 18),
            SizedBox(width: 8),
            Text(
              'YENİ FOTOĞRAF MÜHÜRLE',
              style: TextStyle(
                fontFamily: AppTextStyles.fontMono,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
