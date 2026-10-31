import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _numFmt = NumberFormat('#,##0', 'en_US');
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'en_US');

String money(num n) => _numFmt.format(n);
String dateStr(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

int? daysUntil(DateTime? due) {
  if (due == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(due.year, due.month, due.day);
  return target.difference(today).inDays;
}

// ====== إدارة الثيمات ======
class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  Color _primaryColor = const Color(0xFF0F766E);

  bool get isDark => _isDark;
  Color get primaryColor => _primaryColor;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void changePrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }
}

// ====== ألوان التطبيق الأساسية ======
class AppColors {
  static Color primary(BuildContext context) => 
      Theme.of(context).colorScheme.primary;
      
  static Color bg(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
      
  static Color surface(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white;

  static const secondary = Color(0xFFD97706);
  static const ok = Color(0xFF10B981);
  static const partial = Color(0xFFF59E0B);
  static const none = Color(0xFFEF4444);
  
  static Color textDark(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A);
      
  static Color textMuted(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF64748B);
}
