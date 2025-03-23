import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/components/warning_card.dart';
import 'package:mpass/dashboard/navigation/account/components/email_verification.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/dashboard/navigation/admin/admin_page.dart';
import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/dashboard/navigation/trash/trash_page.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/network_state.dart';
import 'navigation/account/account_page.dart';
import 'navigation/generator/generator_page.dart';
import 'navigation/import_export/import_export_page.dart';
import 'navigation/passwords/passwords_page.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  bool _isAdminMode = false;
  bool _isAdminVisible = false;

  // Modified to become dynamic based on connection status
  List<NavigationDestination> _getDestinations(bool isConnected) {
    final List<NavigationDestination> destinations = <NavigationDestination>[
      const NavigationDestination(
          icon: Icon(Icons.password), label: "Passwords"),
      const NavigationDestination(icon: Icon(Icons.delete), label: "Trash"),
      const NavigationDestination(
          icon: Icon(Icons.sync_alt), label: "Import/Export"),
      const NavigationDestination(icon: Icon(Icons.key), label: "Generator"),
    ];

    // Only add Account page when connected
    if (isConnected) {
      destinations.add(const NavigationDestination(
          icon: Icon(Icons.account_circle), label: "Account"));
    }

    return destinations;
  }

  // Dynamic pages based on connection status
  List<Widget> _getPages(bool isConnected) {
    final List<Widget> pages = <Widget>[
      const PasswordsPage(),
      const TrashPage(),
      const ImportExportPage(),
      const GeneratorPage(),
    ];

    if (isConnected) {
      pages.add(const AccountPage());
    }

    return pages;
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    try {
      await Future.wait([
        fetchPasswords(),
        fetchUser(),
        loadWords(),
      ]).then((_) => generatePasswords());
    } catch (error) {
      if (!mounted) return;
    }
  }

  Future<void> loadWords() async {
    try {
      final passwordsGeneratorState =
          Provider.of<PasswordsGeneratorState>(context, listen: false);
      await passwordsGeneratorState.loadWordList();
    } catch (error) {}
  }

  void generatePasswords() {
    try {
      final passwordsGeneratorState =
          Provider.of<PasswordsGeneratorState>(context, listen: false);
      final userState = Provider.of<UserState>(context, listen: false);
      String email = userState.user.email ?? "";
      passwordsGeneratorState.initializeGeneratedValues(email);
    } catch (error) {}
  }

  Future<void> fetchPasswords() async {
    final passwordsState = Provider.of<PasswordsState>(context, listen: false);
    try {
      final networkState = Provider.of<NetworkState>(context, listen: false);
      if (networkState.isConnected) {
        await passwordsState.fetchPasswords();
      } else {
        await passwordsState.fetchLocalPasswords();
      }
    } catch (error) {
      if (!mounted) return;
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to fetch passwords"));
      }
    } finally {
      passwordsState.setIsLoading(false);
    }
  }

  Future<void> fetchUser() async {
    try {
      final networkState = Provider.of<NetworkState>(context, listen: false);
      final userState = Provider.of<UserState>(context, listen: false);
      if (networkState.isConnected) {
        await userState.fetchUser();
      }
    } catch (error) {
      if (!mounted) return;
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to fetch user"));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserState>(context);
    final networkState = Provider.of<NetworkState>(context);
    final isAdmin = userState.user.admin;
    final isVerified = userState.user.verified;
    final isConnected = networkState.isConnected;

    final destinations = _getDestinations(isConnected);
    final pages = _getPages(isConnected);

    if (!isConnected && _selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    if (isAdmin == true) {
      _isAdminVisible = true;
    }

    return SafeArea(
        child: Scaffold(
      floatingActionButton: Visibility(
        visible: (_isAdminVisible && !_isAdminMode && isConnected),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _isAdminMode = true;
            });
          },
          child: const Icon(Icons.build),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      bottomNavigationBar: NavigationBar(
        destinations: destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _isAdminMode = false;
          });
        },
      ),
      body: Column(
        children: [
          if (!isConnected)
            WarningCard(label: "Offline Mode", icon: Icons.wifi_off),
          if (isVerified == false && isConnected)
            InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EmailVerification()));
                },
                child: WarningCard(label: "Email is not verified")),
          Expanded(
            child: _isAdminMode ? const AdminPage() : pages[_selectedIndex],
          ),
        ],
      ),
    ));
  }
}
