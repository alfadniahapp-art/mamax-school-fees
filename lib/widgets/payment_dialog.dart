import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../models/student.dart';
import '../models/settings.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

Future<void> showPaymentDialog(BuildContext context, Student student, {FeeType? presetType, double? presetAmount}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(studentId: student.id, presetType: presetType, presetAmount: presetAmount),
  );
}

class _PaymentSheet extends StatefulWidget {
  final String studentId;
  final FeeType? presetType;
  final double? presetAmount;
  const _PaymentSheet({required this.studentId, this.presetType, this.presetAmount});
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
  bool _isFullPayment = false;
  
  BankAccount? _selectedBankAccount;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final student = app.getStudentById(widget.studentId)!;
    _type = widget.presetType ?? _firstUnpaidType(student);
    final rem = student.remainingFor(_type);
    _amount = TextEditingController(
      text: widget.presetAmount != null ? widget.presetAmount!.toStringAsFixed(0) : (rem > 0 ? rem.toStringAsFixed(0) : ''),
    );
    if (widget.presetAmount != null && widget.presetAmount == student.remaining) {
      _isFullPayment = true;
    }
  }

  FeeType _firstUnpaidType(Student s) {
    if (s.remainingFor(FeeType.inst1) > 0) return FeeType.inst1;
    if (s.remainingFor(FeeType.inst2) > 0) return FeeType.inst2;
    if (s.remainingFor(FeeType.inst3) > 0) return FeeType.inst3;
    if (s.hasReg && s.remainingFor(FeeType.reg) > 0) return FeeType.reg;
    if (s.hasExam && s.remainingFor(FeeType.exam) > 0) return FeeType.exam;
    return FeeType.inst1;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_method == PaymentMethod.bank && _selectedBankAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الحساب البنكي'), backgroundColor: AppColors.none));
      return;
    }

    final app = context.read<AppProvider>();
    final student = app.getStudentById(widget.studentId)!;
    final amount = double.tryParse(_amount.text) ?? 0;

    if (amount <= 0) return;

    final bankAccId = _method == PaymentMethod.bank ? _selectedBankAccount!.accountNumber : '';

    await app.addPayment(widget.studentId, Payment(
      id: app.newId(),
      type: _isFullPayment ? FeeType.inst1 : _type,
      amount: amount,
      method: _method,
      reference: _reference.text.trim(),
      date: _date,
      bankAccountId: bankAccId,
      isFullPayment: _isFullPayment,
    ));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ تم تسجيل دفعة بمبلغ ${money(amount)}'),
        backgroundColor: AppColors.ok,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final student = app.getStudentById(widget.studentId)!;
    final rem = student.remaining;
    final bankAccounts = app.settings.bankAccounts;

    final options = <FeeType>[];
    if (student.hasReg) options.add(FeeType.reg);
    if (student.hasExam) options.add(FeeType.exam);
    options.addAll([FeeType.inst1, FeeType.inst2, FeeType.inst3]);

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('تسجيل دفعة - ${student.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('سداد كامل المديونية', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('المتبقي الكلي: ${money(rem)}', style: const TextStyle(fontSize: 12)),
              value: _isFullPayment,
              onChanged: (v) {
                setState(() {
                  _isFullPayment = v;
                  if (v) {
                    _amount.text = rem.toStringAsFixed(0);
                  } else {
                    final firstRem = student.remainingFor(_type);
                    _amount.text = firstRem.toStringAsFixed(0);
                  }
                });
              },
            ),
            const Divider(),

            // يختفي حقل النوع عند تفعيل السداد الكامل
            if (!_isFullPayment) ...[
              DropdownButtonFormField<FeeType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'نوع الرسوم / القسط'),
                items: options.map((t) => DropdownMenuItem(value: t, child: Text('${feeTypeLabel(t)} — متبقي ${money(student.remainingFor(t))}'))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() { _type = v; _amount.text = student.remainingFor(v).toStringAsFixed(0); });
                },
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isFullPayment ? 'المبلغ الإجمالي للسداد' : 'المبلغ',
                helperText: _isFullPayment ? 'سيتم إلغاء جميع الأقساط' : 'المتبقي: ${money(rem)}',
              ),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'أدخل مبلغاً صحيحاً' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<PaymentMethod>(
              value: _method,
              decoration: const InputDecoration(labelText: 'طريقة التسديد'),
              items: const [
                DropdownMenuItem(value: PaymentMethod.cash, child: Text('💵 كاش')),
                DropdownMenuItem(value: PaymentMethod.bank, child: Text('🏦 تحويل بنكي')),
              ],
              onChanged: (v) { 
                if (v != null) {
                  setState(() {
                    _method = v;
                    _selectedBankAccount = null;
                  });
                } 
              },
            ),

            if (_method == PaymentMethod.bank) ...[
              const SizedBox(height: 16),
              if (bankAccounts.isEmpty)
                const Text('لا توجد حسابات بنكية مضافة. يرجى إضافتها من الإعدادات.', style: TextStyle(color: Colors.red, fontSize: 12))
              else
                DropdownButtonFormField<BankAccount>(
                  value: _selectedBankAccount,
                  decoration: const InputDecoration(labelText: 'اختر الحساب البنكي'),
                  items: bankAccounts.map((b) => DropdownMenuItem(
                    value: b,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${b.bankName} - ${b.accountName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('رقم الحساب: ${b.accountNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedBankAccount = v),
                ),
              
              if (_selectedBankAccount != null)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.bg(context), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اسم البنك: ${_selectedBankAccount!.bankName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('اسم صاحب الحساب: ${_selectedBankAccount!.accountName}'),
                      Text('رقم الحساب: ${_selectedBankAccount!.accountNumber}'),
                      Text('رقم الهاتف: ${_selectedBankAccount!.phone}'),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 16),
            TextFormField(
              controller: _reference,
              decoration: InputDecoration(labelText: _method == PaymentMethod.cash ? 'اسم المستلم' : 'رقم العملية'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('تأكيد الدفع')),
          ],
        ),
      ),
    );
  }
}
