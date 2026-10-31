import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

final NumberFormat _numFmt = NumberFormat('#,##0', 'en_US');
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'en_US');

String money(num n) => _numFmt.format(n);
String dateStr(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  Color _primaryColor = const Color(0xFF0B4A3D); // أخضر ملكي داكن
  String _bgStyle = 'royal'; // royal, light, dark

  bool get isDark => _isDark;
  Color get primaryColor => _primaryColor;
  String get bgStyle => _bgStyle;

  void toggleTheme() { _isDark = !_isDark; notifyListeners(); }
  void changePrimaryColor(Color color) { _primaryColor = color; notifyListeners(); }
  void changeBgStyle(String style) { _bgStyle = style; notifyListeners(); }

  // إنشاء لون خلفية مشتق من اللون الأساسي (فاتح جداً)
  Color get derivedBackground => _bgStyle == 'dark' 
      ? const Color(0xFF121212) 
      : _primaryColor.withOpacity(0.04);

  // إنشاء لون حدود البطاقات مشتق من اللون الأساسي
  Color get derivedBorderColor => _primaryColor.withOpacity(0.2);
}

class AppColors {
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  
  // الخلفية تأخذ اللون المشتق من الثيم
  static Color bg(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    return themeProv.derivedBackground;
  }
  
  // خلفية البطاقات
  static Color surface(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white;

  // لون حدود البطاقات (يستخدم في كل مكان)
  static Color cardBorder(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    return themeProv.derivedBorderColor;
  }
      
  static Color textDark(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A);
      
  static Color textMuted(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : const Color(0xFF64748B);

  static const secondary = Color(0xFFD97706);
  static const ok = Color(0xFF10B981);
  static const partial = Color(0xFFF59E0B);
  static const none = Color(0xFFEF4444);
}
