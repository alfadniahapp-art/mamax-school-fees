import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});
  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  Stage _selectedStage = Stage.primary;
  Gender _selectedGender = Gender.boys;
  int _selectedClass = 1;
  
  final _baseFeeCtrl = TextEditingController(text: '150000');
  final _regFeeCtrl = TextEditingController(text: '25000');
  final _examFeeCtrl = TextEditingController(text: '50000');
  final _inst1Ctrl = TextEditingController(text: '75000');
  final _inst2Ctrl = TextEditingController(text: '37500');
  final _inst3Ctrl = TextEditingController(text: '37500');
  final _studentsTextCtrl = TextEditingController();
  DateTime? _due2;
  DateTime? _due3;

  void _recalcInstallments() {
    final base = double.tryParse(_baseFeeCtrl.text) ?? 0;
    final app = context.read<AppProvider>();
    final a = (base * app.settings.pctA / 100).roundToDouble();
    final b = (base * app.settings.pctB / 100).roundToDouble();
    _inst1Ctrl.text = a.toStringAsFixed(0);
    _inst2Ctrl.text = b.toStringAsFixed(0);
    _inst3Ctrl.text = (base - a - b).toStringAsFixed(0);
  }

  Future<void> _pickDate(bool isDue2) async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (d != null) setState(() => isDue2 ? _due2 = d : _due3 = d);
  }

  void _saveClass() async {
    final names = _studentsTextCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل أسماء الطلاب أولاً'), backgroundColor: AppColors.none));
      return;
    }

    final app = context.read<AppProvider>();
    final newStudents = <Student>[];

    for (var name in names) {
      newStudents.add(Student(
        id: app.newId(),
        name: name,
        stage: _selectedStage,
        cls: _selectedClass,
        gender: _selectedGender,
        hasReg: isFirstClass(_selectedStage, _selectedClass),
        hasExam: isFinalClass(_selectedStage, _selectedClass),
        feeBase: double.tryParse(_baseFeeCtrl.text) ?? 0,
        feeReg: double.tryParse(_regFeeCtrl.text) ?? 0,
        feeExam: double.tryParse(_examFeeCtrl.text) ?? 0,
        inst1: double.tryParse(_inst1Ctrl.text) ?? 0,
        inst2: double.tryParse(_inst2Ctrl.text) ?? 0,
        inst3: double.tryParse(_inst3Ctrl.text) ?? 0,
        due2: _due2,
        due3: _due3,
      ));
    }

    await app.addMultipleStudents(newStudents);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ تم إضافة ${names.length} طالباً بنجاح'), backgroundColor: AppColors.ok));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('إدارة وتسجيل الفصول')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. تحديد الفصل
          _buildCard(
            title: '1. تحديد الفصل والنوع',
            icon: Icons.group,
            children: [
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<Stage>(
                    value: _selectedStage,
                    decoration: const InputDecoration(labelText: 'المرحلة', filled: true, fillColor: Colors.white),
                    items: stagesList.map((s) => DropdownMenuItem(value: s.stage, child: Text(s.name))).toList(),
                    onChanged: (v) => setState(() { _selectedStage = v!; if (_selectedClass > stageCount(v)) _selectedClass = 1; }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedClass,
                    decoration: const InputDecoration(labelText: 'الصف', filled: true, fillColor: Colors.white),
                    items: List.generate(stageCount(_selectedStage), (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))),
                    onChanged: (v) => setState(() => _selectedClass = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'النوع', filled: true, fillColor: Colors.white),
                items: const [DropdownMenuItem(value: Gender.boys, child: Text('بنين')), DropdownMenuItem(value: Gender.girls, child: Text('بنات'))],
                onChanged: (v) => setState(() => _selectedGender = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 2. الرسوم
          _buildCard(
            title: '2. رسوم الفصل وتوزيع الأقساط',
            icon: Icons.payments,
            children: [
              TextField(controller: _baseFeeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الرسوم الأساسية', filled: true, fillColor: Colors.white), onChanged: (_) => setState(_recalcInstallments)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _inst1Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قسط أول', filled: true, fillColor: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _inst2Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قسط ثاني', filled: true, fillColor: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _inst3Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قسط أخير', filled: true, fillColor: Colors.white))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: InkWell(onTap: () => _pickDate(true), child: InputDecorator(decoration: const InputDecoration(labelText: 'استحقاق القسط 2', filled: true, fillColor: Colors.white), child: Text(_due2 == null ? 'غير محدد' : dateStr(_due2), style: const TextStyle(fontSize: 13))))),
                const SizedBox(width: 8),
                Expanded(child: InkWell(onTap: () => _pickDate(false), child: InputDecorator(decoration: const InputDecoration(labelText: 'استحقاق القسط 3', filled: true, fillColor: Colors.white), child: Text(_due3 == null ? 'غير محدد' : dateStr(_due3), style: const TextStyle(fontSize: 13))))),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          
          // 3. الأسماء
          _buildCard(
            title: '3. أسماء الطلاب (اسم في كل سطر)',
            icon: Icons.list_alt,
            children: [
              TextField(
                controller: _studentsTextCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'محمد أحمد\nعلي خديوي\nعمر ياسر\n...',
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'أدخل اسم كل طالب في سطر منفصل',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // زر الحفظ
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _saveClass,
              icon: const Icon(Icons.group_add),
              label: const Text('إضافة الطلاب وتوزيع الأقساط آلياً', style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary(context), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 20, color: AppColors.primary(context)), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary(context)))]),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}
