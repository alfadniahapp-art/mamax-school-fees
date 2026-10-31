import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

Future<void> showPaymentDialog(
  BuildContext context,
  Student student, {
  FeeType? presetType,
  double? presetAmount,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(
      studentId: student.id,
      presetType: presetType,
      presetAmount: presetAmount,
    ),
  );
}

class _PaymentSheet extends StatefulWidget {
  final String studentId;
  final FeeType? presetType;
  final double? presetAmount;

  const _PaymentSheet({
    required this.studentId,
    this.presetType,
    this.presetAmount,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late FeeType _type;
  PaymentMethod _method = PaymentMethod.cash;
  late TextEditingController _amount;
  final _reference = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final student = app.getStudentById(widget.studentId)!;

    if (widget.presetType != null) {
      _type = widget.presetType!;
    } else {
      _type = _firstUnpaidType(student);
    }

    final rem = student.remainingFor(_type);
    _amount = TextEditingController(
      text: widget.presetAmount != null
          ? widget.presetAmount!.toStringAsFixed(0)
          : (rem > 0 ? rem.toStringAsFixed(0) : ''),
    );
  }

  FeeType _firstUnpaidType(Student s) {
    if (s.hasReg && s.remainingFor(FeeType.reg) > 0) return FeeType.reg;
    if (s.hasExam && s.remainingFor(FeeType.exam) > 0) return FeeType.exam;
    if (s.remainingFor(FeeType.inst1) > 0) return FeeType.inst1;
    if (s.remainingFor(FeeType.inst2) > 0) return FeeType.inst2;
    if (s.remainingFor(FeeType.inst3) > 0) return FeeType.inst3;
    return FeeType.inst1;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final app = context.read<AppProvider>();
    final student = app.getStudentById(widget.studentId)!;
    final amount = double.tryParse(_amount.text) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل مبلغاً صحيحاً')),
      );
      return;
    }

    await app.addPayment(
      widget.studentId,
      Payment(
        id: app.newId(),
        type: _type,
        amount: amount,
        method: _method,
        reference: _reference.text.trim(),
        date: _date,
      ),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ تم تسجيل دفعة بمبلغ ${money(amount)}'),
          backgroundColor: AppColors.ok,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final student = app.getStudentById(widget.studentId)!;
    final rem = student.remainingFor(_type);

    final options = <FeeType>[];
    if (student.hasReg) options.add(FeeType.reg);
    if (student.hasExam) options.add(FeeType.exam);
    options.add(FeeType.inst1);
    options.add(FeeType.inst2);
    options.add(FeeType.inst3);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.payment, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تسجيل دفعة - ${student.name}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<FeeType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'نوع الرسوم / القسط'),
              items: options.map((t) {
                final r = student.remainingFor(t);
                return DropdownMenuItem(
                  value: t,
                  child: Text(
                    '${feeTypeLabel(t)} — متبقي ${money(r)}',
                    style: TextStyle(
                      color: r > 0 ? Colors.black : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _type = v;
                  final r = student.remainingFor(v);
                  if (r > 0) _amount.text = r.toStringAsFixed(0);
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ',
                helperText: 'المتبقي: ${money(rem)}',
                suffixIcon: rem > 0
                    ? IconButton(
                        icon: const Icon(Icons.auto_fix_high, size: 20),
                        onPressed: () => setState(
                            () => _amount.text = rem.toStringAsFixed(0)),
                      )
                    : null,
              ),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'أدخل مبلغاً صحيحاً';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              value: _method,
              decoration: const InputDecoration(labelText: 'طريقة التسديد'),
              items: const [
                DropdownMenuItem(
                  value: PaymentMethod.cash,
                  child: Text('💵 كاش'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.bank,
                  child: Text('🏦 تحويل بنكي'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _method = v;
                  _reference.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reference,
              decoration: InputDecoration(
                labelText: _method == PaymentMethod.cash
                    ? 'اسم المستلم'
                    : 'رقم العملية',
                prefixIcon: Icon(
                  _method == PaymentMethod.cash
                      ? Icons.person
                      : Icons.confirmation_number,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الدفع',
                  suffixIcon: Icon(Icons.calendar_today, size: 20),
                ),
                child: Text(dateStr(_date)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('تأكيد الدفع'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
