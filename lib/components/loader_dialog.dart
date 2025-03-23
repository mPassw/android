import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingDialog {
  static bool _isDialogShowing =
      false;

  static Future<void> show(BuildContext context) async {
    if (_isDialogShowing) {
      return; 
    }
    _isDialogShowing = true;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/mPass_lottie_dark.json',
                  width: 200,
                  height: 200,
                  repeat: true,
                  reverse: false,
                  animate: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> hide(BuildContext context) async {
    if (_isDialogShowing) {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _isDialogShowing = false;
    }
  }
}
