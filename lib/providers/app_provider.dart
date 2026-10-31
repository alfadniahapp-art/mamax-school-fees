import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../models/settings.dart';

class AppProvider extends ChangeNotifier {
  List<Student> students = [];
  AppSettings settings = AppSettings();
  bool isLoading = true;
  bool isUnlocked = false;
  
  String _pinCode = '1234';
  bool get isPinSet => _pinCode.isNotEmpty;

  final _uuid = const Uuid();
  static const _kStudents = 'students_v1';
  static const _kSettings = 'settings_v1';
  static const _kPin = 'app_pin_v1';

  Future<void> load() async {
    isLoading = true;
    final prefs = await SharedPreferences.getInstance();
    _pinCode = prefs.getString(_kPin) ?? '1234';

    final s = prefs.getString(_kStudents);
    if (s != null) {
      try {
        final list = jsonDecode(s) as List;
        students = list.map((e) => Student.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading students: $e');
      }
    }

    final st = prefs.getString(_kSettings);
    if (st != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(st));
      } catch (e) {
        debugPrint('Error loading settings: $e');
      }
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStudents, jsonEncode(students.map((e) => e.toJson()).toList()));
    await prefs.setString(_kSettings, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    _pinCode = pin;
    await prefs.setString(_kPin, pin);
    notifyListeners();
  }

  bool checkPin(String input) => input == _pinCode;
  
  void unlock() {
    isUnlocked = true;
    notifyListeners();
  }
  
  void lock() {
    isUnlocked = false;
    notifyListeners();
  }

  String newId() => _uuid.v4();

  Future<void> addStudent(Student s) async {
    students.add(s);
    await _save();
  }

  Future<void> updateStudent(Student s) async {
    final i = students.indexWhere((e) => e.id == s.id);
    if (i > -1) students[i] = s;
    await _save();
  }

  Future<void> deleteStudent(String id) async {
    students.removeWhere((e) => e.id == id);
    await _save();
  }

  Student? getStudentById(String id) {
    try {
      return students.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addPayment(String studentId, Payment p) async {
    final s = students.firstWhere((e) => e.id == studentId);
    s.payments.add(p);
    await _save();
  }

  Future<void> removePayment(String studentId, String paymentId) async {
    final s = students.firstWhere((e) => e.id == studentId);
    s.payments.removeWhere((p) => p.id == paymentId);
    await _save();
  }

  Future<void> saveSettings(AppSettings s) async {
    settings = s;
    await _save();
  }

  double get totalRequired => students.fold(0.0, (s, e) => s + e.totalRequired);
  double get totalPaid => students.fold(0.0, (s, e) => s + e.totalPaid);
  double get totalRemaining => totalRequired - totalPaid;
  double get paidPct => totalRequired > 0 ? (totalPaid / totalRequired).clamp(0.0, 1.0) : 0.0;

  List<Map<String, dynamic>> get allAlerts {
    final out = <Map<String, dynamic>>[];
    for (final s in students) {
      _checkDue(s, s.due2, FeeType.inst2, out);
      _checkDue(s, s.due3, FeeType.inst3, out);
    }
    return out;
  }

  void _checkDue(Student s, DateTime? due, FeeType t, List<Map<String, dynamic>> out) {
    if (due == null) return;
    final required = s.amountFor(t);
    final paid = s.paidFor(t);
    if (paid >= required) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    final days = target.difference(today).inDays;

    if (days < 0) {
      out.add({'student': s, 'type': t, 'days': days, 'remaining': required - paid, 'overdue': true, 'due': due});
    } else if (days <= settings.warnDays) {
      out.add({'student': s, 'type': t, 'days': days, 'remaining': required - paid, 'overdue': false, 'due': due});
    }
  }

  List<Student> filterStudents({String search = '', Stage? stage, int? cls}) {
    return students.where((s) {
      if (stage != null && s.stage != stage) return false;
      if (cls != null && s.cls != cls) return false;
      if (search.isNotEmpty && !s.name.contains(search)) return false;
      return true;
    }).toList();
  }

  Map<String, double> getFeesForKey(String key) {
    if (key.startsWith('primary')) return {'base': 150000, 'reg': 25000, 'exam': 50000};
    if (key.startsWith('middle')) return {'base': 200000, 'reg': 0, 'exam': 0};
    return {'base': 250000, 'reg': 0, 'exam': 0};
  }
}
