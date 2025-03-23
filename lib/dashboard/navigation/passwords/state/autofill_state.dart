import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AutofillState extends ChangeNotifier {
  String? _flutterEngineId;
  String? get flutterEngineId => _flutterEngineId;

  bool _isAutofill = false;
  bool get isAutofill => _isAutofill;

  bool _isAutosave = false;
  bool get isAutosave => _isAutosave;

  void setFlutterEngineId(String newValue) {
    _flutterEngineId = newValue;
  }

  void setIsAutofill(bool newValue) {
    _isAutofill = newValue;
  }

  void setIsAutosave(bool newValue) {
    _isAutosave = newValue;
  }
}
