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

  final _uuid = const Uuid();
  static const _kStudents = 'students_v1';
  static const _kSettings = 'settings_v1';

  Future<void> load() async {
    isLoading = true;
    final prefs = await SharedPreferences.getInstance();

    final s = prefs.getString(_kStudents);
    if (s != null) {
      try {
        final list = jsonDecode(s) as List;
        students = list.map((e) => Student.fromJson(e)).toList();
      } catch (e) {
        debugPrint('خطأ في تحميل الطلاب: $e');
      }
    }

    final st = prefs.getString(_kSettings);
    if (st != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(st));
      } catch (e) {
        debugPrint('خطأ في تحميل الإعدادات: $e');
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kStudents, jsonEncode(students.map((e) => e.toJson()).toList()));
    await prefs.setString(_kSettings, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  String newId() => _uuid.v4();

  // ============ إدارة الطلاب ============

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

  // ============ إدارة الدفعات ============

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

  // ============ الإعدادات ============

  Future<void> saveSettings(AppSettings s) async {
    settings = s;
    await _save();
  }

  // ============ إحصائيات ============

  double get totalRequired =>
      students.fold(0.0, (s, e) => s + e.totalRequired);

  double get totalPaid => students.fold(0.0, (s, e) => s + e.totalPaid);

  double get totalRemaining => totalRequired - totalPaid;

  double get paidPct =>
      totalRequired > 0 ? (totalPaid / totalRequired).clamp(0.0, 1.0) : 0.0;

  int get overdueCount => allAlerts.where((a) => a['overdue'] == true).length;

  int get soonCount => allAlerts.where((a) => a['overdue'] == false).length;

  // ============ التنبيهات ============

  List<Map<String, dynamic>> get allAlerts {
    final out = <Map<String, dynamic>>[];
    for (final s in students) {
      _checkDue(s, s.due2, FeeType.inst2, out);
      _checkDue(s, s.due3, FeeType.inst3, out);
    }
    out.sort((a, b) {
      final ao = a['overdue'] == true ? 0 : 1;
      final bo = b['overdue'] == true ? 0 : 1;
      if (ao != bo) return ao - bo;
      return (a['days'] as int).compareTo(b['days'] as int);
    });
    return out;
  }

  void _checkDue(
      Student s, DateTime? due, FeeType t, List<Map<String, dynamic>> out) {
    if (due == null) return;
    final required = s.amountFor(t);
    final paid = s.paidFor(t);
    if (paid >= required) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    final days = target.difference(today).inDays;

    if (days < 0) {
      out.add({
        'student': s,
        'type': t,
        'days': days,
        'remaining': required - paid,
        'overdue': true,
        'due': due,
      });
    } else if (days <= settings.warnDays) {
      out.add({
        'student': s,
        'type': t,
        'days': days,
        'remaining': required - paid,
        'overdue': false,
        'due': due,
      });
    }
  }

  // ============ فلترة الطلاب ============

  List<Student> filterStudents({
    String search = '',
    Stage? stage,
    int? cls,
  }) {
    return students.where((s) {
      if (stage != null && s.stage != stage) return false;
      if (cls != null && s.cls != cls) return false;
      if (search.isNotEmpty && !s.name.contains(search)) return false;
      return true;
    }).toList();
  }

  // ============ كل الدفعات ============

  List<Map<String, dynamic>> getAllPayments({
    DateTime? from,
    DateTime? to,
    PaymentMethod? method,
    Stage? stage,
  }) {
    final out = <Map<String, dynamic>>[];
    for (final s in students) {
      if (stage != null && s.stage != stage) continue;
      for (final p in s.payments) {
        if (from != null) {
          final fromDay = DateTime(from.year, from.month, from.day);
          if (p.date.isBefore(fromDay)) continue;
        }
        if (to != null) {
          final toDay =
              DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
          if (p.date.isAfter(toDay)) continue;
        }
        if (method != null && p.method != method) continue;
        out.add({'student': s, 'payment': p});
      }
    }
    out.sort((a, b) {
      final pa = a['payment'] as Payment;
      final pb = b['payment'] as Payment;
      return pb.date.compareTo(pa.date);
    });
    return out;
  }
}
