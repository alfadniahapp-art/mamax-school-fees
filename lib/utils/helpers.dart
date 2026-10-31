import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _numFmt = NumberFormat('#,##0', 'en_US');
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'en_US');

String money(num n) => _numFmt.format(n);
String dateStr(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

String installmentLabel(int i) => ['القسط الأول', 'القسط الثاني', 'القسط الثالث'][i];

int? daysUntil(DateTime? due) {
  if (due == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(due.year, due.month, due.day);
  return target.difference(today).inDays;
}

// ====== الهوية البصرية الاحترافية ======
class AppColors {
  static const primary = Color(0xFF0F766E); // زمردي
  static const primaryDark = Color(0xFF115E59);
  static const secondary = Color(0xFFD97706); // ذهبي
  static const bg = Color(0xFFF3F4F6); // رمادي فاتح جداً
  static const surface = Colors.white;
  
  static const ok = Color(0xFF059669); // أخضر
  static const partial = Color(0xFFD97706); // برتقالي
  static const none = Color(0xFFDC2626); // أحمر
  static const over = Color(0xFF2563EB); // أزرق
  
  static const textDark = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
}
