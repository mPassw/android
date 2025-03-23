import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/admin/model/smtp_settings.dart';
import 'package:mpass/dashboard/navigation/admin/state/admin_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:provider/provider.dart';

class SmtpSettingsDialogContent extends StatefulWidget {
  const SmtpSettingsDialogContent({super.key});

  @override
  State<SmtpSettingsDialogContent> createState() =>
      _SmtpSettingsDialogContentState();
}

class _SmtpSettingsDialogContentState extends State<SmtpSettingsDialogContent> {
  bool _obscureText = true;
  bool _sslSwitch = false;

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _senderController = TextEditingController();
  final TextEditingController _smtpUsernameController = TextEditingController();
  final TextEditingController _smtpPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        LoadingDialog.show(context);
        await fetchSMTPSettings();
        _fillSmtpSettings();
      } catch (error) {
        if (error is Exception && mounted) {
          HttpService.parseException(context, error);
        }
      } finally {
        if (mounted) {
          LoadingDialog.hide(context);
        }
      }
    });
  }

  void _fillSmtpSettings() {
    final adminState = Provider.of<AdminState>(context, listen: false);
    setState(() {
      _hostController.text = adminState.smtpSettings.host ?? '';
      _portController.text = adminState.smtpSettings.port != null
          ? "${adminState.smtpSettings.port}"
          : '';
      _senderController.text = adminState.smtpSettings.sender ?? '';
      _smtpUsernameController.text = adminState.smtpSettings.username ?? '';
      _smtpPasswordController.text = adminState.smtpSettings.password ?? '';
      _sslSwitch = adminState.smtpSettings.ssl ?? false;
    });
  }

  Future<void> fetchSMTPSettings() async {
    try {
      final adminState = Provider.of<AdminState>(context, listen: false);
      await adminState.fetchSMTPSettings();
    } catch (error) {
      if (!mounted) return;
      if (error is Exception) HttpService.parseException(context, error);
    }
  }

  Future<void> _saveSettings() async {
    try {
      LoadingDialog.show(context);
      final adminState = Provider.of<AdminState>(context, listen: false);
      final smtpSettings = SMTPSettings(
        host: _hostController.text,
        port: int.parse(_portController.text),
        sender: _senderController.text,
        username: _smtpUsernameController.text,
        password: _smtpPasswordController.text,
        ssl: _sslSwitch,
      );
      await adminState.updateSMTPSettings(smtpSettings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(Sonner(message: "Saved"));
    } catch (error) {
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(Sonner(message: "Failed to save smtp settings"));
      }
    } finally {
      LoadingDialog.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'SMTP Settings',
            style: TextStyle(fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            // Added Padding for better spacing in fullscreen dialog
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _hostController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.dns_outlined),
                      border: OutlineInputBorder(),
                      labelText: "Host",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.pin_outlined),
                      border: OutlineInputBorder(),
                      labelText: "Port",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _senderController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                      labelText: "Sender Email",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _smtpUsernameController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_circle_outlined),
                      border: OutlineInputBorder(),
                      labelText: "SMTP Username",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _smtpPasswordController,
                    obscureText: _obscureText,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "SMTP Password",
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        "SSL",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                        value: _sslSwitch,
                        onChanged: (newValue) {
                          setState(() {
                            _sslSwitch = newValue;
                          });
                        }),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                      onPressed: () {
                        _saveSettings();
                      },
                      label: const Text("Save"),
                      icon: const Icon(Icons.save_outlined)),
                )
              ],
            ),
          ),
        ));
  }
}
