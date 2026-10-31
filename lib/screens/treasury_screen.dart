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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('الخزينة والحسابات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary(context), AppColors.primary(context).withOpacity(0.7)], begin: Alignment.topRight, end: Alignment.bottomLeft),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary(context).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                const Text('الرصيد الحالي', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(money(currentBalance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _balanceCard('إجمالي الإيداعات', totalDeposits, Icons.arrow_downward, AppColors.ok)),
              const SizedBox(width: 12),
              Expanded(child: _balanceCard('إجمالي السحوبات', totalWithdraws, Icons.arrow_upward, AppColors.none)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _balanceCard('رصيد الصندوق', app.cashBalance, Icons.money, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _balanceCard('رصيد البنك', app.bankBalance, Icons.account_balance, Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _actionBtn('إيداع', Icons.add_circle, Colors.green, () => _showTransactionDialog(context, 'deposit'))),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn('سحب', Icons.remove_circle, Colors.red, () => _showTransactionDialog(context, 'withdraw'))),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn('تحويل', Icons.swap_horiz, Colors.orange, () => _showTransactionDialog(context, 'transfer'))),
            ],
          ),
          const SizedBox(height: 24),
          const Text('سجل العمليات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (app.transactions.isEmpty)
            const Center(child: Text('لا توجد عمليات مالية', style: TextStyle(color: Colors.grey)))
          else
            ...app.transactions.reversed.map((tx) => _buildTxCard(context, tx)),
        ],
      ),
    );
  }

  Widget _balanceCard(String label, double balance, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(money(balance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Column(children: [Icon(icon, size: 22), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12))]),
    );
  }

  Widget _buildTxCard(BuildContext context, FinancialTransaction tx) {
    final isDeposit = tx.type == 'deposit';
    final isWithdraw = tx.type == 'withdraw';
    final color = isDeposit ? AppColors.ok : isWithdraw ? AppColors.none : AppColors.secondary;
    final label = isDeposit ? 'إيداع' : isWithdraw ? 'سحب' : 'تحويل';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(isDeposit ? Icons.arrow_downward : isWithdraw ? Icons.arrow_upward : Icons.swap_horiz, color: color, size: 18)),
        title: Text('$label - ${tx.entityName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${dateStr(tx.date)} • ${tx.method == 'cash' ? 'كاش' : 'بنك'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(money(tx.amount), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(existingTx != null ? 'تعديل العملية' : (type == 'deposit' ? 'إيداع جديد' : type == 'withdraw' ? 'سحب جديد' : 'تحويل جديد'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: entityCtrl, decoration: InputDecoration(labelText: type == 'deposit' ? 'اسم المودع' : 'جهة السحب'), keyboardType: TextInputType.text),
                  const SizedBox(height: 12),
                  TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  
                  if (type == 'transfer') ...[
                    DropdownButtonFormField<String>(value: fromAcc, decoration: const InputDecoration(labelText: 'من حساب'), items: const [DropdownMenuItem(value: 'cash', child: Text('الصندوق')), DropdownMenuItem(value: 'bank', child: Text('البنك'))], onChanged: (v) => setState(() => fromAcc = v!)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(value: toAcc, decoration: const InputDecoration(labelText: 'إلى حساب'), items: const [DropdownMenuItem(value: 'cash', child: Text('الصندوق')), DropdownMenuItem(value: 'bank', child: Text('البنك'))], onChanged: (v) => setState(() => toAcc = v!)),
                  ] else ...[
                    DropdownButtonFormField<String>(value: method, decoration: const InputDecoration(labelText: 'طريقة الدفع'), items: const [DropdownMenuItem(value: 'cash', child: Text('كاش (صندوق)')), DropdownMenuItem(value: 'bank', child: Text('بنك'))], onChanged: (v) => setState(() => method = v!)),
                  ],

                  // حقول البنك
                  if (method == 'bank' && type != 'transfer') ...[
                    const SizedBox(height: 12),
                    TextField(controller: bankNameCtrl, decoration: const InputDecoration(labelText: 'اسم البنك')),
                    const SizedBox(height: 12),
                    TextField(controller: accHolderCtrl, decoration: const InputDecoration(labelText: 'اسم صاحب الحساب')),
                    const SizedBox(height: 12),
                    TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'رقم العملية / الإيصال')),
                  ],
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
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
                      child: Text(existingTx != null ? 'حفظ التعديلات' : 'تأكيد العملية'),
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
}
