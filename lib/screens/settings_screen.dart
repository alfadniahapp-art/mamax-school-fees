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
  late TextEditingController _bankNameCtrl, _bankName, _bankAcc, _bankPhone;
  late TextEditingController _schoolNameCtrl, _accountantNameCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppProvider>().settings;
    _pctA = TextEditingController(text: s.pctA.toStringAsFixed(0));
    _pctB = TextEditingController(text: s.pctB.toStringAsFixed(0));
    _pctC = TextEditingController(text: s.pctC.toStringAsFixed(0));
    _warnDays = TextEditingController(text: '${s.warnDays}');
    _bankNameCtrl = TextEditingController(text: s.bankName);
    _bankName = TextEditingController(text: s.bankAccountName);
    _bankAcc = TextEditingController(text: s.bankAccountNumber);
    _bankPhone = TextEditingController(text: s.bankPhone);
    _schoolNameCtrl = TextEditingController(text: s.schoolName);
    _accountantNameCtrl = TextEditingController(text: s.accountantName);
  }

  Future<void> _save() async {
    final app = context.read<AppProvider>();
    await app.saveSettings(AppSettings(
      pctA: double.tryParse(_pctA.text) ?? 50,
      pctB: double.tryParse(_pctB.text) ?? 25,
      pctC: double.tryParse(_pctC.text) ?? 25,
      warnDays: int.tryParse(_warnDays.text) ?? 14,
      bankName: _bankNameCtrl.text.trim(),
      bankAccountName: _bankName.text.trim(),
      bankAccountNumber: _bankAcc.text.trim(),
      bankPhone: _bankPhone.text.trim(),
      schoolName: _schoolNameCtrl.text.trim(),
      accountantName: _accountantNameCtrl.text.trim(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ تم حفظ الإعدادات'), backgroundColor: AppColors.ok));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بيانات المدرسة والمحاسب
          _buildCard('بيانات المدرسة والمحاسب', [
            TextField(controller: _schoolNameCtrl, decoration: _inputDecoration('اسم المدرسة')),
            const SizedBox(height: 12),
            TextField(controller: _accountantNameCtrl, decoration: _inputDecoration('اسم المحاسب')),
          ]),
          
          // النسخ الاحتياطي
          _buildCard('النسخ الاحتياطي', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup, color: AppColors.ok),
              title: const Text('حفظ نسخة من البيانات (تصدير)'),
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

          // المظهر والألوان
          _buildCard('المظهر والألوان', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('الوضع الليلي (Dark Mode)'),
              secondary: Icon(themeProv.isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary(context)),
              value: themeProv.isDark,
              onChanged: (v) => themeProv.toggleTheme(),
            ),
            const Divider(),
            const Text('اللون الأساسي للتطبيق', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorDot(const Color(0xFF0F766E), themeProv), // زمردي
                _colorDot(const Color(0xFF0B4A3D), themeProv), // أخضر داكن (الافتراضي الجديد)
                _colorDot(const Color(0xFF2563EB), themeProv), // أزرق
                _colorDot(const Color(0xFF7C3AED), themeProv), // بنفسجي
                _colorDot(const Color(0xFF1F2937), themeProv), // أسود
              ],
            ),
          ]),

          // نسب الأقساط
          _buildCard('نسب الأقساط الافتراضية', [
            Row(
              children: [
                Expanded(child: TextField(controller: _pctA, keyboardType: TextInputType.number, decoration: _inputDecoration('قسط أول %'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _pctB, keyboardType: TextInputType.number, decoration: _inputDecoration('قسط ثاني %'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _pctC, keyboardType: TextInputType.number, decoration: _inputDecoration('قسط أخير %'))),
              ],
            ),
          ]),

          // التنبيهات
          _buildCard('إعدادات التنبيهات', [
            TextField(controller: _warnDays, keyboardType: TextInputType.number, decoration: _inputDecoration('التنبيه قبل الاستحقاق (أيام)')),
          ]),

          // بيانات البنك
          _buildCard('بيانات البنك', [
            TextField(controller: _bankNameCtrl, decoration: _inputDecoration('اسم البنك')),
            const SizedBox(height: 12),
            TextField(controller: _bankName, decoration: _inputDecoration('اسم صاحب الحساب')),
            const SizedBox(height: 12),
            TextField(controller: _bankAcc, decoration: _inputDecoration('رقم الحساب')),
            const SizedBox(height: 12),
            TextField(controller: _bankPhone, decoration: _inputDecoration('رقم الهاتف')),
          ]),

          const SizedBox(height: 30),
          
          // زر الحفظ
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: AppColors.primary(context).withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _colorDot(Color color, ThemeProvider themeProv) {
    final isSelected = themeProv.primaryColor == color;
    return GestureDetector(
      onTap: () => themeProv.changePrimaryColor(color),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)] : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary(context), fontSize: 16)),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}
