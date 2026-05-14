import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/api_requests/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _claimNavOpen = prefs.getBool('ff_claimNavOpen') ?? _claimNavOpen;
    });
    _safeInit(() {
      _leadNavOpen = prefs.getBool('ff_leadNavOpen') ?? _leadNavOpen;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  List<int> _xAxis = [];
  List<int> get xAxis => _xAxis;
  set xAxis(List<int> value) {
    _xAxis = value;
  }

  void addToXAxis(int value) {
    xAxis.add(value);
  }

  void removeFromXAxis(int value) {
    xAxis.remove(value);
  }

  void removeAtIndexFromXAxis(int index) {
    xAxis.removeAt(index);
  }

  void updateXAxisAtIndex(
    int index,
    int Function(int) updateFn,
  ) {
    xAxis[index] = updateFn(_xAxis[index]);
  }

  void insertAtIndexInXAxis(int index, int value) {
    xAxis.insert(index, value);
  }

  List<double> _yAxis = [];
  List<double> get yAxis => _yAxis;
  set yAxis(List<double> value) {
    _yAxis = value;
  }

  void addToYAxis(double value) {
    yAxis.add(value);
  }

  void removeFromYAxis(double value) {
    yAxis.remove(value);
  }

  void removeAtIndexFromYAxis(int index) {
    yAxis.removeAt(index);
  }

  void updateYAxisAtIndex(
    int index,
    double Function(double) updateFn,
  ) {
    yAxis[index] = updateFn(_yAxis[index]);
  }

  void insertAtIndexInYAxis(int index, double value) {
    yAxis.insert(index, value);
  }

  List<int> _xAxis2 = [];
  List<int> get xAxis2 => _xAxis2;
  set xAxis2(List<int> value) {
    _xAxis2 = value;
  }

  void addToXAxis2(int value) {
    xAxis2.add(value);
  }

  void removeFromXAxis2(int value) {
    xAxis2.remove(value);
  }

  void removeAtIndexFromXAxis2(int index) {
    xAxis2.removeAt(index);
  }

  void updateXAxis2AtIndex(
    int index,
    int Function(int) updateFn,
  ) {
    xAxis2[index] = updateFn(_xAxis2[index]);
  }

  void insertAtIndexInXAxis2(int index, int value) {
    xAxis2.insert(index, value);
  }

  List<double> _yAxis2 = [];
  List<double> get yAxis2 => _yAxis2;
  set yAxis2(List<double> value) {
    _yAxis2 = value;
  }

  void addToYAxis2(double value) {
    yAxis2.add(value);
  }

  void removeFromYAxis2(double value) {
    yAxis2.remove(value);
  }

  void removeAtIndexFromYAxis2(int index) {
    yAxis2.removeAt(index);
  }

  void updateYAxis2AtIndex(
    int index,
    double Function(double) updateFn,
  ) {
    yAxis2[index] = updateFn(_yAxis2[index]);
  }

  void insertAtIndexInYAxis2(int index, double value) {
    yAxis2.insert(index, value);
  }

  bool _claimNavOpen = false;
  bool get claimNavOpen => _claimNavOpen;
  set claimNavOpen(bool value) {
    _claimNavOpen = value;
    prefs.setBool('ff_claimNavOpen', value);
  }

  bool _leadNavOpen = false;
  bool get leadNavOpen => _leadNavOpen;
  set leadNavOpen(bool value) {
    _leadNavOpen = value;
    prefs.setBool('ff_leadNavOpen', value);
  }

  bool _navOpen = false;
  bool get navOpen => _navOpen;
  set navOpen(bool value) {
    _navOpen = value;
  }

  String _selectedAirlineEmail = '';
  String get selectedAirlineEmail => _selectedAirlineEmail;
  set selectedAirlineEmail(String value) {
    _selectedAirlineEmail = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
