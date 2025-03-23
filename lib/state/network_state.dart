import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mpass/service/network_service.dart';

class NetworkState extends ChangeNotifier {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  void setIsConnected(bool newValue) {
    _isConnected = newValue;
    notifyListeners();
  }

  void listenToConnectivityChanges() {
    final networkService = NetworkService();
    networkService.connectionStatus.listen((isConnected) {
      setIsConnected(isConnected);
    });
  }
}
