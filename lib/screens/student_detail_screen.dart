import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import '../widgets/payment_dialog.dart';
import 'student_form_screen.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final student = app.getStudentById(studentId);

    if (student == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('الطالب'),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('الطالب غير موجود')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        title: Text(student.name),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StudentFormScreen(student: student)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, app, student),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSummaryCard(student),
          const SizedBox(height: 12),
          _buildInstallmentsSection(context, student),
          const SizedBox(height: 12),
          _buildPaymentsHistory(context, app, student),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPaymentDialog(context, student),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add),
        label: const Text('تسجيل دفعة'),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppProvider app, Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text(
            'هل تريد حذف «${s.name}» نهائياً؟\n\nسيتم حذف جميع دفعاته أيضاً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: kNoneColor, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.deleteStudent(s.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildSummaryCard(Student s) {
    final pct = s.paidPct;
    final c = pct >= 1
        ? kOkColor
        : pct > 0
            ? kPartialColor
            : kNoneColor;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: c.withOpacity(0.15),
                  child: Icon(Icons.person, color: c, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${stageName(s.stage)} — ${classNames[s.cls - 1]}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pct >= 1
                        ? '✓ مكتمل'
                        : pct > 0
                            ? 'جزئي'
                            : 'لم يدفع',
                    style: TextStyle(
                        color: c, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _finItem('المطلوب', money(s.totalRequired),
                    color: Colors.blueGrey),
                _finItem('المدفوع', money(s.totalPaid), color: kOkColor),
                _finItem('المتبقي', money(s.remaining), color: kNoneColor),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: c,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(pct * 100).toStringAsFixed(0)}% مسدد',
              style: TextStyle(
                  fontSize: 11, color: c, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _finItem(String label, String value, {required Color color}) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentsSection(BuildContext context, Student s) {
    final items = <Widget>[];

    if (s.hasReg) {
      items.add(_installmentCard(context, s, FeeType.reg,
          'رسوم التسجيل', s.feeReg, s.paidFor(FeeType.reg), null));
    }

    items.add(_installmentCard(context, s, FeeType.inst1, 'القسط الأول',
        s.inst1, s.paidFor(FeeType.inst1), null));

    items.add(_installmentCard(context, s, FeeType.inst2, 'القسط الثاني',
        s.inst2, s.paidFor(FeeType.inst2), s.due2));

    items.add(_installmentCard(context, s, FeeType.inst3, 'القسط الثالث',
        s.inst3, s.paidFor(FeeType.inst3), s.due3));

    if (s.hasExam) {
      items.add(_installmentCard(context, s, FeeType.exam,
          'رسوم الامتحانات', s.feeExam, s.paidFor(FeeType.exam), null));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8, right: 4),
          child: Text('الأقساط والرسوم',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        ...items,
      ],
    );
  }

  Widget _installmentCard(BuildContext context, Student s, FeeType type,
      String label, double amount, double paid, DateTime? due) {
    final rem = (amount - paid).clamp(0.0, double.infinity);

    Color c;
    String status;
    if (rem == 0 && amount > 0) {
      c = kOkColor;
      status = '✓ مكتمل';
    } else if (paid > 0) {
      c = kPartialColor;
      status = 'جزئي';
    } else {
      c = kNoneColor;
      status = 'غير مسدد';
    }

    int? days;
    if (due != null && rem > 0) days = daysUntil(due);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 10.5,
                          color: c,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _amt('المطلوب', amount),
                _amt('المدفوع', paid, color: kOkColor),
                _amt('المتبقي', rem, color: kNoneColor),
              ],
            ),
            if (days != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: days < 0
                      ? Colors.red.shade50
                      : days <= 14
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      days < 0 ? Icons.warning : Icons.access_time,
                      size: 14,
                      color: days < 0
                          ? kNoneColor
                          : days <= 14
                              ? kPartialColor
                              : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      days < 0
                          ? 'متأخر ${days.abs()} يوم — ${dateStr(due)}'
                          : days == 0
                              ? 'يستحق اليوم — ${dateStr(due)}'
                              : 'يستحق بعد $days يوم — ${dateStr(due)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: days < 0
                            ? kNoneColor
                            : days <= 14
                                ? kPartialColor
                                : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (rem > 0) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showPaymentDialog(
                    context,
                    s,
                    presetType: type,
                    presetAmount: rem,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                    side: const BorderSide(color: kPrimaryColor),
                  ),
                  icon: const Icon(Icons.payment, size: 16),
                  label: Text('دفع ${money(rem)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amt(String l, double v, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(l,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            money(v),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsHistory(
      BuildContext context, AppProvider app, Student s) {
    final payments = [...s.payments];
    payments.sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('سجل الدفعات',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${payments.length} دفعة',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        if (payments.isEmpty)
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('لا توجد دفعات مسجلة',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          )
        else
          ...payments.map((p) => _paymentTile(context, app, s, p)),
      ],
    );
  }

  Widget _paymentTile(
      BuildContext context, AppProvider app, Student s, Payment p) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: p.method == PaymentMethod.cash
              ? Colors.green.shade50
              : Colors.blue.shade50,
          child: Icon(
            p.method == PaymentMethod.cash
                ? Icons.payments
                : Icons.account_balance,
            size: 18,
            color: p.method == PaymentMethod.cash
                ? Colors.green.shade700
                : Colors.blue.shade700,
          ),
        ),
        title: Text(
          feeTypeLabel(p.type),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          '${dateStr(p.date)} • ${methodLabel(p.method)} • ${p.reference}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              money(p.amount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  fontSize: 13),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('حذف الدفعة'),
                    content: Text(
                        'حذف دفعة بمبلغ ${money(p.amount)}؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kNoneColor,
                            foregroundColor: Colors.white),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await app.removePayment(s.id, p.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
