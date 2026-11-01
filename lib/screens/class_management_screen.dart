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
  
  bool _includeReg = false;
  bool _includeExam = false;

  @override
  void initState() {
    super.initState();
    _loadClassFee();
  }

  void _loadClassFee() {
    final app = context.read<AppProvider>();
    final key = '${_selectedStage.name}-$_selectedClass';
    final fee = app.getClassFee(key);
    _baseFeeCtrl.text = fee.toStringAsFixed(0);
    _recalcInstallments();
  }

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
        hasReg: _includeReg,
        hasExam: _includeExam,
        feeBase: double.tryParse(_baseFeeCtrl.text) ?? 0,
        feeReg: _includeReg ? (double.tryParse(_regFeeCtrl.text) ?? 0) : 0,
        feeExam: _includeExam ? (double.tryParse(_examFeeCtrl.text) ?? 0) : 0,
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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('إدارة وتسجيل الفصول', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeesTable(context),
          const SizedBox(height: 20),
          
          _buildCard(
            title: '1. تحديد الفصل والنوع',
            icon: Icons.group,
            children: [
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<Stage>(
                    value: _selectedStage,
                    decoration: _inputDecoration(context, 'المرحلة'),
                    items: stagesList.map((s) => DropdownMenuItem(value: s.stage, child: Text(s.name))).toList(),
                    onChanged: (v) => setState(() { _selectedStage = v!; if (_selectedClass > stageCount(v)) _selectedClass = 1; _loadClassFee(); }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedClass,
                    decoration: _inputDecoration(context, 'الصف'),
                    items: List.generate(stageCount(_selectedStage), (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))),
                    onChanged: (v) => setState(() => _selectedClass = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                decoration: _inputDecoration(context, 'النوع'),
                items: const [DropdownMenuItem(value: Gender.boys, child: Text('بنين')), DropdownMenuItem(value: Gender.girls, child: Text('بنات'))],
                onChanged: (v) => setState(() => _selectedGender = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildCard(
            title: '2. رسوم الفصل وتوزيع الأقساط',
            icon: Icons.payments,
            children: [
              TextField(controller: _baseFeeCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'الرسوم الأساسية'), onChanged: (_) => setState(_recalcInstallments)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: _inst1Ctrl, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'قسط أول'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _inst2Ctrl, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'قسط ثاني'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _inst3Ctrl, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'قسط أخير'))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: InkWell(onTap: () => _pickDate(true), child: InputDecorator(decoration: _inputDecoration(context, 'استحقاق القسط 2', suffixIcon: const Icon(Icons.calendar_today, size: 20)), child: Text(_due2 == null ? 'غير محدد' : dateStr(_due2), style: const TextStyle(fontSize: 13))))),
                const SizedBox(width: 10),
                Expanded(child: InkWell(onTap: () => _pickDate(false), child: InputDecorator(decoration: _inputDecoration(context, 'استحقاق القسط 3', suffixIcon: const Icon(Icons.calendar_today, size: 20)), child: Text(_due3 == null ? 'غير محدد' : dateStr(_due3), style: const TextStyle(fontSize: 13))))),
              ]),
              const SizedBox(height: 16),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('شامل رسوم التسجيل', style: TextStyle(fontSize: 14)),
                value: _includeReg,
                onChanged: (v) => setState(() => _includeReg = v),
              ),
              if (_includeReg) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(controller: _regFeeCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'قيمة رسوم التسجيل')),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('شامل رسوم الامتحانات', style: TextStyle(fontSize: 14)),
                value: _includeExam,
                onChanged: (v) => setState(() => _includeExam = v),
              ),
              if (_includeExam) 
                TextField(controller: _examFeeCtrl, keyboardType: TextInputType.number, decoration: _inputDecoration(context, 'قيمة رسوم الامتحانات')),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildCard(
            title: '3. أسماء الطلاب (اسم في كل سطر)',
            icon: Icons.list_alt,
            children: [
              TextField(
                controller: _studentsTextCtrl,
                maxLines: 6,
                decoration: _inputDecoration(context, 'محمد أحمد\nعلي خديوي\nعمر ياسر\n...', helperText: 'أدخل اسم كل طالب في سطر منفصل'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _saveClass,
              icon: const Icon(Icons.group_add),
              label: const Text('إضافة الطلاب وتوزيع الأقساط آلياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context), 
                foregroundColor: Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: AppColors.primary(context).withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // دالة موحدة لتزيين الحقول (مع الحدود الملونة)
  InputDecoration _inputDecoration(BuildContext context, String label, {String? helperText, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.inputBorder(context), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary(context), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildFeesTable(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppColors.cardBorder(context), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.table_chart, size: 24, color: AppColors.primary(context)), 
            const SizedBox(width: 10), 
            Text('تحديد رسوم كل الفصول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary(context)))
          ]),
          const Divider(height: 30),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('الفصل', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('الرسوم (قابلة للتعديل)', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: stagesList.expand((st) {
                return List.generate(stageCount(st.stage), (i) {
                  final key = '${st.stage.name}-${i + 1}';
                  final fee = context.read<AppProvider>().getClassFee(key);
                  return DataRow(cells: [
                    DataCell(Text('${st.name} - ${classNames[i]}')),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          initialValue: fee.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          // تم تطبيق الحدود الملونة هنا
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surface(context),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.inputBorder(context), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primary(context), width: 2),
                            ),
                          ),
                          onChanged: (v) {
                            final newFee = double.tryParse(v) ?? 0;
                            context.read<AppProvider>().setClassFee(key, newFee);
                          },
                        ),
                      ),
                    ),
                  ]);
                });
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppColors.cardBorder(context), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 24, color: AppColors.primary(context)), 
            const SizedBox(width: 10), 
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary(context)))
          ]),
          const Divider(height: 30),
          ...children,
        ],
      ),
    );
  }
}
