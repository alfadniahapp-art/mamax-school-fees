import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

final NumberFormat _numFmt = NumberFormat('#,##0', 'en_US');
final DateFormat _dateFmt = DateFormat('dd/MM/yyyy', 'en_US');

String money(num n) => _numFmt.format(n);
String dateStr(DateTime? d) => d == null ? '—' : _dateFmt.format(d);

class ThemeProvider extends ChangeNotifier {
  // القيم الافتراضية
  Color _primaryColor = const Color(0xFF0B4A3D); 
  Color _cardBorderColor = const Color(0xFFD97706); 
  Color _inputBorderColor = const Color(0xFFD97706); 
  Color _chipBorderColor = const Color(0xFFD97706); 
  Color _cardBgColor = Colors.white;

  Color get primaryColor => _primaryColor;
  Color get cardBorderColor => _cardBorderColor;
  Color get inputBorderColor => _inputBorderColor;
  Color get chipBorderColor => _chipBorderColor;
  Color get cardBgColor => _cardBgColor;

  // مفاتيح الحفظ في الذاكرة
  static const _kPrimary = 'theme_primary';
  static const _kCardBorder = 'theme_card_border';
  static const _kInputBorder = 'theme_input_border';
  static const _kChipBorder = 'theme_chip_border';
  static const _kCardBg = 'theme_card_bg';

  // دالة التحميل عند فتح التطبيق
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (prefs.containsKey(_kPrimary)) _primaryColor = Color(prefs.getInt(_kPrimary)!);
    if (prefs.containsKey(_kCardBorder)) _cardBorderColor = Color(prefs.getInt(_kCardBorder)!);
    if (prefs.containsKey(_kInputBorder)) _inputBorderColor = Color(prefs.getInt(_kInputBorder)!);
    if (prefs.containsKey(_kChipBorder)) _chipBorderColor = Color(prefs.getInt(_kChipBorder)!);
    if (prefs.containsKey(_kCardBg)) _cardBgColor = Color(prefs.getInt(_kCardBg)!);
    
    notifyListeners();
  }

  // دوال التغيير مع الحفظ
  Future<void> changePrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrimary, color.value);
  }

  Future<void> changeCardBorderColor(Color color) async {
    _cardBorderColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCardBorder, color.value);
  }

  Future<void> changeInputBorderColor(Color color) async {
    _inputBorderColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kInputBorder, color.value);
  }

  Future<void> changeChipBorderColor(Color color) async {
    _chipBorderColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kChipBorder, color.value);
  }

  Future<void> changeCardBgColor(Color color) async {
    _cardBgColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCardBg, color.value);
  }
}

class AppColors {
  static Color primary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color bg(BuildContext context) => const Color(0xFFF8FAFC);
  
  static Color surface(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    return themeProv.cardBgColor == Colors.white 
        ? Colors.white 
        : Color.alphaBlend(themeProv.cardBgColor.withOpacity(0.08), Colors.white);
  }

  static Color cardBorder(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    return themeProv.cardBorderColor;
  }

  static Color inputBorder(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    return themeProv.inputBorderColor;
  }

  static Color chipBorder(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    return themeProv.chipBorderColor;
  }
      
  static Color textDark(BuildContext context) => const Color(0xFF0F172A);
  static Color textMuted(BuildContext context) => const Color(0xFF64748B);

  static const secondary = Color(0xFFD97706);
  static const ok = Color(0xFF10B981);
  static const partial = Color(0xFFF59E0B);
  static const none = Color(0xFFEF4444);
}
