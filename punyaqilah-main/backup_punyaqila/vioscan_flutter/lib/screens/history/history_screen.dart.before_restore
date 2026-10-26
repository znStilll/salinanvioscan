// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/scan_result.dart';
import '../../services/scan_history_service.dart';
import '../../widgets/scan_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  RiskLevel? _filter;

  List<ScanResult> _scans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final results = await ScanHistoryService.getAll();
      if (!mounted) return;
      setState(() {
        _scans = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? _scans
        : _scans.where((s) => s.riskLevel == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Scan History')),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isActive: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ...RiskLevel.values.map((r) => _FilterChip(
                        label: r.name.capitalize(),
                        isActive: _filter == r,
                        onTap: () => setState(() => _filter = r),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = filtered[i];
                return ScanCard(
                  date: s.scannedAt.toLocal().toString().substring(0, 16),
                  location: s.bodyLocation.isEmpty ? 'Lokasi tidak dicatat' : s.bodyLocation,
                  riskLevel: s.riskLevel,
                  confidence: s.confidenceScore,
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
  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}




