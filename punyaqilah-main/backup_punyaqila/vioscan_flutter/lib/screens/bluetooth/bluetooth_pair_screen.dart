import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/bluetooth_service.dart';
import '../../models/scan_result.dart';

class BluetoothPairScreen extends StatefulWidget {
  const BluetoothPairScreen({super.key});

  @override
  State<BluetoothPairScreen> createState() => _BluetoothPairScreenState();
}

class _BluetoothPairScreenState extends State<BluetoothPairScreen> {
  final BluetoothService _service = BluetoothService();

  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<String>? _progressSub;
  StreamSubscription<ScanResult>? _resultSub;

  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  String _status = 'Menunggu koneksi';
  String _progress = '';
  ScanResult? _result;
  bool _busy = false;

  bool get _connected =>
      _state == BluetoothConnectionState.connected;

  @override
  void initState() {
    super.initState();

    _state = _service.isConnected
        ? BluetoothConnectionState.connected
        : BluetoothConnectionState.disconnected;

    _connSub = _service.connectionStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _state = state;
        _status = state == BluetoothConnectionState.connected
            ? 'Terhubung ke BC-Care'
            : state == BluetoothConnectionState.connecting
                ? 'Menghubungkan...'
                : 'Terputus';
      });
    });

    _progressSub = _service.scanProgressStream.listen((message) {
      if (!mounted) return;
      setState(() => _progress = message);
    });

    _result = BluetoothService.lastResult;
    _resultSub = _service.resultsStream.listen((result) {
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = 'Pemindaian selesai';
      });
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _progressSub?.cancel();
    _resultSub?.cancel();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.scanAndConnect();
    } catch (e) {
      if (mounted) setState(() => _progress = 'Koneksi gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startScan() async {
    if (!_connected || _busy) return;
    setState(() => _busy = true);
    try {
      await _service.prepareScanCommand(mode: 'uv');
      setState(() => _progress = 'Menunggu alat siap...');
    } catch (e) {
      if (mounted) setState(() => _progress = 'Gagal menyiapkan scan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runScan() async {
    if (!_connected || _busy) return;
    setState(() => _busy = true);
    try {
      await _service.startScanCommand(mode: 'uv');
    } catch (e) {
      if (mounted) setState(() => _progress = 'Scan gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BC-Care Bluetooth'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_status, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_progress.isEmpty ? 'Siapkan perangkat Raspberry Pi.' : _progress),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _connect,
                      child: Text(_connected ? 'Sudah Terhubung' : 'Hubungkan BC-Care'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _connected && !_busy ? _startScan : null,
                      child: const Text('Siapkan Scan UV'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _connected && _service.isScanReady && !_busy
                          ? _runScan
                          : null,
                      child: const Text('Mulai Scan'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _connected && !_busy
                        ? () async {
                            await _service.disconnect();
                          }
                        : null,
                    child: const Text('Putuskan Koneksi'),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text(_result!.rpiDisease ?? _result!.conditionLabel),
                subtitle: Text(
                  'Risiko: ${_result!.riskLabel}\n'
                  'Confidence: ${(_result!.confidenceScore * 100).toStringAsFixed(1)}%',
                ),
                isThreeLine: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

