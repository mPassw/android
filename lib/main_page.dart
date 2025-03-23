import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mpass/auth/login_page.dart';
import 'package:mpass/auth/server_url_page.dart';
import 'package:mpass/auth/service/authorization_service.dart';
import 'package:mpass/auth/unlock_page.dart';
import 'package:mpass/state/network_state.dart';
import 'package:mpass/state/secure_storage.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final secureStorage = SecureStorage.instance;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        checkConnection();
        await checkSavedData(secureStorage);
        if (mounted) {
          final networkState =
              Provider.of<NetworkState>(context, listen: false);
          if (networkState.isConnected) {
            await checkServerUrl(secureStorage);
          }
        }

        FlutterNativeSplash.remove();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UnlockPage()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        log(e.toString());
      }
    });
  }

  void checkConnection() async {
    final networkState = Provider.of<NetworkState>(context, listen: false);
    networkState.listenToConnectivityChanges();
  }

  Future<void> checkServerUrl(SecureStorage secureStorage) async {
    try {
      final String serverUrl = await secureStorage.getServerUrl();
      await AuthorizationService.validateServer(serverUrl);
    } catch (e) {
      log(e.toString());
      FlutterNativeSplash.remove();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ServerUrlPage()),
        (Route<dynamic> route) => false,
      );
      rethrow;
    }
  }

  Future<void> checkSavedData(SecureStorage secureStorage) async {
    try {
      await secureStorage.getDerivedKey();
      await secureStorage.getEmail();
    } catch (e) {
      log(e.toString());
      FlutterNativeSplash.remove();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ServerUrlPage()),
        (Route<dynamic> route) => false,
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
