import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/analysis_result.dart';

// API SERVİS KATMANI

class ApiService {
  ApiService._();

  /// Fotoğrafı sunucuya gönder → AI analizi + Blokzinciri mühürleme.
  /// [POST /upload-media] multipart/form-data, key: "file"
  static Future<AnalysisResult> uploadMedia(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.uploadMedia),
    );

    // Ngrok header'ları
    request.headers.addAll(ApiConfig.defaultHeaders);

    // Dosyayı multipart olarak ekle
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes));
      return AnalysisResult.fromJson(data);
    } else {
      throw ApiException(
        'Sunucu hatası: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  /// Sunucu sağlık kontrolü.
  /// [GET /]
  static Future<HealthStatus> checkHealth() async {
    try {
      final url = ApiConfig.healthCheck;
      final uri = Uri.parse(url.endsWith('/') ? url : '$url/');

      final response = await http
          .get(
            uri,
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String message = 'Sunucu aktif ve hazır';
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map) {
            message = decoded['mesaj'] as String? ??
                decoded['message'] as String? ??
                decoded['status'] as String? ??
                'Sunucu aktif';
          } else if (decoded is List && decoded.isNotEmpty) {
            message = decoded.first.toString();
          } else if (decoded is String && decoded.isNotEmpty) {
            message = decoded;
          }
        } catch (_) {
          final raw = utf8.decode(response.bodyBytes).trim();
          if (raw.isNotEmpty && !raw.startsWith('<')) {
            message = raw;
          }
        }

        return HealthStatus(
          isOnline: true,
          message: message,
          responseTimeMs: 0, // will be set by caller
        );
      }
      return HealthStatus(
        isOnline: false,
        message: 'HTTP ${response.statusCode}: Sunucu yanıt vermedi',
      );
    } catch (e) {
      return HealthStatus(
        isOnline: false,
        message: 'Bağlantı hatası: $e',
      );
    }
  }

  /// Blokzinciri hash doğrulama.
  /// [GET /verify-media/{file_hash}]
  static Future<VerifyResult> verifyMedia(String fileHash) async {
    final cleanHash = fileHash.trim();
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.verifyMedia(cleanHash)),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        return VerifyResult.fromJson(data);
      } else if (response.statusCode == 404) {
        // Backend hash bulunamadığında 404 döner
        try {
          final Map<String, dynamic> data =
              jsonDecode(utf8.decode(response.bodyBytes));
          return VerifyResult.fromJson(data);
        } catch (_) {
          return const VerifyResult(
            durum: 'BULUNAMADI',
            mesaj: 'Kayıt bulunamadı. Bu hash kodu blokzincirinde mühürlü değil (Kayıtsız).',
          );
        }
      } else {
        throw ApiException(
          'Doğrulama sunucu hatası: HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Ağ bağlantı hatası: $e');
    }
  }
}

/// Sunucu sağlık durumu modeli.
class HealthStatus {
  final bool isOnline;
  final String message;
  final int responseTimeMs;

  const HealthStatus({
    required this.isOnline,
    required this.message,
    this.responseTimeMs = 0,
  });
}

/// API istisna sınıfı.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
