import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkService {
  // Private constructor
  NetworkService._();

  // Singleton instance
  static final NetworkService _instance = NetworkService._();

  // Factory constructor to return the same instance
  factory NetworkService() => _instance;

  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;

  // Stream controller to broadcast connectivity changes
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Initialize method to be called once at app startup
  void initialize() {
    // Initial check
    _checkConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _handleConnectivityChange(results);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _isConnected = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
    _connectionStatusController.add(_isConnected);
  }

  bool get isConnected => _isConnected;

  void dispose() {
    _connectionStatusController.close();
  }
}
