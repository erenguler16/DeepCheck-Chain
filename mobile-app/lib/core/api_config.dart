// API YAPILANDIRMASI – Ngrok üzerinden FastAPI haberleşme

class ApiConfig {
  ApiConfig._();

  /// Ngrok üzerinden erişilen FastAPI sunucu adresi.
  static const String baseUrl = 'https://promptly-handheld-pureblood.ngrok-free.dev';

  /// Tüm HTTP isteklerine eklenecek ortak header'lar.
  /// [ngrok-skip-browser-warning] → Ngrok uyarı sayfasını atlar.
  static const Map<String, String> defaultHeaders = {
    'ngrok-skip-browser-warning': 'true',
    'User-Agent': 'DeepCheckChain/2.0',
  };

  // ── Endpoint'ler ──

  /// Ana doğrulama ve mühürleme endpoint'i.
  /// Method: POST, Body: multipart/form-data (key: "file")
  static String get uploadMedia => '$baseUrl/upload-media';

  /// Sunucu sağlık kontrolü.
  /// Method: GET
  static String get healthCheck => baseUrl;

  /// Blokzinciri hash doğrulama.
  /// Method: GET, Path param: {file_hash}
  static String verifyMedia(String fileHash) =>
      '$baseUrl/verify-media/$fileHash';
}
