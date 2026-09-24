class AnalysisResult {
  final String durum;
  final String? hashKodu;
  final String? dosyaAdi;
  final String? aiSonucu;
  final String? zaman;
  final String? detay;
  final String? guvenOrani;

  const AnalysisResult({
    required this.durum,
    this.hashKodu,
    this.dosyaAdi,
    this.aiSonucu,
    this.zaman,
    this.detay,
    this.guvenOrani,
  });

  /// Backend'den gelen JSON'u parse et.
  /// API birden fazla key formatı döndürebilir, hepsini handle ediyoruz.
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      durum: json['durum'] as String? ?? 'Bilinmeyen durum',
      hashKodu: json['hash_kodu'] as String?,
      dosyaAdi: json['dosya_adi'] as String?,
      aiSonucu: json['ai_sonucu'] as String? ??
          json['ai_analiz_sonucu'] as String?,
      zaman: json['zaman'] as String? ?? json['timestamp'] as String?,
      detay: json['detay'] as String?,
      guvenOrani: json['ai_guven_orani'] as String?,
    );
  }

  /// Sonuç başarılı mı? (Blokzincire yazıldı mı?)
  bool get isSuccess => durum.contains('BAŞARILI') || durum.contains('BASARILI');

  /// AI analizi "Gerçek" mi döndü?
  bool get isAuthentic {
    final s = aiSonucu?.toLowerCase().trim() ?? '';
    return s.contains('gercek') ||
        s.contains('gerçek') ||
        s.contains('authentic') ||
        s.contains('real');
  }

  /// AI analizi "Sahte" mi döndü?
  bool get isFake {
    final s = aiSonucu?.toLowerCase().trim() ?? '';
    return s.contains('sahte') || s.contains('fake');
  }
}

/// Blokzinciri doğrulama sorgusunun sonucu.
class VerifyResult {
  final String durum;
  final String? mesaj;
  final Map<String, dynamic>? veri;
  final String? detay;

  const VerifyResult({
    required this.durum,
    this.mesaj,
    this.veri,
    this.detay,
  });

  factory VerifyResult.fromJson(Map<String, dynamic> json) {
    return VerifyResult(
      durum: json['durum'] as String? ?? 'Bilinmeyen durum',
      mesaj: json['mesaj'] as String? ?? json['message'] as String?,
      veri: json['veri'] as Map<String, dynamic>? ??
          json['data'] as Map<String, dynamic>?,
      detay: json['detay'] as String? ?? json['detail'] as String?,
    );
  }

  /// Blokzincirinde kayıtlı ve doğrulanmış mı?
  bool get isRegistered {
    final d = durum.toUpperCase();
    return d.contains('DOĞRULANDI') ||
        d.contains('DOGRULANDI') ||
        d.contains('KAYITLI') ||
        d.contains('BAŞARILI') ||
        d.contains('BASARILI');
  }

  /// Blokzincirinde bulunamadı / kayıtsız mı?
  bool get isNotRegistered {
    final d = durum.toUpperCase();
    return d.contains('BULUNAMADI') ||
        d.contains('KAYITSIZ') ||
        d.contains('GEÇERSİZ') ||
        d.contains('GECERSIZ') ||
        !isRegistered;
  }

  /// Blokzinciri kaydındaki AI sonucu (camelCase veya snake_case desteği)
  String? get aiResult {
    if (veri == null) return null;
    return veri!['aiResult'] as String? ??
        veri!['ai_result'] as String? ??
        veri!['aiSonucu'] as String? ??
        veri!['ai_sonucu'] as String? ??
        veri!['ai_analiz_sonucu'] as String?;
  }

  /// AI analizi "Sahte" (Deepfake) mi?
  bool get isFake {
    final ai = aiResult?.toLowerCase().trim() ?? '';
    return ai.contains('sahte') || ai.contains('fake');
  }

  /// AI analizi "Gerçek" mi?
  bool get isAuthentic {
    final ai = aiResult?.toLowerCase().trim() ?? '';
    return ai.contains('gercek') ||
        ai.contains('gerçek') ||
        ai.contains('real') ||
        ai.contains('authentic');
  }

  bool get isFound => isRegistered;
  bool get isNotFound => isNotRegistered;
}
