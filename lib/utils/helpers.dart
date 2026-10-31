import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

final NumberFormat _numFmt = NumberFormat('#,##0', 'en_US');
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'en_US');

String money(num n) => _numFmt.format(n);
String dateStr(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = const Color(0xFF0B4A3D); 
  Color _cardBorderColor = const Color(0xFF0B4A3D).withOpacity(0.25);
  Color _cardBgColor = Colors.white; // لون خلفية البطاقة الافتراضي

  Color get primaryColor => _primaryColor;
  Color get cardBorderColor => _cardBorderColor;
  Color get cardBgColor => _cardBgColor;

  void changePrimaryColor(Color color) { 
    _primaryColor = color; 
    notifyListeners(); 
  }

  void changeCardBorderColor(Color color) {
    _cardBorderColor = color;
    notifyListeners();
  }

  void changeCardBgColor(Color color) {
    _cardBgColor = color;
    notifyListeners();
  }
}

class AppColors {
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color bg(BuildContext context) => const Color(0xFFF8FAFC);
  
  // خلفية البطاقة تأخذ اللون المختار، لكن بشفافية عالية لضمان بقاء النص مقروءاً
  static Color surface(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    // إذا كان اللون أبيض نتركه أبيض، وإلا نطبق عليه شفافية 85% ليكون لوناً فاتحاً جداً
    return themeProv.cardBgColor == Colors.white 
        ? Colors.white 
        : Color.alphaBlend(themeProv.cardBgColor.withOpacity(0.08), Colors.white);
  }

  static Color cardBorder(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    return themeProv.cardBorderColor;
  }
      
  static Color textDark(BuildContext context) => const Color(0xFF0F172A);
  static Color textMuted(BuildContext context) => const Color(0xFF64748B);

  static const secondary = Color(0xFFD97706);
  static const ok = Color(0xFF10B981);
  static const partial = Color(0xFFF59E0B);
  static const none = Color(0xFFEF4444);
}
