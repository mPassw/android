import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:mpass/auth/login_page.dart';
import 'package:mpass/auth/register_page.dart';
import 'package:mpass/auth/server_url_page.dart';
import 'package:mpass/auth/unlock_page.dart';
import 'package:mpass/dashboard/dashboard.dart';
import 'package:mpass/dashboard/navigation/account/components/email_verification.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/dashboard/navigation/admin/state/admin_state.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:mpass/dashboard/navigation/import_export/state/export_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/autofill_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/hive/hive_registrar.g.dart';
import 'package:mpass/main_page.dart';
import 'package:mpass/service/network_service.dart';
import 'package:mpass/state/network_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

@pragma('vm:entry-point')
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapters();

  await setMaxRefreshRate();
  NetworkService().initialize();

  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  runAppWithHomePage(const MainPage());
}

@pragma('vm:entry-point')
Future<void> autofillMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapters();

  await setMaxRefreshRate();

  const platform = MethodChannel('com.example.mpass_autofill');

  platform.setMethodCallHandler((call) async {
    if (call.method == 'getPasswordsList') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final requestingPackage = args?['requestingPackage'] as String?;

      log("requestingPackage: $requestingPackage");

      final list = await PasswordsService.loadLocalPasswordList();

      return list
          .where(
              (e) => e.websites.any((w) => w.contains(requestingPackage ?? "")))
          .map((e) => {"id": e.id, "title": e.title})
          .toList();
    }
    if (call.method == 'showAutofill') {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final flutterEngineId = args?['flutterEngineId'] as String?;
      runAppWithHomePage(
          UnlockPage(flutterEngineId: flutterEngineId, isAutofill: true));
      return true;
    }
    if (call.method == "showAutosave") {
      final args = call.arguments as Map<dynamic, dynamic>?;
      final flutterEngineId = args?['flutterEngineId'] as String?;
      runAppWithHomePage(UnlockPage(
          flutterEngineId: flutterEngineId,
          isAutofill: true,
          isAutosave: true));
      return true;
    }
    return null;
  });
}

void runAppWithHomePage(Widget homePage) {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PasswordsState()),
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => AdminState()),
        ChangeNotifierProvider(create: (_) => PasswordsGeneratorState()),
        ChangeNotifierProvider(create: (_) => ExportState()),
        ChangeNotifierProvider(create: (_) => AutofillState()),
        ChangeNotifierProvider(create: (_) => NetworkState()),
      ],
      child: App(homePage: homePage),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key, required this.homePage});

  final Widget homePage;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme lightScheme =
            lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.blue);
        final ColorScheme darkScheme = darkDynamic ??
            ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 33, 150, 243),
                brightness: Brightness.dark);

        return MaterialApp(
            theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
            darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
            home: homePage,
            routes: {
              '/unlock': (context) => const UnlockPage(),
              '/server-url': (context) => const ServerUrlPage(),
              '/login': (context) => const Login(),
              '/register': (context) => const Register(),
              '/dashboard': (context) => const Dashboard(),
              '/verification': (context) => const EmailVerification(),
            });
      },
    );
  }
}

Future<void> setMaxRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {}
}
