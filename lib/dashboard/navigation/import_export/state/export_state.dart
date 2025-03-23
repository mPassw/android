import 'package:flutter/material.dart';

class ExportState extends ChangeNotifier {
  String _selectedValue = 'JSON';
  String get selectedValue => _selectedValue;

  List<String> get options => ['JSON', 'CSV'];

  setSelectedValue(String newValue) {
    _selectedValue = newValue;
    notifyListeners();
  }

  
}
