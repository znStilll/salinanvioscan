import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/scan_result.dart';
import '../../widgets/scan_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  RiskLevel? _filter;
  String _query = '';

  final _scans = const [
    {'date': '22 Okt 2026, 09:06', 'location': 'Left Forearm', 'risk': RiskLevel.low, 'confidence': 0.96},
    {'date': '21 Okt 2026, 14:22', 'location': 'Upper Back', 'risk': RiskLevel.medium, 'confidence': 0.82},
    {'date': '20 Okt 2026, 10:10', 'location': 'Right Cheek', 'risk': RiskLevel.low, 'confidence': 0.91},
    {'date': '19 Okt 2026, 08:28', 'location': 'Neck', 'risk': RiskLevel.low, 'confidence': 0.88},
    {'date': '18 Okt 2026, 11:12', 'location': 'Chest', 'risk': RiskLevel.high, 'confidence': 0.79},
    {'date': '17 Okt 2026, 15:30', 'location': 'Left Hand', 'risk': RiskLevel.low, 'confidence': 0.93},
    {'date': '16 Okt 2026, 09:15', 'location': 'Right Arm', 'risk': RiskLevel.medium, 'confidence': 0.84},
    {'date': '15 Okt 2026, 13:40', 'location': 'Shoulder', 'risk': RiskLevel.low, 'confidence': 0.95},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _scans.where((s) {
      final matchesRisk = _filter == null || s['risk'] == _filter;
      final matchesQuery = (s['location'] as String)
          .toLowerCase().contains(_query.toLowerCase());
      return matchesRisk && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B757B),
        elevation: 0,
        title: const Text(
          'Riwayat Skrining',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari riwayat skrining...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0A858C)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    isActive: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ...RiskLevel.values.map((r) => _FilterChip(
                    label: switch (r) {
                      RiskLevel.low => 'Rendah',
                      RiskLevel.medium => 'Sedang',
                      RiskLevel.high => 'Tinggi',
                      RiskLevel.critical => 'Kritis',
                    },
                    isActive: _filter == r,
                    onTap: () => setState(() => _filter = r),
                  )),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = filtered[i];
                return ScanCard(
                  date: s['date'] as String,
                  location: s['location'] as String,
                  riskLevel: s['risk'] as RiskLevel,
                  confidence: s['confidence'] as double,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A858C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
