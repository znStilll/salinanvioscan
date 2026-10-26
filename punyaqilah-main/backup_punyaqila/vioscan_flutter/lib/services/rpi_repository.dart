// lib/services/rpi_repository.dart
import 'dart:async';
import 'bluetooth_service.dart';
import '../models/scan_result.dart';

class RPiRepository {
  final BluetoothService _bt;
  final StreamController<ScanResult> _resultController;
  final StreamController<String> _statusController;
  StreamSubscription<ScanResult>? _sub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<String>? _statusSub;
  
  RPiRepository(this._bt)
      : _resultController = StreamController<ScanResult>.broadcast(),
        _statusController = StreamController<String>.broadcast() {
    _sub = _bt.resultsStream.listen(_resultController.add);
    _connSub = _bt.connectionStateStream.listen(_onConnectionState);
    _statusSub = _bt.scanProgressStream.listen(_statusController.add);
  }
  
  Stream<ScanResult> get resultsStream => _resultController.stream;
  Stream<String> get statusStream => _statusController.stream;
  
  void _onConnectionState(BluetoothConnectionState state) {
    if (state == BluetoothConnectionState.connected) {
      _statusController.add('Connected to BCcare RPi');
    } else if (state == BluetoothConnectionState.disconnected) {
      _statusController.add('Disconnected from BCcare RPi');
    }
  }
  
  Future<void> connect() async {
    await _bt.scanAndConnect();
  }
  
  void requestLatest() => _bt.requestLatest();
  void requestAll() => _bt.requestAll();
  
  bool get isPaired => _bt.isConnected;
  
  void dispose() {
    _sub?.cancel();
    _connSub?.cancel();
    _statusSub?.cancel();
    _resultController.close();
    _statusController.close();
  }
}

