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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard('بيانات المدرسة والمحاسب', [
            TextField(controller: _schoolNameCtrl, decoration: _inputDecoration('اسم المدرسة')),
            const SizedBox(height: 12),
            TextField(controller: _accountantNameCtrl, decoration: _inputDecoration('اسم المحاسب')),
          ]),
          
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

          _buildCard('المظهر والألوان', [
            const Text('اللون الأساسي للتطبيق:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorDot(const Color(0xFF0F766E), themeProv, 'primary'),
                _colorDot(const Color(0xFF0B4A3D), themeProv, 'primary'),
                _colorDot(const Color(0xFF2563EB), themeProv, 'primary'),
                _colorDot(const Color(0xFF7C3AED), themeProv, 'primary'),
                _colorDot(const Color(0xFF1F2937), themeProv, 'primary'),
              ],
            ),
            const Divider(height: 30),
            
            // لون حدود البطاقات
            const Text('لون حدود البطاقات:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorDot(const Color(0xFFE2E8F0), themeProv, 'border'),
                _colorDot(const Color(0xFFD97706), themeProv, 'border'),
                _colorDot(const Color(0xFF0F766E), themeProv, 'border'),
                _colorDot(const Color(0xFF2563EB), themeProv, 'border'),
                _pickColorBtn(context, themeProv, 'border'),
              ],
            ),
            const Divider(height: 30),
            
            // خلفية البطاقات
            const Text('خلفية البطاقات (لون خفيف جداً):', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorDot(Colors.white, themeProv, 'bg'),
                _colorDot(const Color(0xFFE0F2F1), themeProv, 'bg'), // أخضر فاتح
                _colorDot(const Color(0xFFE3F2FD), themeProv, 'bg'), // أزرق فاتح
                _colorDot(const Color(0xFFF3E5F5), themeProv, 'bg'), // بنفسجي فاتح
                _pickColorBtn(context, themeProv, 'bg'),
              ],
            ),
          ]),

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

          _buildCard('إعدادات التنبيهات', [
            TextField(controller: _warnDays, keyboardType: TextInputType.number, decoration: _inputDecoration('التنبيه قبل الاستحقاق (أيام)')),
          ]),

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

  Future<void> _pickColor(BuildContext context, ThemeProvider themeProv, String type) async {
    final colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple, 
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan, 
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange, 
      Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    ];
    
    final selected = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر اللون'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: colors.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => Navigator.pop(ctx, colors[i]),
              child: Container(decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
            ),
          ),
        ),
      ),
    );
    if (selected != null) {
      if (type == 'border') {
        themeProv.changeCardBorderColor(selected.withOpacity(0.6));
      } else {
        themeProv.changeCardBgColor(selected);
      }
    }
  }

  Widget _pickColorBtn(BuildContext context, ThemeProvider themeProv, String type) {
    return GestureDetector(
      onTap: () => _pickColor(context, themeProv, type),
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.colorize, color: Colors.black54, size: 20),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _colorDot(Color color, ThemeProvider themeProv, String type) {
    Color currentColor;
    bool isSelected;
    
    if (type == 'primary') {
      currentColor = themeProv.primaryColor;
      isSelected = currentColor == color;
    } else if (type == 'border') {
      currentColor = themeProv.cardBorderColor;
      isSelected = currentColor.withOpacity(0.6) == color.withOpacity(0.6);
    } else {
      currentColor = themeProv.cardBgColor;
      isSelected = currentColor == color;
    }

    return GestureDetector(
      onTap: () {
        if (type == 'primary') themeProv.changePrimaryColor(color);
        else if (type == 'border') themeProv.changeCardBorderColor(color);
        else themeProv.changeCardBgColor(color);
      },
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.black87 : Colors.transparent, width: 2),
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
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context), width: 1.5),
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
