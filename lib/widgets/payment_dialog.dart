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
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PaymentDialog(
      studentId: student.id,
      presetType: presetType,
      presetAmount: presetAmount,
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  final String studentId;
  final FeeType? presetType;
  final double? presetAmount;

  const _PaymentDialog({
    required this.studentId,
    this.presetType,
    this.presetAmount,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
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

    // اختيار النوع الافتراضي
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

    final rem = student.remainingFor(_type);
    if (amount > rem + 0.5) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تنبيه'),
          content: Text(
            'المبلغ (${money(amount)}) يتجاوز المتبقي (${money(rem)}) لهذا البند.\n\nهل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white),
              child: const Text('متابعة'),
            ),
          ],
        ),
      );
      if (ok != true) return;
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
          backgroundColor: kOkColor,
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

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.payment, color: kPrimaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تسجيل دفعة — ${student.name}',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FeeType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'نوع الرسوم'),
                items: options.map((t) {
                  final r = student.remainingFor(t);
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      '${feeTypeLabel(t)} — متبقي ${money(r)}',
                      style: TextStyle(
                        fontSize: 13,
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  helperText: 'المتبقي: ${money(rem)}',
                  suffixIcon: rem > 0
                      ? IconButton(
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          tooltip: 'ملء المتبقي',
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
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                value: _method,
                decoration:
                    const InputDecoration(labelText: 'طريقة التسديد'),
                items: const [
                  DropdownMenuItem(
                    value: PaymentMethod.cash,
                    child: Row(children: [
                      Icon(Icons.payments, size: 18),
                      SizedBox(width: 8),
                      Text('كاش'),
                    ]),
                  ),
                  DropdownMenuItem(
                    value: PaymentMethod.bank,
                    child: Row(children: [
                      Icon(Icons.account_balance, size: 18),
                      SizedBox(width: 8),
                      Text('تحويل بنكي'),
                    ]),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _reference,
                decoration: InputDecoration(
                  labelText: _method == PaymentMethod.cash
                      ? 'اسم المستلم'
                      : 'رقم العملية / الإيصال',
                  prefixIcon: Icon(
                    _method == PaymentMethod.cash
                        ? Icons.person
                        : Icons.confirmation_number,
                    size: 18,
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الدفع',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(dateStr(_date)),
                ),
              ),
              if (_method == PaymentMethod.bank &&
                  app.settings.bankAccountName.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('بيانات الحساب البنكي:',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor)),
                      const SizedBox(height: 4),
                      Text('👤 ${app.settings.bankAccountName}',
                          style: const TextStyle(fontSize: 12)),
                      Text('🏦 ${app.settings.bankAccountNumber}',
                          style: const TextStyle(fontSize: 12)),
                      if (app.settings.bankPhone.isNotEmpty)
                        Text('📱 ${app.settings.bankPhone}',
                            style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('حفظ الدفعة'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }
}
