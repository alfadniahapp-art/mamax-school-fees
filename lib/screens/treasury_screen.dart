import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class TreasuryScreen extends StatelessWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    
    final totalDeposits = app.transactions.where((tx) => tx.type == 'deposit').fold(0.0, (s, e) => s + e.amount);
    final totalWithdraws = app.transactions.where((tx) => tx.type == 'withdraw').fold(0.0, (s, e) => s + e.amount);
    final currentBalance = totalDeposits - totalWithdraws;

    return Scaffold(
      backgroundColor: AppColors.bg(context), // خلفية الثيم الملكية
      appBar: AppBar(
        title: const Text('الخزينة والحسابات', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة الرصيد الحالي (بتصميم ملكي)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary(context), AppColors.primary(context).withOpacity(0.7)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary(context).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Column(
              children: [
                const Text('الرصيد الحالي (الإجمالي)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                Text(money(currentBalance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // بطاقات الإجماليات
          Row(
            children: [
              Expanded(child: _balanceCard(context, 'إجمالي الإيداعات', totalDeposits, Icons.arrow_downward, AppColors.ok)),
              const SizedBox(width: 16),
              Expanded(child: _balanceCard(context, 'إجمالي السحوبات', totalWithdraws, Icons.arrow_upward, AppColors.none)),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _balanceCard(context, 'رصيد الصندوق', app.cashBalance, Icons.money, Colors.green.shade600)),
              const SizedBox(width: 16),
              Expanded(child: _balanceCard(context, 'رصيد البنك', app.bankBalance, Icons.account_balance, Colors.blue.shade600)),
            ],
          ),
          const SizedBox(height: 24),
          
          // أزرار العمليات
          Row(
            children: [
              Expanded(child: _actionBtn('إيداع', Icons.add_circle, Colors.green.shade600, () => _showTransactionDialog(context, 'deposit'))),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('سحب', Icons.remove_circle, Colors.red.shade600, () => _showTransactionDialog(context, 'withdraw'))),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('تحويل', Icons.swap_horiz, Colors.orange.shade600, () => _showTransactionDialog(context, 'transfer'))),
            ],
          ),
          const SizedBox(height: 30),
          
          // سجل العمليات
          Text('سجل العمليات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark(context))),
          const SizedBox(height: 12),
          if (app.transactions.isEmpty)
            const Center(child: Text('لا توجد عمليات مالية', style: TextStyle(color: Colors.grey)))
          else
            ...app.transactions.reversed.map((tx) => _buildTxCard(context, tx)),
        ],
      ),
    );
  }

  Widget _balanceCard(BuildContext context, String label, double balance, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppColors.cardBorder(context), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(money(balance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, 
        foregroundColor: Colors.white, 
        padding: const EdgeInsets.symmetric(vertical: 16), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        shadowColor: color.withOpacity(0.4),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24), 
          const SizedBox(height: 6), 
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
        ]
      ),
    );
  }

  Widget _buildTxCard(BuildContext context, FinancialTransaction tx) {
    final isDeposit = tx.type == 'deposit';
    final isWithdraw = tx.type == 'withdraw';
    final color = isDeposit ? AppColors.ok : isWithdraw ? AppColors.none : AppColors.secondary;
    final label = isDeposit ? 'إيداع' : isWithdraw ? 'سحب' : 'تحويل';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppColors.cardBorder(context), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1), 
          child: Icon(isDeposit ? Icons.arrow_downward : isWithdraw ? Icons.arrow_upward : Icons.swap_horiz, color: color, size: 20)
        ),
        title: Text('$label - ${tx.entityName}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark(context))),
        subtitle: Text('${dateStr(tx.date)} • ${tx.method == 'cash' ? 'كاش' : 'بنك'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(money(tx.amount), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showTransactionDialog(context, tx.type, existingTx: tx);
                if (value == 'delete') _deleteTx(context, tx);
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                const PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTx(BuildContext context, FinancialTransaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العملية'),
        content: const Text('هل أنت متأكد من حذف هذه العملية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteTransaction(tx.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTransactionDialog(BuildContext context, String type, {FinancialTransaction? existingTx}) {
    final entityCtrl = TextEditingController(text: existingTx?.entityName ?? '');
    final amountCtrl = TextEditingController(text: existingTx?.amount.toString() ?? '');
    final bankNameCtrl = TextEditingController(text: existingTx?.bankName ?? '');
    final accHolderCtrl = TextEditingController(text: existingTx?.accountHolderName ?? '');
    final refCtrl = TextEditingController(text: existingTx?.referenceNumber ?? '');
    
    String method = existingTx?.method ?? 'cash';
    String fromAcc = existingTx?.fromAccount ?? 'cash';
    String toAcc = existingTx?.toAccount ?? 'bank';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(color: AppColors.bg(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text(existingTx != null ? 'تعديل العملية' : (type == 'deposit' ? 'إيداع جديد' : type == 'withdraw' ? 'سحب جديد' : 'تحويل جديد'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark(context))),
                  const SizedBox(height: 20),
                  
                  TextField(controller: entityCtrl, decoration: _dialogInputDecoration(context, type == 'deposit' ? 'اسم المودع' : 'جهة السحب'), keyboardType: TextInputType.text),
                  const SizedBox(height: 12),
                  TextField(controller: amountCtrl, decoration: _dialogInputDecoration(context, 'المبلغ'), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  
                  if (type == 'transfer') ...[
                    DropdownButtonFormField<String>(value: fromAcc, decoration: _dialogInputDecoration(context, 'من حساب'), items: const [DropdownMenuItem(value: 'cash', child: Text('الصندوق')), DropdownMenuItem(value: 'bank', child: Text('البنك'))], onChanged: (v) => setState(() => fromAcc = v!)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(value: toAcc, decoration: _dialogInputDecoration(context, 'إلى حساب'), items: const [DropdownMenuItem(value: 'cash', child: Text('الصندوق')), DropdownMenuItem(value: 'bank', child: Text('البنك'))], onChanged: (v) => setState(() => toAcc = v!)),
                  ] else ...[
                    DropdownButtonFormField<String>(value: method, decoration: _dialogInputDecoration(context, 'طريقة الدفع'), items: const [DropdownMenuItem(value: 'cash', child: Text('كاش (صندوق)')), DropdownMenuItem(value: 'bank', child: Text('بنك'))], onChanged: (v) => setState(() => method = v!)),
                  ],

                  if (method == 'bank' && type != 'transfer') ...[
                    const SizedBox(height: 12),
                    TextField(controller: bankNameCtrl, decoration: _dialogInputDecoration(context, 'اسم البنك')),
                    const SizedBox(height: 12),
                    TextField(controller: accHolderCtrl, decoration: _dialogInputDecoration(context, 'اسم صاحب الحساب')),
                    const SizedBox(height: 12),
                    TextField(controller: refCtrl, decoration: _dialogInputDecoration(context, 'رقم العملية / الإيصال')),
                  ],
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (amount > 0 && entityCtrl.text.isNotEmpty) {
                          final newTx = FinancialTransaction(
                            id: existingTx?.id ?? context.read<AppProvider>().newId(),
                            type: type,
                            method: method,
                            fromAccount: type == 'transfer' ? fromAcc : (type == 'withdraw' ? method : ''),
                            toAccount: type == 'transfer' ? toAcc : (type == 'deposit' ? method : ''),
                            entityName: entityCtrl.text.trim(),
                            amount: amount,
                            date: existingTx?.date ?? DateTime.now(),
                            bankName: bankNameCtrl.text.trim(),
                            accountHolderName: accHolderCtrl.text.trim(),
                            referenceNumber: refCtrl.text.trim(),
                          );
                          
                          if (existingTx != null) {
                            context.read<AppProvider>().updateTransaction(newTx);
                          } else {
                            context.read<AppProvider>().addTransaction(newTx);
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary(context),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(existingTx != null ? 'حفظ التعديلات' : 'تأكيد العملية', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _dialogInputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
