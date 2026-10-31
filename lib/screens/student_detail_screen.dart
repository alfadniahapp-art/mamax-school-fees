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
    final s = app.getStudentById(studentId)!;
    final pct = s.paidPct;
    final c = pct >= 1 ? AppColors.ok : pct > 0 ? AppColors.partial : AppColors.none;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFormScreen(student: s))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('${stageName(s.stage)} - ${classNames[s.cls - 1]}', style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _finItem('المطلوب', s.totalRequired, Colors.blueGrey),
                      _finItem('المدفوع', s.totalPaid, AppColors.ok),
                      _finItem('المتبقي', s.remaining, AppColors.none),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: pct, color: c, minHeight: 8, backgroundColor: Colors.grey.shade200),
                  
                  // زر سداد كامل المبلغ
                  if (s.remaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => showPaymentDialog(context, s, presetType: FeeType.inst1, presetAmount: s.remaining),
                          icon: const Icon(Icons.payment),
                          label: const Text('سداد كامل المبلغ المتبقي'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary, // لون ذهبي مميز
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('الأقساط والرسوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (s.hasReg) _buildInstCard(context, s, FeeType.reg, 'رسوم التسجيل', s.feeReg),
          _buildInstCard(context, s, FeeType.inst1, 'القسط الأول', s.inst1),
          _buildInstCard(context, s, FeeType.inst2, 'القسط الثاني', s.inst2),
          _buildInstCard(context, s, FeeType.inst3, 'القسط الثالث', s.inst3),
          if (s.hasExam) _buildInstCard(context, s, FeeType.exam, 'رسوم الامتحانات', s.feeExam),
        ],
      ),
    );
  }

  Widget _finItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(money(value), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _buildInstCard(BuildContext context, Student s, FeeType type, String label, double amount) {
    final paid = s.paidFor(type);
    final rem = (amount - paid).clamp(0.0, double.infinity);
    final c = rem == 0 ? AppColors.ok : paid > 0 ? AppColors.partial : AppColors.none;
    final status = rem == 0 ? 'مسدد' : paid > 0 ? 'جزئي' : 'غير مسدد';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(label: Text(status), backgroundColor: c.withOpacity(0.15), labelStyle: TextStyle(color: c, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مطلوب: ${money(amount)}', style: const TextStyle(fontSize: 12)),
                Text('متبقي: ${money(rem)}', style: const TextStyle(fontSize: 12, color: AppColors.none, fontWeight: FontWeight.bold)),
              ],
            ),
            if (rem > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => showPaymentDialog(context, s, presetType: type, presetAmount: rem),
                    child: Text('دفع ${money(rem)}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
