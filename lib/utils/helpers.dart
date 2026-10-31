import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

final NumberFormat _numFmt = NumberFormat('#,##0', 'en_US');
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'en_US');

String money(num n) => _numFmt.format(n);
String dateStr(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = const Color(0xFF0B4A3D); // أخضر ملكي
  String _bgStyle = 'light'; // فاتح افتراضياً

  Color get primaryColor => _primaryColor;
  String get bgStyle => _bgStyle;

  void changePrimaryColor(Color color) { _primaryColor = color; notifyListeners(); }
  void changeBgStyle(String style) { _bgStyle = style; notifyListeners(); }

  Color get derivedBackground {
    if (_bgStyle == 'royal') return _primaryColor.withOpacity(0.05);
    return const Color(0xFFF8FAFC); // أبيض فاتح
  }

  Color get derivedBorderColor => _primaryColor.withOpacity(0.2);
}

class AppColors {
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color bg(BuildContext context) => const Color(0xFFF8FAFC); // إجبار الخلفية البيضاء
  static Color surface(BuildContext context) => Colors.white; // إجبار البطاقات البيضاء
  static Color cardBorder(BuildContext context) => const Color(0xFFE2E8F0); // حدود فاتحة
  
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);

  static const secondary = Color(0xFFD97706);
  static const ok = Color(0xFF10B981);
  static const partial = Color(0xFFF59E0B);
  static const none = Color(0xFFEF4444);
}
