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
    final s = app.getStudentById(studentId);
    
    if (s == null) return const Scaffold(body: Center(child: Text('الطالب غير موجود')));

    final pct = s.paidPct;
    final c = pct >= 1 ? AppColors.ok : pct > 0 ? AppColors.partial : AppColors.none;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل بيانات الطالب',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFormScreen(student: s))).then((_) => (context as Element).markNeedsBuild()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'حذف الطالب',
            onPressed: () => _confirmDelete(context, app, s),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // البطاقة العلوية
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.withOpacity(0.9), c], begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Column(
              children: [
                Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text('${stageName(s.stage)} • ${classNames[s.cls - 1]} • ${genderName(s.gender)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _whiteStat('المطلوب', money(s.totalRequired)),
                    Container(width: 1, height: 40, color: Colors.white30),
                    _whiteStat('المدفوع', money(s.totalPaid)),
                    Container(width: 1, height: 40, color: Colors.white30),
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
          
          // زر سداد كامل المديونية
          if (s.remaining > 0) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  showPaymentDialog(context, s, presetType: FeeType.inst1, presetAmount: s.remaining);
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: Text('سداد كامل المديونية (${money(s.remaining)})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ok,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: AppColors.ok.withOpacity(0.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          Text('سجل الأقساط والرسوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark(context))),
          const SizedBox(height: 12),
          
          // عرض الأقساط
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

  void _confirmDelete(BuildContext context, AppProvider app, Student s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text('هل أنت متأكد من حذف «${s.name}» نهائياً؟\n\nسيتم حذف جميع دفعاته أيضاً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              app.deleteStudent(s.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.none),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
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
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                    Icon(isDone ? Icons.check_circle : Icons.circle_outlined, color: c, size: 22),
                    const SizedBox(width: 8),
                    Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark(context))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(isDone ? 'مسدد' : 'متبقي ${money(rem)}', style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
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
