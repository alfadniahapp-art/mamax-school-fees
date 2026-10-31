import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // فلاتر النطاق
  String _scope = 'all'; // all, stage, gender, class
  Stage _selectedStage = Stage.primary;
  Gender _selectedGender = Gender.boys;
  int _selectedClass = 1;

  // فلتر حالة السداد
  String _paymentStatus = 'all'; // all, paid, partial, unpaid

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    
    // 1. الفلترة حسب النطاق (مرحلة، قسم، فصل)
    var list = app.students.where((s) {
      if (_scope == 'stage') return s.stage == _selectedStage;
      if (_scope == 'gender') return s.gender == _selectedGender;
      if (_scope == 'class') return s.stage == _selectedStage && s.cls == _selectedClass;
      return true;
    }).toList();

    // 2. الفلترة حسب حالة السداد (مكتمل، جزئي، لم يدفع)
    list = list.where((s) {
      if (_paymentStatus == 'paid') return s.paidPct >= 1.0;
      if (_paymentStatus == 'partial') return s.paidPct > 0 && s.paidPct < 1.0;
      if (_paymentStatus == 'unpaid') return s.paidPct == 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('لا توجد بيانات مطابقة', style: TextStyle(color: Colors.grey)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummary(list),
                      const SizedBox(height: 16),
                      _buildTable(list),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // فلاتر النطاق
          const Text('تصفية حسب النطاق:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('كل الطلاب', 'all'),
                const SizedBox(width: 8),
                _chip('مرحلة معينة', 'stage'),
                const SizedBox(width: 8),
                _chip('قسم (بنين/بنات)', 'gender'),
                const SizedBox(width: 8),
                _chip('فصل معين', 'class'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_scope == 'stage' || _scope == 'class')
            DropdownButtonFormField<Stage>(
              value: _selectedStage,
              decoration: const InputDecoration(labelText: 'اختر المرحلة', isDense: true),
              items: stagesList.map((s) => DropdownMenuItem(value: s.stage, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _selectedStage = v!),
            ),
          if (_scope == 'gender')
            DropdownButtonFormField<Gender>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'اختر القسم', isDense: true),
              items: const [
                DropdownMenuItem(value: Gender.boys, child: Text('بنين')),
                DropdownMenuItem(value: Gender.girls, child: Text('بنات')),
              ],
              onChanged: (v) => setState(() => _selectedGender = v!),
            ),
          if (_scope == 'class')
            DropdownButtonFormField<int>(
              value: _selectedClass,
              decoration: const InputDecoration(labelText: 'اختر الصف', isDense: true),
              items: List.generate(stageCount(_selectedStage), (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))).toList(),
              onChanged: (v) => setState(() => _selectedClass = v!),
            ),
            
          const Divider(height: 24),
          
          // فلتر حالة السداد
          const Text('تصفية حسب حالة السداد:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('الكل', 'all_status', isStatus: true),
                const SizedBox(width: 8),
                _chip('دفعوا كاملاً', 'paid', isStatus: true),
                const SizedBox(width: 8),
                _chip('سداد جزئي', 'partial', isStatus: true),
                const SizedBox(width: 8),
                _chip('لم يدفعوا', 'unpaid', isStatus: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, {bool isStatus = false}) {
    final isActive = isStatus ? _paymentStatus == value : _scope == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.black87)),
      selected: isActive,
      selectedColor: isStatus ? AppColors.secondary : AppColors.primary(context),
      onSelected: (_) {
        setState(() {
          if (isStatus) {
            _paymentStatus = value == 'all_status' ? 'all' : value;
          } else {
            _scope = value;
          }
        });
      },
    );
  }

  Widget _buildSummary(List<Student> list) {
    final totalReq = list.fold(0.0, (s, e) => s + e.totalRequired);
    final totalPaid = list.fold(0.0, (s, e) => s + e.totalPaid);
    final totalRem = list.fold(0.0, (s, e) => s + e.remaining);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumItem('عدد الطلاب', '${list.length}', Colors.blueGrey),
              _sumItem('إجمالي المطلوب', money(totalReq), Colors.blueGrey),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumItem('إجمالي المدفوع', money(totalPaid), AppColors.ok),
              _sumItem('إجمالي المتبقي', money(totalRem), AppColors.none),
            ],
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

  Widget _buildTable(List<Student> list) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
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
            if (pct >= 1) {
              status = 'مكتمل';
              statusColor = AppColors.ok;
            } else if (pct > 0) {
              status = 'جزئي';
              statusColor = AppColors.partial;
            } else {
              status = 'لم يدفع';
              statusColor = AppColors.none;
            }

            return DataRow(cells: [
              DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(classNames[s.cls - 1])),
              DataCell(Text(genderName(s.gender))),
              DataCell(Text(money(s.totalRequired))),
              DataCell(Text(money(s.totalPaid), style: const TextStyle(color: AppColors.ok))),
              DataCell(Text(money(s.remaining), style: const TextStyle(color: AppColors.none))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
