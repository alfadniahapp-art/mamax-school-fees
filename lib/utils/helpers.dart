import 'package:intl/intl.dart';

/// تنسيق الأرقام بفواصل الآلاف
final NumberFormat _numFmt = NumberFormat('#,##0', 'en_US');
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'en_US');

/// تنسيق المبلغ
String money(num n) => _numFmt.format(n);

/// تنسيق التاريخ
String dateStr(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

/// تنسيق التاريخ بصيغة ISO (للحفظ)
String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// تحويل نص إلى تاريخ (ISO)
DateTime? parseIso(String? s) {
  if (s == null || s.isEmpty) return null;
  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

/// وصف نوع القسط
String installmentLabel(int i) =>
    ['قسط أول', 'قسط ثاني', 'قسط أخير'][i];

/// حساب الأيام حتى تاريخ
int? daysUntil(DateTime? due) {
  if (due == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(due.year, due.month, due.day);
  return target.difference(today).inDays;
}

/// ألوان الحالة
const kOkColor = Color(0xFF16A34A);
const kPartialColor = Color(0xFFD97706);
const kNoneColor = Color(0xFFDC2626);
const kOverColor = Color(0xFF2563EB);
const kPrimaryColor = Color(0xFF0F766E);
const kPrimaryDark = Color(0xFF115E59);
