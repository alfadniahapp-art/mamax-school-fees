import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../models/settings.dart';
import '../models/transaction.dart';

class AppProvider extends ChangeNotifier {
  List<Student> students = [];
  List<FinancialTransaction> transactions = [];
  AppSettings settings = AppSettings();
  bool isLoading = true;
  bool isUnlocked = false;
  
  String _pinCode = '1234';
  final _uuid = const Uuid();
  static const _kStudents = 'students_v1';
  static const _kSettings = 'settings_v1';
  static const _kPin = 'app_pin_v1';
  static const _kTransactions = 'transactions_v1';
  static const _kClassFees = 'class_fees_v1';

  Map<String, double> _classFees = {};

  Future<void> load() async {
    isLoading = true;
    final prefs = await SharedPreferences.getInstance();
    _pinCode = prefs.getString(_kPin) ?? '1234';

    final s = prefs.getString(_kStudents);
    if (s != null) {
      try {
        students = (jsonDecode(s) as List).map((e) => Student.fromJson(e)).toList();
      } catch (e) {
        debugPrint('$e');
      }
    }

    final tx = prefs.getString(_kTransactions);
    if (tx != null) {
      try {
        transactions = (jsonDecode(tx) as List).map((e) => FinancialTransaction.fromJson(e)).toList();
      } catch (e) {
        debugPrint('$e');
      }
    }

    final st = prefs.getString(_kSettings);
    if (st != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(st));
      } catch (e) {
        debugPrint('$e');
      }
    }

    final cf = prefs.getString(_kClassFees);
    if (cf != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(cf);
        _classFees = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } catch (e) {
        debugPrint('$e');
      }
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStudents, jsonEncode(students.map((e) => e.toJson()).toList()));
    await prefs.setString(_kSettings, jsonEncode(settings.toJson()));
    await prefs.setString(_kTransactions, jsonEncode(transactions.map((e) => e.toJson()).toList()));
    await prefs.setString(_kClassFees, jsonEncode(_classFees));
    notifyListeners();
  }

  Future<void> setClassFee(String key, double fee) async {
    _classFees[key] = fee;
    await _save();
  }

  double getClassFee(String key) => _classFees[key] ?? 200000;

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    _pinCode = pin;
    await prefs.setString(_kPin, pin);
    notifyListeners();
  }

  bool checkPin(String input) => input == _pinCode;
  void unlock() { isUnlocked = true; notifyListeners(); }
  void lock() { isUnlocked = false; notifyListeners(); }
  String newId() => _uuid.v4();

  Future<void> addStudent(Student s) async {
    students.add(s);
    await _save();
  }

  Future<void> addMultipleStudents(List<Student> newStudents) async {
    students.addAll(newStudents);
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

    final isCash = p.method == PaymentMethod.cash;
    final newTx = FinancialTransaction(
      id: newId(),
      type: 'deposit',
      method: isCash ? 'cash' : 'bank',
      entityName: s.name,
      amount: p.amount,
      date: p.date,
      referenceNumber: p.reference,
    );
    transactions.add(newTx);
    await _save();
  }

  Future<void> removePayment(String studentId, String paymentId) async {
    final s = students.firstWhere((e) => e.id == studentId);
    s.payments.removeWhere((p) => p.id == paymentId);
    await _save();
  }

  Future<void> addTransaction(FinancialTransaction tx) async {
    transactions.add(tx);
    await _save();
  }

  Future<void> updateTransaction(FinancialTransaction updatedTx) async {
    final i = transactions.indexWhere((e) => e.id == updatedTx.id);
    if (i > -1) transactions[i] = updatedTx;
    await _save();
  }

  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> saveSettings(AppSettings s) async {
    settings = s;
    await _save();
  }

  double get cashBalance {
    double balance = 0;
    for (var tx in transactions) {
      if (tx.method == 'cash') {
        if (tx.type == 'deposit') balance += tx.amount;
        if (tx.type == 'withdraw') balance -= tx.amount;
        if (tx.type == 'transfer') {
          if (tx.toAccount == 'cash') balance += tx.amount;
          if (tx.fromAccount == 'cash') balance -= tx.amount;
        }
      }
    }
    return balance;
  }

  double get bankBalance {
    double balance = 0;
    for (var tx in transactions) {
      if (tx.method == 'bank') {
        if (tx.type == 'deposit') balance += tx.amount;
        if (tx.type == 'withdraw') balance -= tx.amount;
        if (tx.type == 'transfer') {
          if (tx.toAccount == 'bank') balance += tx.amount;
          if (tx.fromAccount == 'bank') balance -= tx.amount;
        }
      }
    }
    return balance;
  }

  Future<void> exportData() async {
    final data = jsonEncode({
      'students': students.map((e) => e.toJson()).toList(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'pin': _pinCode,
    });
    
    final fileName = 'Mamx_For_Schools_${DateTime.now().millisecondsSinceEpoch}.json';
    
    final file = XFile.fromData(
      utf8.encode(data), 
      name: fileName, 
      mimeType: 'application/json'
    );
    
    await Share.shareXFiles([file], text: 'نسخة احتياطية من بيانات رسوم الطلاب');
  }

  Future<bool> importData() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null && result.files.single.path != null) {
      try {
        final data = jsonDecode(await File(result.files.single.path!).readAsString());
        if (data['students'] != null) students = (data['students'] as List).map((e) => Student.fromJson(e)).toList();
        if (data['transactions'] != null) transactions = (data['transactions'] as List).map((e) => FinancialTransaction.fromJson(e)).toList();
        if (data['settings'] != null) settings = AppSettings.fromJson(data['settings']);
        if (data['pin'] != null) _pinCode = data['pin'];
        await _save();
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
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

    final warnDaysList = [settings.warnDays1, settings.warnDays2, settings.warnDays3];
    bool shouldAlert = false;
    for (var warnDay in warnDaysList) {
      if (days <= warnDay && days >= 0) {
        shouldAlert = true;
        break;
      }
    }

    if (days < 0) {
      out.add({'student': s, 'type': t, 'days': days, 'remaining': required - paid, 'overdue': true, 'due': due});
    } else if (shouldAlert) {
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
    final base = _classFees[key] ?? 200000;
    return {'base': base, 'reg': 25000, 'exam': 50000};
  }
}
