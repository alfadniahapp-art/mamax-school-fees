import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

final NumberFormat _numFmt = NumberFormat('#,##0', 'en_US');
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'en_US');

String money(num n) => _numFmt.format(n);
String dateStr(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = const Color(0xFF0B4A3D);
  String _bgStyle = 'light';
  bool _isDark = false; // تم إضافتها لمنع الخطأ في شاشة الإعدادات

  Color get primaryColor => _primaryColor;
  String get bgStyle => _bgStyle;
  bool get isDark => _isDark;

  void changePrimaryColor(Color color) { _primaryColor = color; notifyListeners(); }
  void changeBgStyle(String style) { _bgStyle = style; notifyListeners(); }
  void toggleTheme() { _isDark = !_isDark; notifyListeners(); }

  Color get derivedBackground {
    if (_bgStyle == 'royal') return _primaryColor.withOpacity(0.05);
    if (_bgStyle == 'dark') return const Color(0xFF121212);
    return const Color(0xFFF8FAFC);
  }

  Color get derivedBorderColor => _primaryColor.withOpacity(0.2);
}

class AppColors {
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color bg(BuildContext context) => const Color(0xFFF8FAFC);
  static Color surface(BuildContext context) => Colors.white;
  static Color cardBorder(BuildContext context) => const Color(0xFFE2E8F0);
  
  // تعريفها كدالة تقبل context (لإرضاء الكود القديم)
  static Color textDark(BuildContext context) => const Color(0xFF0F172A);
  static Color textMuted(BuildContext context) => const Color(0xFF64748B);

  static const secondary = Color(0xFFD97706);
  static const ok = Color(0xFF10B981);
  static const partial = Color(0xFFF59E0B);
  static const none = Color(0xFFEF4444);
}
