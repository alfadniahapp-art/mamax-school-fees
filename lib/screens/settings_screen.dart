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
  late TextEditingController _pctA, _pctB, _pctC, _warnDays, _alertRepeat;
  late TextEditingController _bankName, _bankAcc, _bankPhone;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppProvider>().settings;
    _pctA = TextEditingController(text: s.pctA.toStringAsFixed(0));
    _pctB = TextEditingController(text: s.pctB.toStringAsFixed(0));
    _pctC = TextEditingController(text: s.pctC.toStringAsFixed(0));
    _warnDays = TextEditingController(text: '${s.warnDays}');
    _alertRepeat = TextEditingController(text: '${s.alertRepeatCount}');
    _bankName = TextEditingController(text: s.bankAccountName);
    _bankAcc = TextEditingController(text: s.bankAccountNumber);
    _bankPhone = TextEditingController(text: s.bankPhone);
  }

  @override
  void dispose() {
    _pctA.dispose();
    _pctB.dispose();
    _pctC.dispose();
    _warnDays.dispose();
    _alertRepeat.dispose();
    _bankName.dispose();
    _bankAcc.dispose();
    _bankPhone.dispose();
    super.dispose();
  }

  double get _sumPct =>
      (double.tryParse(_pctA.text) ?? 0) +
      (double.tryParse(_pctB.text) ?? 0) +
      (double.tryParse(_pctC.text) ?? 0);

  Future<void> _save() async {
    if (_sumPct != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'مجموع النسب يجب أن يكون 100% (الحالي ${_sumPct.toStringAsFixed(0)}%)'),
          backgroundColor: kNoneColor,
        ),
      );
      return;
    }

    final app = context.read<AppProvider>();
    await app.saveSettings(AppSettings(
      pctA: double.tryParse(_pctA.text) ?? 50,
      pctB: double.tryParse(_pctB.text) ?? 25,
      pctC: double.tryParse(_pctC.text) ?? 25,
      warnDays: int.tryParse(_warnDays.text) ?? 14,
      alertRepeatCount: int.tryParse(_alertRepeat.text) ?? 1,
      bankAccountName: _bankName.text.trim(),
      bankAccountNumber: _bankAcc.text.trim(),
      bankPhone: _bankPhone.text.trim(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ تم حفظ الإعدادات بنجاح'),
          backgroundColor: kOkColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'حفظ',
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ============ النسب ============
          _card(
            title: 'نسب توزيع الأقساط',
            icon: Icons.pie_chart,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _numField('القسط الأول %', _pctA,
                          onChanged: (_) => setState(() {})),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numField('القسط الثاني %', _pctB,
                          onChanged: (_) => setState(() {})),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numField('القسط الأخير %', _pctC,
                          onChanged: (_) => setState(() {})),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _sumPct == 100
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _sumPct == 100
                            ? Icons.check_circle
                            : Icons.warning,
                        size: 16,
                        color: _sumPct == 100 ? kOkColor : kNoneColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'المجموع: ${_sumPct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _sumPct == 100 ? kOkColor : kNoneColor,
                        ),
                      ),
                      const Spacer(),
                      if (_sumPct != 100)
                        Text(
                          'يجب أن يساوي 100%',
                          style: TextStyle(
                            fontSize: 11,
                            color: kNoneColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ============ التنبيهات ============
          _card(
            title: 'إعدادات التنبيهات',
            icon: Icons.notifications_active,
            child: Column(
              children: [
                _numField('تنبيه قبل الاستحقاق بـ (أيام)', _warnDays,
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 10),
                _numField('عدد تكرار التنبيه', _alertRepeat),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'سيتم تنبيهك قبل ${_warnDays.text} يوم من تاريخ استحقاق أي قسط، وحتى يوم الاستحقاق نفسه.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ============ بنكك ============
          _card(
            title: 'بيانات الحساب البنكي (بنكك)',
            icon: Icons.account_balance,
            child: Column(
              children: [
                _textField('اسم صاحب الحساب', _bankName,
                    icon: Icons.person),
                const SizedBox(height: 10),
                _textField('رقم الحساب', _bankAcc,
                    icon: Icons.numbers, type: TextInputType.number),
                const SizedBox(height: 10),
                _textField('رقم الهاتف', _bankPhone,
                    icon: Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.teal.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'تظهر هذه البيانات عند اختيار طريقة الدفع "تحويل بنكي" لتسهيل عملية التحويل.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ============ إحصائيات عامة ============
          _card(
            title: 'ملخص عام',
            icon: Icons.analytics,
            child: Consumer<AppProvider>(
              builder: (_, app, __) => Column(
                children: [
                  _infoRow('عدد الطلاب', '${app.students.length}'),
                  _infoRow('إجمالي المطلوب', money(app.totalRequired)),
                  _infoRow('إجمالي المدفوع', money(app.totalPaid),
                      color: kOkColor),
                  _infoRow('إجمالي المتبقي', money(app.totalRemaining),
                      color: kNoneColor),
                  _infoRow('عدد التنبيهات', '${app.allAlerts.length}',
                      color: kPartialColor),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.save),
            label: const Text('حفظ الإعدادات',
                style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: kPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kPrimaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController c,
      {Function(String)? onChanged}) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }

  Widget _textField(String label, TextEditingController c,
      {IconData? icon, TextInputType? type}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
