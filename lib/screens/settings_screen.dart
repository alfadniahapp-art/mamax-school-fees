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
  late TextEditingController _pctA, _pctB, _pctC, _warnDays1, _warnDays2, _warnDays3;
  late TextEditingController _schoolNameCtrl, _accountantNameCtrl;
  
  List<BankAccount> _bankAccounts = [];

  @override
  void initState() {
    super.initState();
    final s = context.read<AppProvider>().settings;
    _pctA = TextEditingController(text: s.pctA.toStringAsFixed(0));
    _pctB = TextEditingController(text: s.pctB.toStringAsFixed(0));
    _pctC = TextEditingController(text: s.pctC.toStringAsFixed(0));
    _warnDays1 = TextEditingController(text: '${s.warnDays1}');
    _warnDays2 = TextEditingController(text: '${s.warnDays2}');
    _warnDays3 = TextEditingController(text: '${s.warnDays3}');
    _schoolNameCtrl = TextEditingController(text: s.schoolName);
    _accountantNameCtrl = TextEditingController(text: s.accountantName);
    
    _bankAccounts = List.from(s.bankAccounts);
  }

  Future<void> _save() async {
    final app = context.read<AppProvider>();
    await app.saveSettings(AppSettings(
      pctA: double.tryParse(_pctA.text) ?? 50,
      pctB: double.tryParse(_pctB.text) ?? 25,
      pctC: double.tryParse(_pctC.text) ?? 25,
      warnDays1: int.tryParse(_warnDays1.text) ?? 14,
      warnDays2: int.tryParse(_warnDays2.text) ?? 7,
      warnDays3: int.tryParse(_warnDays3.text) ?? 1,
      schoolName: _schoolNameCtrl.text.trim(),
      accountantName: _accountantNameCtrl.text.trim(),
      bankAccounts: _bankAccounts,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ تم حفظ الإعدادات'), backgroundColor: AppColors.ok));
      Navigator.pop(context);
    }
  }

  void _addBankAccount() {
    final bankCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة حساب بنكي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'اسم البنك')),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم صاحب الحساب')),
            const SizedBox(height: 8),
            TextField(controller: accCtrl, decoration: const InputDecoration(labelText: 'رقم الحساب')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (bankCtrl.text.isNotEmpty && accCtrl.text.isNotEmpty) {
                setState(() {
                  _bankAccounts.add(BankAccount(
                    bankName: bankCtrl.text.trim(),
                    accountName: nameCtrl.text.trim(),
                    accountNumber: accCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
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
            TextField(controller: _schoolNameCtrl, decoration: _inputDecoration(context, 'اسم المدرسة')),
            const SizedBox(height: 12),
            TextField(controller: _accountantNameCtrl, decoration: _inputDecoration(context, 'اسم المحاسب')),
          ]),

          // إدارة الحسابات البنكية
          _buildCard('الحسابات البنكية (للتحويلات)', [
            if (_bankAccounts.isEmpty)
              const Text('لا توجد حسابات مضافة', style: TextStyle(color: Colors.grey)),
            ..._bankAccounts.asMap().entries.map((entry) {
              final index = entry.key;
              final acc = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${acc.bankName} - ${acc.accountName}'),
                  subtitle: Text('${acc.accountNumber} • ${acc.phone}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _bankAccounts.removeAt(index)),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _addBankAccount,
              icon: const Icon(Icons.add),
              label: const Text('إضافة حساب بنكي جديد'),
            ),
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
                _pickColorBtn(context, themeProv, 'primary'),
              ],
            ),
            const Divider(height: 30),
            const Text('لون حدود البطاقات:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorDot(const Color(0xFFE2E8F0), themeProv, 'cardBorder'),
                _colorDot(const Color(0xFFD97706), themeProv, 'cardBorder'),
                _colorDot(const Color(0xFF0F766E), themeProv, 'cardBorder'),
                _colorDot(const Color(0xFF2563EB), themeProv, 'cardBorder'),
                _pickColorBtn(context, themeProv, 'cardBorder'),
              ],
            ),
            const Divider(height: 30),
            const Text('لون حدود مربعات الإدخال:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorDot(const Color(0xFFE2E8F0), themeProv, 'inputBorder'),
                _colorDot(const Color(0xFFD97706), themeProv, 'inputBorder'),
                _colorDot(const Color(0xFF0F766E), themeProv, 'inputBorder'),
                _colorDot(const Color(0xFF2563EB), themeProv, 'inputBorder'),
                _pickColorBtn(context, themeProv, 'inputBorder'),
              ],
            ),
            const Divider(height: 30),
            const Text('لون حدود أزرار الاختيار:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorDot(const Color(0xFFE2E8F0), themeProv, 'chipBorder'),
                _colorDot(const Color(0xFFD97706), themeProv, 'chipBorder'),
                _colorDot(const Color(0xFF0F766E), themeProv, 'chipBorder'),
                _colorDot(const Color(0xFF2563EB), themeProv, 'chipBorder'),
                _pickColorBtn(context, themeProv, 'chipBorder'),
              ],
            ),
          ]),

          _buildCard('نسب الأقساط الافتراضية', [
            Row(
              children: [
                Expanded(child: TextField(controller: _pctA, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'قسط أول %'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _pctB, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'قسط ثاني %'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _pctC, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'قسط أخير %'))),
              ],
            ),
          ]),

          _buildCard('إعدادات التنبيهات', [
            const Text('التنبيهات قبل الاستحقاق (أيام):', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _warnDays1, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'التنبيه الأول'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _warnDays2, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'التنبيه الثاني'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _warnDays3, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'التنبيه الثالث'))),
              ],
            ),
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
      if (type == 'primary') {
        themeProv.changePrimaryColor(selected);
      } else if (type == 'cardBorder') {
        themeProv.changeCardBorderColor(selected.withOpacity(0.6));
      } else if (type == 'inputBorder') {
        themeProv.changeInputBorderColor(selected);
      } else if (type == 'chipBorder') {
        themeProv.changeChipBorderColor(selected);
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

  InputDecoration _inputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.inputBorder(context), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary(context), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _colorDot(Color color, ThemeProvider themeProv, String type) {
    Color currentColor;
    bool isSelected;
    
    if (type == 'primary') {
      currentColor = themeProv.primaryColor;
      isSelected = currentColor == color;
    } else if (type == 'cardBorder') {
      currentColor = themeProv.cardBorderColor;
      isSelected = currentColor.withOpacity(0.6) == color.withOpacity(0.6);
    } else if (type == 'inputBorder') {
      currentColor = themeProv.inputBorderColor;
      isSelected = currentColor == color;
    } else {
      currentColor = themeProv.chipBorderColor;
      isSelected = currentColor == color;
    }

    return GestureDetector(
      onTap: () {
        if (type == 'primary') themeProv.changePrimaryColor(color);
        else if (type == 'cardBorder') themeProv.changeCardBorderColor(color);
        else if (type == 'inputBorder') themeProv.changeInputBorderColor(color);
        else themeProv.changeChipBorderColor(color);
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
