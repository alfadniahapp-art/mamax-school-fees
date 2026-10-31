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
    if (d != null) {
      setState(() => isFrom ? _from = d : _to = d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    var list = app.getAllPayments(
      from: _from,
      to: _to,
      method: _method,
      stage: _stage,
    );

    if (_search.isNotEmpty) {
      list = list
          .where((x) =>
              ((x['student'] as Student).name.contains(_search)))
          .toList();
    }

    final total = list.fold(
        0.0, (s, x) => s + (x['payment'] as Payment).amount);
    final avg = list.isEmpty ? 0.0 : total / list.length;
    final uniqueStudents =
        list.map((x) => (x['student'] as Student).id).toSet().length;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        title: const Text('سجل الدفعات'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStats(list.length, total, avg, uniqueStudents),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('لا توجد دفعات مطابقة',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final x = list[i];
                      return _paymentTile(
                          x['student'] as Student, x['payment'] as Payment);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'بحث بالاسم...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: (v) => setState(() => _search = v.trim()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'من تاريخ',
                      prefixIcon: const Icon(Icons.calendar_today, size: 16),
                      suffixIcon: _from != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _from = null))
                          : null,
                    ),
                    child: Text(_from == null ? 'الكل' : dateStr(_from)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'إلى تاريخ',
                      prefixIcon: const Icon(Icons.calendar_today, size: 16),
                      suffixIcon: _to != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _to = null))
                          : null,
                    ),
                    child: Text(_to == null ? 'الكل' : dateStr(_to)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PaymentMethod?>(
                  value: _method,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'طريقة الدفع',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(
                        value: PaymentMethod.cash, child: Text('كاش')),
                    DropdownMenuItem(
                        value: PaymentMethod.bank, child: Text('بنك')),
                  ],
                  onChanged: (v) => setState(() => _method = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<Stage?>(
                  value: _stage,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'المرحلة',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(
                        value: Stage.primary, child: Text('ابتدائي')),
                    DropdownMenuItem(
                        value: Stage.middle, child: Text('متوسط')),
                    DropdownMenuItem(
                        value: Stage.high, child: Text('ثانوي')),
                  ],
                  onChanged: (v) => setState(() => _stage = v),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'تفريغ الفلاتر',
                icon: const Icon(Icons.refresh),
                onPressed: _reset,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int count, double total, double avg, int students) {
    return Container(
      color: kPrimaryColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          _stat('عدد الدفعات', '$count'),
          _stat('إجمالي', money(total), color: Colors.green.shade200),
          _stat('متوسط', money(avg)),
          _stat('طلاب', '$students'),
        ],
      ),
    );
  }

  Widget _stat(String l, String v, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(l,
              style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withOpacity(0.85))),
          const SizedBox(height: 2),
          Text(v,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.white,
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _paymentTile(Student s, Payment p) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: s.id)),
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: p.method == PaymentMethod.cash
              ? Colors.green.shade50
              : Colors.blue.shade50,
          child: Icon(
            p.method == PaymentMethod.cash
                ? Icons.payments
                : Icons.account_balance,
            color: p.method == PaymentMethod.cash
                ? Colors.green.shade700
                : Colors.blue.shade700,
          ),
        ),
        title: Text(
          s.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        subtitle: Text(
          '${dateStr(p.date)} • ${feeTypeLabel(p.type)} • ${p.reference}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              money(p.amount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  fontSize: 14),
            ),
            Text(
              methodLabel(p.method),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
