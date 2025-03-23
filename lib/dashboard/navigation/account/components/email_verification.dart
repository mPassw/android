import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mpass/components/loader_dialog.dart';
import 'package:mpass/components/sonner.dart';
import 'package:mpass/dashboard/navigation/account/state/user_state.dart';
import 'package:mpass/service/http_service.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _sendOnInit();
    });
  }

  Future<void> _sendOnInit() async {
    try {
      UserState userState = Provider.of<UserState>(context, listen: false);
      if (userState.codeSent == false) {
        await userState.sendVerificationCode();
      }
    } catch (error) {
      log(error.toString());
      if (!mounted) return;
      if (error is CustomException) {
        HttpService.parseException(context, error);
      }
    }
  }

  Future<void> _verifyCode(String code) async {
    try {
      LoadingDialog.show(context);
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.verifyCode(code);
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(Sonner(message: "Verified"));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      if (error is CustomException) {
        HttpService.parseException(context, error);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(Sonner(message: "Failed to verify code"));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    UserState userState = Provider.of<UserState>(context, listen: false);
    final email = userState.user.email ?? "";

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: const Alignment(0.0, -0.5),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Email Verification",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the 6-digit code we sent to $email",
                      style: TextStyle(
                        color: onSurfaceColor.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Pinput(
                        onCompleted: (value) {
                          _verifyCode(value);
                        },
                        length: 6,
                        defaultPinTheme: PinTheme(
                            width: 40,
                            height: 40,
                            textStyle: TextStyle(
                                fontSize: 20,
                                color: onSurfaceColor,
                                fontWeight: FontWeight.w600),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: onSurfaceColor,
                                  width: 1.0,
                                ),
                              ),
                            ))),
                    const SizedBox(height: 28),
                    Text("Didn't receive the code?",
                        style: TextStyle(
                          color: onSurfaceColor.withValues(alpha: 0.7),
                        )),
                    TextButton(
                      onPressed: () {
                        userState.sendCode(
                            context, userState.sendVerificationCode);
                      },
                      child: const Text("Resend"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
