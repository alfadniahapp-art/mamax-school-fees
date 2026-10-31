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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('الملف المالي للطالب'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFormScreen(student: s))).then((_) => (context as Element).markNeedsBuild())),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.withOpacity(0.8), c], begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${stageName(s.stage)} • ${classNames[s.cls - 1]} • ${genderName(s.gender)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _whiteStat('المطلوب', money(s.totalRequired)),
                    Container(width: 1, height: 30, color: Colors.white30),
                    _whiteStat('المدفوع', money(s.totalPaid)),
                    Container(width: 1, height: 30, color: Colors.white30),
                    _whiteStat('المتبقي', money(s.remaining)),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white24, color: Colors.white, minHeight: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('سجل الأقساط والرسوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (s.hasReg) _buildInstCard(context, s, FeeType.reg, 'رسوم التسجيل', s.feeReg),
          _buildInstCard(context, s, FeeType.inst1, 'القسط الأول', s.inst1),
          _buildInstCard(context, s, FeeType.inst2, 'القسط الثاني', s.inst2),
          _buildInstCard(context, s, FeeType.inst3, 'القسط الثالث', s.inst3),
          if (s.hasExam) _buildInstCard(context, s, FeeType.exam, 'رسوم الامتحانات', s.feeExam),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _whiteStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildInstCard(BuildContext context, Student s, FeeType type, String label, double amount) {
    final paid = s.paidFor(type);
    final rem = (amount - paid).clamp(0.0, double.infinity);
    final isDone = rem == 0;
    final c = isDone ? AppColors.ok : paid > 0 ? AppColors.partial : AppColors.none;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isDone ? Icons.check_circle : Icons.circle_outlined, color: c, size: 20),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(isDone ? 'مسدد' : 'متبقي ${money(rem)}', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المبلغ الأصلي: ${money(amount)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                if (!isDone)
                  TextButton.icon(
                    onPressed: () => showPaymentDialog(context, s, presetType: type, presetAmount: rem),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('دفع الآن'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary(context)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
