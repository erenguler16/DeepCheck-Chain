import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/api_config.dart';
import '../services/api_service.dart';
import '../widgets/radar_painter.dart';
import '../widgets/glass_card.dart';

// Sistem Durumu – Radar ve Ağ Doğrulama

class SystemStatusScreen extends StatefulWidget {
  const SystemStatusScreen({super.key});

  @override
  State<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends State<SystemStatusScreen> {
  bool _isChecking = false;
  HealthStatus? _healthStatus;
  int _responseTimeMs = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);

    final stopwatch = Stopwatch()..start();

    try {
      final status = await ApiService.checkHealth();
      stopwatch.stop();

      if (mounted) {
        setState(() {
          _healthStatus = HealthStatus(
            isOnline: status.isOnline,
            message: status.message,
            responseTimeMs: stopwatch.elapsedMilliseconds,
          );
          _responseTimeMs = stopwatch.elapsedMilliseconds;
          _isChecking = false;
        });
      }
    } catch (e) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _healthStatus = HealthStatus(
            isOnline: false,
            message: 'Bağlantı hatası',
            responseTimeMs: stopwatch.elapsedMilliseconds,
          );
          _responseTimeMs = stopwatch.elapsedMilliseconds;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = _healthStatus?.isOnline ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Radar widget
          RadarWidget(
            size: 200,
            isOnline: isOnline,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Ana durum kartı
          GlassCard(
            borderColor: isOnline
                ? AppColors.neonGreen.withAlpha(40)
                : AppColors.neonRed.withAlpha(40),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Durum başlığı
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppColors.neonGreen
                            : AppColors.neonRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline
                                    ? AppColors.neonGreen
                                    : AppColors.neonRed)
                                .withAlpha(100),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isOnline
                          ? 'TÜM SİSTEMLER AKTİF'
                          : 'BAĞLANTI KESİK',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isOnline
                            ? AppColors.neonGreen
                            : AppColors.neonRed,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                if (_healthStatus?.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _healthStatus!.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Detay durumlar
          _buildStatusRow(
            icon: Icons.api,
            label: 'API BAĞLANTISI',
            status: isOnline ? 'AKTİF' : 'ÇEVRİMDIŞI',
            isActive: isOnline,
            detail: _responseTimeMs > 0 ? '${_responseTimeMs}ms' : null,
          ),

          _buildStatusRow(
            icon: Icons.link,
            label: 'HYPERLEDGER AĞI',
            status: isOnline ? 'BAĞLI' : 'BAĞLANTI YOK',
            isActive: isOnline,
          ),

          _buildStatusRow(
            icon: Icons.psychology,
            label: 'AI MOTORU (CNN/ViT)',
            status: isOnline ? 'HAZIR' : 'ERİŞİLEMİYOR',
            isActive: isOnline,
          ),

          _buildStatusRow(
            icon: Icons.security,
            label: 'SIFIR GÜVEN PROTOKOLÜ',
            status: 'AKTİF',
            isActive: true,
          ),

          _buildStatusRow(
            icon: Icons.enhanced_encryption,
            label: 'SHA-256 HASH MOTORU',
            status: 'AKTİF',
            isActive: true,
          ),

          const SizedBox(height: AppSpacing.md),

          // Sunucu Hedef Kartı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.gold.withAlpha(30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.dns_outlined, color: AppColors.gold, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUNUCU HEDEFİ (NGROK)',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontMono,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ApiConfig.baseUrl,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontMono,
                          fontSize: 10,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Yenile butonu
          GestureDetector(
            onTap: _isChecking ? null : _checkStatus,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 14),
              borderColor: AppColors.gold.withAlpha(40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isChecking)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  else
                    Icon(Icons.refresh, color: AppColors.gold, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _isChecking ? 'KONTROL EDİLİYOR...' : 'AĞI TARA',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1,
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

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String status,
    required bool isActive,
    String? detail,
  }) {
    final Color statusColor =
        isActive ? AppColors.neonGreen : AppColors.neonRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: statusColor.withAlpha(15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: statusColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontMono,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (detail != null)
                    Text(
                      detail,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontMono,
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: statusColor.withAlpha(40),
                ),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontMono,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
