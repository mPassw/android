import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpass/components/sonner.dart';

class CustomUtils {
  static String truncateString(String text, int maxLength) {
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength)}...';
    } else {
      return text;
    }
  }

  static String getDomainFromUrl(String url) {
    if (url.isEmpty) {
      return "";
    }

    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = "https://$url";
    }

    try {
      Uri uri = Uri.parse(url);
      String? host = uri.host;

      if (host.isEmpty) {
        return "";
      }

      List<String> parts = host.split('.');
      if (parts.length >= 2) {
        // Improved TLD extraction (handles co.uk, etc.)
        int tldLength = _getTldLength(parts);
        if (parts.length > tldLength) {
          return parts
              .sublist(parts.length - tldLength, parts.length)
              .join('.');
        } else {
          return host; // Just the host if no proper TLD
        }
      } else {
        return host;
      }
    } catch (e) {
      log(e.toString());
      return ""; // Or throw if you want to signal an error
    }
  }

  static int _getTldLength(List<String> parts) {
    // Simple TLD check (can be expanded with a more comprehensive list)
    String lastPart = parts.last;
    if (lastPart.length == 2 ||
        lastPart == "com" ||
        lastPart == "net" ||
        lastPart == "org") {
      return 2; // Most common cases like .com, .uk, .co.uk
    } else if (lastPart.length == 3) {
      //Example .info
      return 2;
    } else {
      return 1; //fallback to just the last part
    }
  }

  static void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(Sonner(message: "Copied to clipboard"));
  }

  static bool isValidEmail(String email) {
    final RegExp emailRegExp =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegExp.hasMatch(email);
  }
}
