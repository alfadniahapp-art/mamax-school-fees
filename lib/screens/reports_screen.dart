import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student.dart';
import '../models/transaction.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _reportType = 'students'; // students, treasury
  
  // فلاتر الطلاب
  String _scope = 'all';
  Stage _selectedStage = Stage.primary;
  Gender _selectedGender = Gender.boys;
  int _selectedClass = 1;
  String _paymentStatus = 'all';

  // فلترة الخزينة
  String _treasuryType = 'all';

  Future<void> _generatePdf(List<dynamic> data) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(_reportType == 'students' ? 'تقرير رسوم الطلاب' : 'تقرير الخزينة والحسابات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          if (_reportType == 'students')
            pw.TableHelper.fromTextArray(
              headers: ['الطالب', 'الفصل', 'القسم', 'المطلوب', 'المدفوع', 'المتبقي', 'الحالة'],
              data: data.map((s) {
                final pct = s.paidPct;
                final status = pct >= 1 ? 'مكتمل' : pct > 0 ? 'جزئي' : 'لم يدفع';
                return [s.name, classNames[s.cls - 1], genderName(s.gender), money(s.totalRequired), money(s.totalPaid), money(s.remaining), status];
              }).toList(),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: ['التاريخ', 'النوع', 'الجهة', 'طريقة الدفع', 'المبلغ'],
              data: data.map((FinancialTransaction tx) => [
                dateStr(tx.date), 
                tx.type == 'deposit' ? 'إيداع' : tx.type == 'withdraw' ? 'سحب' : 'تحويل', 
                tx.entityName, 
                tx.method == 'cash' ? 'كاش' : 'بنك', 
                money(tx.amount)
              ]).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    List<dynamic> reportData = [];
    if (_reportType == 'students') {
      reportData = app.students.where((s) {
        if (_scope == 'stage') return s.stage == _selectedStage;
        if (_scope == 'gender') return s.gender == _selectedGender;
        if (_scope == 'class') return s.stage == _selectedStage && s.cls == _selectedClass;
        return true;
      }).where((s) {
        if (_paymentStatus == 'paid') return s.paidPct >= 1.0;
        if (_paymentStatus == 'partial') return s.paidPct > 0 && s.paidPct < 1.0;
        if (_paymentStatus == 'unpaid') return s.paidPct == 0;
        return true;
      }).toList();
    } else {
      reportData = app.transactions.where((tx) {
        if (_treasuryType == 'all') return true;
        return tx.type == _treasuryType;
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'طباعة PDF',
            onPressed: reportData.isEmpty ? null : () => _generatePdf(reportData),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildReportTypeSelector(),
          _reportType == 'students' ? _buildStudentFilters() : _buildTreasuryFilters(),
          Expanded(
            child: reportData.isEmpty
                ? const Center(child: Text('لا توجد بيانات مطابقة', style: TextStyle(color: Colors.grey)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_reportType == 'students') ...[
                        _buildStudentSummary(reportData.cast<Student>()),
                        const SizedBox(height: 16),
                        _buildStudentTable(reportData.cast<Student>()),
                      ] else ...[
                        _buildTreasurySummary(reportData.cast<FinancialTransaction>()),
                        const SizedBox(height: 16),
                        _buildTreasuryTable(reportData.cast<FinancialTransaction>()),
                      ]
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _reportType = 'students'),
              icon: const Icon(Icons.people),
              label: const Text('تقارير الطلاب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _reportType == 'students' ? AppColors.primary(context) : Colors.grey.shade200,
                foregroundColor: _reportType == 'students' ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _reportType = 'treasury'),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('تقارير الخزينة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _reportType == 'treasury' ? AppColors.primary(context) : Colors.grey.shade200,
                foregroundColor: _reportType == 'treasury' ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تصفية حسب النطاق:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('الكل', 'all', true),
              const SizedBox(width: 4),
              _chip('مرحلة', 'stage', true),
              const SizedBox(width: 4),
              _chip('قسم', 'gender', true),
              const SizedBox(width: 4),
              _chip('فصل', 'class', true),
            ],
          ),
          const SizedBox(height: 12),
          if (_scope == 'stage' || _scope == 'class')
            DropdownButtonFormField<Stage>(value: _selectedStage, decoration: const InputDecoration(labelText: 'المرحلة', isDense: true), items: stagesList.map((s) => DropdownMenuItem(value: s.stage, child: Text(s.name))).toList(), onChanged: (v) => setState(() => _selectedStage = v!)),
          if (_scope == 'gender')
            DropdownButtonFormField<Gender>(value: _selectedGender, decoration: const InputDecoration(labelText: 'القسم', isDense: true), items: const [DropdownMenuItem(value: Gender.boys, child: Text('بنين')), DropdownMenuItem(value: Gender.girls, child: Text('بنات'))], onChanged: (v) => setState(() => _selectedGender = v!)),
          if (_scope == 'class')
            DropdownButtonFormField<int>(value: _selectedClass, decoration: const InputDecoration(labelText: 'الصف', isDense: true), items: List.generate(stageCount(_selectedStage), (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))).toList(), onChanged: (v) => setState(() => _selectedClass = v!)),
          const Divider(height: 24),
          const Text('حالة السداد:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('الكل', 'all_status', false),
              const SizedBox(width: 4),
              _chip('مكتمل', 'paid', false),
              const SizedBox(width: 4),
              _chip('جزئي', 'partial', false),
              const SizedBox(width: 4),
              _chip('لم يدفع', 'unpaid', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreasuryFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تصفية حسب نوع العملية:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _chipTreasury('الكل', 'all'),
              const SizedBox(width: 4),
              _chipTreasury('إيداعات', 'deposit'),
              const SizedBox(width: 4),
              _chipTreasury('سحوبات', 'withdraw'),
              const SizedBox(width: 4),
              _chipTreasury('تحويلات', 'transfer'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, bool isScope) {
    final isActive = isScope ? _scope == value : _paymentStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          if (isScope) _scope = value;
          else _paymentStatus = value == 'all_status' ? 'all' : value;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: isActive ? (isScope ? AppColors.primary(context) : AppColors.secondary) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(label, style: TextStyle(fontSize: 11, color: isActive ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _chipTreasury(String label, String value) {
    final isActive = _treasuryType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _treasuryType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: isActive ? AppColors.secondary : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(label, style: TextStyle(fontSize: 11, color: isActive ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildStudentSummary(List<Student> list) {
    final totalReq = list.fold(0.0, (s, e) => s + e.totalRequired);
    final totalPaid = list.fold(0.0, (s, e) => s + e.totalPaid);
    final totalRem = list.fold(0.0, (s, e) => s + e.remaining);
    return _summaryCard('عدد الطلاب', '${list.length}', 'المطلوب', money(totalReq), 'المدفوع', money(totalPaid), 'المتبقي', money(totalRem));
  }

  Widget _buildTreasurySummary(List<FinancialTransaction> list) {
    final deposits = list.where((tx) => tx.type == 'deposit').fold(0.0, (s, e) => s + e.amount);
    final withdraws = list.where((tx) => tx.type == 'withdraw').fold(0.0, (s, e) => s + e.amount);
    final transfers = list.where((tx) => tx.type == 'transfer').fold(0.0, (s, e) => s + e.amount);
    return _summaryCard('عدد العمليات', '${list.length}', 'إيداعات', money(deposits), 'سحوبات', money(withdraws), 'تحويلات', money(transfers));
  }

  Widget _summaryCard(String l1, String v1, String l2, String v2, String l3, String v3, String l4, String v4) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_sumItem(l1, v1, Colors.blueGrey), _sumItem(l2, v2, Colors.blueGrey)],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [_sumItem(l3, v3, AppColors.ok), _sumItem(l4, v4, AppColors.none)],
          ),
        ],
      ),
    );
  }

  Widget _sumItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _buildStudentTable(List<Student> list) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.primary(context).withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('الطالب')),
            DataColumn(label: Text('الفصل')),
            DataColumn(label: Text('القسم')),
            DataColumn(label: Text('المطلوب')),
            DataColumn(label: Text('المدفوع')),
            DataColumn(label: Text('المتبقي')),
            DataColumn(label: Text('الحالة')),
          ],
          rows: list.map((s) {
            final pct = s.paidPct;
            String status;
            Color statusColor;
            if (pct >= 1) { status = 'مكتمل'; statusColor = AppColors.ok; }
            else if (pct > 0) { status = 'جزئي'; statusColor = AppColors.partial; }
            else { status = 'لم يدفع'; statusColor = AppColors.none; }

            return DataRow(cells: [
              DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(classNames[s.cls - 1])),
              DataCell(Text(genderName(s.gender))),
              DataCell(Text(money(s.totalRequired))),
              DataCell(Text(money(s.totalPaid), style: const TextStyle(color: AppColors.ok))),
              DataCell(Text(money(s.remaining), style: const TextStyle(color: AppColors.none))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTreasuryTable(List<FinancialTransaction> list) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.primary(context).withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('النوع')),
            DataColumn(label: Text('الجهة')),
            DataColumn(label: Text('طريقة الدفع')),
            DataColumn(label: Text('المبلغ')),
          ],
          rows: list.map((tx) {
            final isDeposit = tx.type == 'deposit';
            final isWithdraw = tx.type == 'withdraw';
            final color = isDeposit ? AppColors.ok : isWithdraw ? AppColors.none : AppColors.secondary;
            final label = isDeposit ? 'إيداع' : isWithdraw ? 'سحب' : 'تحويل';

            return DataRow(cells: [
              DataCell(Text(dateStr(tx.date))),
              DataCell(Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
              DataCell(Text(tx.entityName)),
              DataCell(Text(tx.method == 'cash' ? 'كاش' : 'بنك')),
              DataCell(Text(money(tx.amount), style: TextStyle(color: color, fontWeight: FontWeight.bold))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}


  
