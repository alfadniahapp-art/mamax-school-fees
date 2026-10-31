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
  String _scope = 'all'; // all, stage, gender, class
  Stage _selectedStage = Stage.primary;
  Gender _selectedGender = Gender.boys;
  int _selectedClass = 1;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    
    var list = app.students.where((s) {
      if (_scope == 'stage') return s.stage == _selectedStage;
      if (_scope == 'gender') return s.gender == _selectedGender;
      if (_scope == 'class') return s.stage == _selectedStage && s.cls == _selectedClass;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('التقارير')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('لا توجد بيانات', style: TextStyle(color: Colors.grey)))
                : ListView(
                    padding: const EdgeInsets.all(12),
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
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('الكل', 'all'),
                const SizedBox(width: 8),
                _chip('المرحلة', 'stage'),
                const SizedBox(width: 8),
                _chip('بنين/بنات', 'gender'),
                const SizedBox(width: 8),
                _chip('الفصل', 'class'),
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
              decoration: const InputDecoration(labelText: 'اختر النوع', isDense: true),
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
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final isActive = _scope == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => setState(() => _scope = value),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumItem('عدد الطلاب', '${list.length}', Colors.blueGrey),
              _sumItem('المطلوب', money(totalReq), Colors.blueGrey),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumItem('المدفوع', money(totalPaid), AppColors.ok),
              _sumItem('المتبقي', money(totalRem), AppColors.none),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppColors.primary(context).withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('الطالب')),
            DataColumn(label: Text('الصف')),
            DataColumn(label: Text('النوع')),
            DataColumn(label: Text('المطلوب')),
            DataColumn(label: Text('المدفوع')),
            DataColumn(label: Text('المتبقي')),
          ],
          rows: list.map((s) {
            return DataRow(cells: [
              DataCell(Text(s.name)),
              DataCell(Text(classNames[s.cls - 1])),
              DataCell(Text(genderName(s.gender))),
              DataCell(Text(money(s.totalRequired))),
              DataCell(Text(money(s.totalPaid), style: const TextStyle(color: AppColors.ok))),
              DataCell(Text(money(s.remaining), style: const TextStyle(color: AppColors.none))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
