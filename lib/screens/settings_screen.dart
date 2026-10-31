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
  late TextEditingController _bankName, _bankAcc, _bankPhone, _pin;

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
    _pin = TextEditingController();
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
    if (_pin.text.length >= 4) {
      await app.savePin(_pin.text.trim());
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ تم الحفظ')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card('كلمة السر (PIN)', [
            TextField(controller: _pin, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كلمة سر جديدة (اتركها فارغة لعدم التغيير)')),
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
          _card('التنبيهات', [
            TextField(controller: _warnDays, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'التنبيه قبل (أيام)')),
          ]),
          _card('حساب البنك', [
            TextField(controller: _bankName, decoration: const InputDecoration(labelText: 'اسم صاحب الحساب')),
            const SizedBox(height: 8),
            TextField(controller: _bankAcc, decoration: const InputDecoration(labelText: 'رقم الحساب')),
            const SizedBox(height: 8),
            TextField(controller: _bankPhone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('حفظ الإعدادات')),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
