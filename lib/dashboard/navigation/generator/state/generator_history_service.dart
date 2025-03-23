import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:mpass/dashboard/navigation/generator/state/passwords_generator_state.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';
import 'package:mpass/state/secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class GeneratorHistoryService {
  static final String _fileName = 'generatedHistory.json';

  static Future<void> addToHistoryFile(GeneratedValue generatedValue) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        String fileContents = await file.readAsString();

        List<dynamic> jsonList = jsonDecode(fileContents);

        List<GeneratedValue> generatedHistory = jsonList
            .map((jsonItem) => GeneratedValue.fromJson(jsonItem))
            .toList();

        if (generatedHistory.length >= 100) {
          generatedHistory.removeAt(0);
        }

        GeneratedValue encryptedValue = generatedValue.copy();
        if (generatedValue.decrypted == true) {
          encryptedValue = await encryptGeneratedValue(generatedValue);
        }

        generatedHistory.add(encryptedValue);

        List<Map<String, dynamic>> updatedJsonList =
            generatedHistory.map((item) => item.toJson()).toList();

        await file.writeAsString(jsonEncode(updatedJsonList));
      } else {
        GeneratedValue encryptedValue = generatedValue.copy();
        if (generatedValue.decrypted == true) {
          encryptedValue = await encryptGeneratedValue(generatedValue);
        }
        List<GeneratedValue> generatedHistory = [encryptedValue];

        List<Map<String, dynamic>> jsonList =
            generatedHistory.map((item) => item.toJson()).toList();

        await file.writeAsString(jsonEncode(jsonList));
      }
    } catch (e) {
      log("add to history error: ${e.toString()}");
    }
  }

  static Future<List<GeneratedValue>> getHistoryFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        String fileContents = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(fileContents);

        List<GeneratedValue> generatedHistory = jsonList
            .map((jsonItem) => GeneratedValue.fromJson(jsonItem))
            .toList();

        return generatedHistory;
      } else {
        return [];
      }
    } catch (e) {
      log("get history error: ${e.toString()}");
      return [];
    }
  }

  static Future<GeneratedValue> encryptGeneratedValue(
      GeneratedValue value) async {
    SecureStorage secureStorage = SecureStorage.instance;
    final hexEncryptionKey = await secureStorage.getDerivedKey();
    String? encryptedText =
        await PasswordsService.encryptText(value.value, hexEncryptionKey);
    return value.copy(
      value: encryptedText,
      decrypted: false,
    );
  }

  static Future<void> clearHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        await file.writeAsString(jsonEncode([]));
      }
    } catch (e) {
      log("clear history error: ${e.toString()}");
    }
  }
}
