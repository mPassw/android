import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_add_button.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_header.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_searchbar.dart';
import 'package:mpass/dashboard/navigation/passwords/components/passwords_list_widget.dart';
import 'package:mpass/dashboard/navigation/passwords/state/autofill_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:mpass/state/network_state.dart';
import 'package:provider/provider.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({super.key});

  @override
  State<PasswordsPage> createState() => _PasswordsPageState();
}

class _PasswordsPageState extends State<PasswordsPage> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final autofillState = Provider.of<AutofillState>(context, listen: false);
      bool isAutofill = autofillState.isAutofill;
      if (isAutofill) {
        await fetchPasswords();
      }
    });
  }

  Future<void> fetchPasswords() async {
    final passwordsState = Provider.of<PasswordsState>(context, listen: false);
    try {
      await passwordsState.fetchLocalPasswords();
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

  @override
  Widget build(BuildContext context) {
    final isAutofill = Provider.of<AutofillState>(context).isAutofill;
    final isConnected = Provider.of<NetworkState>(context).isConnected;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PasswordsSearchBar(isTrash: false),
            if (!isAutofill && isConnected) PasswordsAddButton(),
            PasswordsHeader(title: "Passwords", icon: Icons.password),
            PasswordListWidget(isTrash: false),
          ],
        ),
      ),
    );
  }
}
