// lib/screens/scan/scan_result_screen.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../models/scan_result.dart';
import '../../widgets/risk_badge.dart';
import '../../services/bluetooth_service.dart';

class ScanResultScreen extends StatelessWidget {
  final String scanId;

  const ScanResultScreen({super.key, required this.scanId});

  ScanResult _demoResult() => ScanResult(
        id: scanId,
        scannedAt: DateTime.now(),
        imageUrl: '',
        uvImageUrl: '',
        riskLevel: RiskLevel.low,
        confidenceScore: 0.94,
        condition: SkinCondition.benign,
        detectedRegions: const [],
        bodyLocation: 'Left Forearm',
        source: 'flutter',
        mode: 'white',
      );

  @override
  Widget build(BuildContext context) {
    // Prioritaskan hasil dari Raspberry Pi.
    final result = BluetoothService.lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Results'),
          leading: IconButton(
            onPressed: () => context.go('/bluetooth'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Belum ada hasil pemindaian dari Raspberry Pi. '
              'Hubungkan perangkat dan jalankan pemindaian terlebih dahulu.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Results'),
        leading: IconButton(
          onPressed: () => context.go('/bluetooth'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResultHeroCard(result: result),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ConfidenceBar(
                  confidence: result.confidenceScore
                      .clamp(0.0, 1.0)
                      .toDouble(),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ImageSection(result: result),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DetailSection(result: result),
              ),
              if (result.ultrasonic != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _UltrasonicSection(
                    ultrasonic: result.ultrasonic!,
                  ),
                ),
              ],
              if ((result.probabilities?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ProbabilitiesSection(
                    probabilities: result.probabilities!,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _RecommendationSection(
                  riskLevel: result.riskLevel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeroCard extends StatelessWidget {
  final ScanResult result;

  const _ResultHeroCard({required this.result});

  Color get _riskColor {
    switch (result.riskLevel) {
      case RiskLevel.low:
        return AppColors.riskLow;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.critical:
        return AppColors.riskCritical;
    }
  }

  String get _diseaseLabel {
    if (result.rpiDisease != null) {
      return result.rpiDisease == 'BCC'
          ? 'Basal Cell Carcinoma'
          : result.rpiDisease == 'NORMAL'
              ? 'Normal Skin Tissue'
              : result.rpiDisease!;
    }
    return result.conditionLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _riskColor.withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _riskColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  result.riskLevel == RiskLevel.low
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: _riskColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiskBadge(riskLevel: result.riskLevel),
                    const SizedBox(height: 4),
                    Text(
                      _diseaseLabel,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (result.mode != null && result.source == 'rpi')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Captured via BC-Care device Â· '
                          '${result.mode!.toUpperCase()} mode',
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _riskColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              result.riskLevel == RiskLevel.low
                  ? 'No suspicious signs were reported by the current scan. '
                      'This result is not a medical diagnosis; consult a '
                      'qualified clinician if a lesion changes or concerns you.'
                  : 'Potentially suspicious regions were reported. '
                      'Please consult a dermatologist for professional '
                      'evaluation.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;

  const _ConfidenceBar({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final safeConfidence = confidence.clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'AI Confidence Score',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(safeConfidence * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: safeConfidence,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final ScanResult result;

  const _DetailSection({required this.result});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'label': 'Scan Date',
        'value':
            '${result.scannedAt.day}/${result.scannedAt.month}/${result.scannedAt.year} '
                '${result.scannedAt.hour}:'
                '${result.scannedAt.minute.toString().padLeft(2, '0')}',
      },
      {
        'label': 'Scan Source',
        'value':
            result.source == 'rpi' ? 'BC-Care Device (RPi)' : 'Phone Camera',
      },
      {
        'label': 'Scan Type',
        'value': result.mode == 'uv' ? 'UV Fluorescence' : 'White Dermoscopy',
      },
      {
        'label': 'Model',
        'value': 'EfficientNetB3 (BCCare)',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 94,
                      child: Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['value']!,
                        textAlign: TextAlign.end,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final ScanResult result;

  const _ImageSection({required this.result});

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    final b64 = result.imageBase64 ?? BluetoothService.lastImageB64;

    if (b64 != null && b64.isNotEmpty) {
      try {
        imageBytes = base64Decode(b64);
      } catch (_) {
        imageBytes = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Captured Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (result.mode != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: result.mode == 'uv'
                      ? const Color(0xFF0A0020)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.mode!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: result.mode == 'uv'
                        ? AppColors.uvCyan
                        : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: result.mode == 'uv'
                ? const Color(0xFF0A0020)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: imageBytes != null
              ? Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Gambar tidak dapat ditampilkan'),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: result.mode == 'uv'
                            ? AppColors.uvCyan.withValues(alpha: 0.5)
                            : AppColors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.source == 'rpi'
                            ? 'Waiting for image transfer...'
                            : 'No image available',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: result.mode == 'uv'
                              ? AppColors.uvCyan.withValues(alpha: 0.6)
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _UltrasonicSection extends StatelessWidget {
  final UltrasonicData ultrasonic;

  const _UltrasonicSection({required this.ultrasonic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ultrasonic Measurement',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Reference',
                  '${ultrasonic.jarakReferensi.toStringAsFixed(1)} mm',
                ),
              ),
              Expanded(
                child: _metric(
                  'Lesion',
                  '${ultrasonic.jarakLesi.toStringAsFixed(1)} mm',
                ),
              ),
              Expanded(
                child: _metric(
                  'Delta',
                  '${ultrasonic.selisih.toStringAsFixed(1)} mm',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProbabilitiesSection extends StatelessWidget {
  final Map<String, double> probabilities;

  const _ProbabilitiesSection({required this.probabilities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Class Probabilities',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...probabilities.entries.map(
            (e) {
              final value = e.value.clamp(0.0, 1.0).toDouble();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        e.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            e.key.toUpperCase() == 'BCC'
                                ? AppColors.riskHigh
                                : AppColors.riskLow,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(value * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  final RiskLevel riskLevel;

  const _RecommendationSection({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final recs = riskLevel == RiskLevel.low
        ? [
            'Continue monthly self-examinations',
            'Apply SPF 30+ sunscreen daily',
            'Schedule annual professional skin check',
            'Avoid peak UV hours (10am â€“ 4pm)',
          ]
        : [
            'Consult a dermatologist for evaluation',
            'Avoid UV exposure on affected area',
            'Document any changes with photos',
            'Do not scratch or irritate the lesion',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...recs.map(
          (rec) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rec,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
