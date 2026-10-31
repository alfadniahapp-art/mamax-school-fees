import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settings.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _pctA, _pctB, _pctC, _warnDays;
  late TextEditingController _bankName, _bankAcc, _bankPhone;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppProvider>().settings;
    _pctA = TextEditingController(text: s.pctA.toStringAsFixed(0));
    _pctB = TextEditingController(text: s.pctB.toStringAsFixed(0));
    _pctC = TextEditingController(text: s.pctC.toStringAsFixed(0));
    _warnDays = TextEditingController(text: '${s.warnDays}');
    _bankName = TextEditingController(text: s.bankAccountName);
    _bankAcc = TextEditingController(text: s.bankAccountNumber);
    _bankPhone = TextEditingController(text: s.bankPhone);
  }

  Future<void> _save() async {
    final app = context.read<AppProvider>();
    await app.saveSettings(AppSettings(
      pctA: double.tryParse(_pctA.text) ?? 50,
      pctB: double.tryParse(_pctB.text) ?? 25,
      pctC: double.tryParse(_pctC.text) ?? 25,
      warnDays: int.tryParse(_warnDays.text) ?? 14,
      bankAccountName: _bankName.text.trim(),
      bankAccountNumber: _bankAcc.text.trim(),
      bankPhone: _bankPhone.text.trim(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('✓ تم حفظ الإعدادات'), backgroundColor: AppColors.ok));
      Navigator.pop(context);
    }
  }

  Future<void> _resetPassword() async {
    final TextEditingController resetCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استعادة كلمة السر'),
        content: TextField(
          controller: resetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'كلمة السر الجديدة (4 أرقام على الأقل)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary(context), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('تعيين')
          ),
        ],
      ),
    );
    if (confirm == true && resetCtrl.text.length >= 4) {
      await context.read<AppProvider>().savePin(resetCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ تم تغيير كلمة السر بنجاح'), backgroundColor: AppColors.ok));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card('المظهر والألوان', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('الوضع الليلي (Dark Mode)'),
              secondary: Icon(themeProv.isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary(context)),
              value: themeProv.isDark,
              onChanged: (v) => themeProv.toggleTheme(),
            ),
            const Divider(),
            const Text('اللون الأساسي للتطبيق', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorDot(const Color(0xFF0F766E), themeProv), // زمردي
                _colorDot(const Color(0xFF2563EB), themeProv), // أزرق
                _colorDot(const Color(0xFF7C3AED), themeProv), // بنفسجي
                _colorDot(const Color(0xFFDC2626), themeProv), // أحمر
                _colorDot(const Color(0xFF1F2937), themeProv), // أسود داكن
              ],
            ),
          ]),
          _card('الأمان والنسخ الاحتياطي', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_reset, color: AppColors.primary(context)),
              title: const Text('استعادة كلمة السر'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _resetPassword,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup, color: AppColors.ok),
              title: const Text('حفظ نسخة من البيانات'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.read<AppProvider>().exportData(),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore, color: AppColors.partial),
              title: const Text('استعادة نسخة احتياطية'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final success = await context.read<AppProvider>().importData();
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ تم استعادة البيانات بنجاح'), backgroundColor: AppColors.ok));
                }
              },
            ),
          ]),
          _card('نسب الأقساط', [
            Row(
              children: [
                Expanded(child: TextField(controller: _pctA, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قسط أول %'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _pctB, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قسط ثاني %'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _pctC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قسط أخير %'))),
              ],
            ),
          ]),
          _card('حساب البنك', [
            TextField(controller: _bankName, decoration: const InputDecoration(labelText: 'اسم صاحب الحساب')),
            const SizedBox(height: 8),
            TextField(controller: _bankAcc, decoration: const InputDecoration(labelText: 'رقم الحساب')),
            const SizedBox(height: 8),
            TextField(controller: _bankPhone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary(context), foregroundColor: Colors.white),
            onPressed: _save, 
            child: const Text('حفظ الإعدادات')
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color, ThemeProvider themeProv) {
    final isSelected = themeProv.primaryColor == color;
    return GestureDetector(
      onTap: () => themeProv.changePrimaryColor(color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary(context), fontSize: 16)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
