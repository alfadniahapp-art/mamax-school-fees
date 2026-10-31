import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import 'student_detail_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  DateTime? _from;
  DateTime? _to;
  PaymentMethod? _method;
  Stage? _stage;
  String _search = '';

  void _reset() {
    setState(() {
      _from = null;
      _to = null;
      _method = null;
      _stage = null;
      _search = '';
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => isFrom ? _from = d : _to = d);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    var list = app.getAllPayments(from: _from, to: _to, method: _method, stage: _stage);

    if (_search.isNotEmpty) {
      list = list.where((x) => ((x['student'] as Student).name.contains(_search))).toList();
    }

    final total = list.fold(0.0, (s, x) => s + (x['payment'] as Payment).amount);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الدفعات')),
      body: Column(
        children: [
          _buildFilters(),
          Container(
            color: AppColors.primary(context),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('الدفعات', '${list.length}'),
                _statItem('الإجمالي', money(total)),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('لا توجد دفعات', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final x = list[i];
                      final s = x['student'] as Student;
                      final p = x['payment'] as Payment;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id))),
                          leading: CircleAvatar(
                            backgroundColor: p.method == PaymentMethod.cash ? Colors.green.shade50 : Colors.blue.shade50,
                            child: Icon(
                              p.method == PaymentMethod.cash ? Icons.payments : Icons.account_balance,
                              color: p.method == PaymentMethod.cash ? Colors.green.shade700 : Colors.blue.shade700,
                            ),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${dateStr(p.date)} • ${feeTypeLabel(p.type)} • ${p.reference}'),
                          trailing: Text(money(p.amount), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary(context), fontSize: 14)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface(context),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'بحث بالاسم...', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _dateBtn('من', _from, () => _pickDate(true), () => setState(() => _from = null))),
              const SizedBox(width: 8),
              Expanded(child: _dateBtn('إلى', _to, () => _pickDate(false), () => setState(() => _to = null))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PaymentMethod?>(
                  value: _method,
                  decoration: const InputDecoration(labelText: 'طريقة الدفع', isDense: true),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: PaymentMethod.cash, child: Text('كاش')),
                    DropdownMenuItem(value: PaymentMethod.bank, child: Text('بنك')),
                  ],
                  onChanged: (v) => setState(() => _method = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<Stage?>(
                  value: _stage,
                  decoration: const InputDecoration(labelText: 'المرحلة', isDense: true),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: Stage.primary, child: Text('ابتدائي')),
                    DropdownMenuItem(value: Stage.middle, child: Text('متوسط')),
                    DropdownMenuItem(value: Stage.high, child: Text('ثانوي')),
                  ],
                  onChanged: (v) => setState(() => _stage = v),
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateBtn(String label, DateTime? d, VoidCallback onTap, VoidCallback onClear) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixIcon: d != null ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: onClear) : null,
        ),
        child: Text(d == null ? 'الكل' : dateStr(d)),
      ),
    );
  }
}
