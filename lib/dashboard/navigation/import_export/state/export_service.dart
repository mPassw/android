import 'package:intl/intl.dart';
import 'package:mpass/dashboard/navigation/passwords/model/password.dart';
import 'package:mpass/dashboard/navigation/passwords/state/passwords_service.dart';
import 'package:mpass/state/secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class ExportService {
  static Future<List<Password>> decryptAllPasswords(
      List<Password> passwordList) async {
    final secureStorage = SecureStorage.instance;
    final String hexDecryptionKey = await secureStorage.getDerivedKey();

    List<Password> decryptedPasswords =
        await Future.wait(passwordList.map((element) async {
      return await PasswordsService.decryptPassword(element, hexDecryptionKey);
    }));

    return decryptedPasswords;
  }

  static Future<bool> exportToJson(List<Password> passwordList) async {
    final jsonList = passwordList.map((password) => password.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      return false;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final fileName = "export_$formattedDate.json";

    final filePath = '$selectedDirectory/$fileName';
    final file = File(filePath);

    await file.writeAsString(jsonString);
    return true;
  }

  static String escapeCsv(String value) {
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      value = value.replaceAll('"', '""');
      return '"$value"';
    }
    return value;
  }

  static Future<bool> exportToCsv(List<Password> passwordList) async {
    if (passwordList.isEmpty) return false;

    final headers = [
      'id',
      'title',
      'username',
      'password',
      'note',
      'tags',
      'websites',
      'createdAt',
      'updatedAt',
      'inTrash'
    ];

    final List<List<String>> rows = [];

    rows.add(headers);

    for (final password in passwordList) {
      final row = [
        password.id ?? '',
        password.title ?? '',
        password.username ?? '',
        password.password ?? '',
        password.note ?? '',
        password.tags.join('|'),
        password.websites.join('|'),
        password.createdAt ?? '',
        password.updatedAt ?? '',
        password.inTrash.toString(),
      ];
      rows.add(row);
    }

    final csvString =
        rows.map((row) => row.map(escapeCsv).join(',')).join('\n');

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      return false;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final fileName = "export_$formattedDate.csv";

    final filePath = '$selectedDirectory/$fileName';
    final file = File(filePath);

    await file.writeAsString(csvString);

    return true;
  }
}
