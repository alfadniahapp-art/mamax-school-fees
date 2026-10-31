import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;
  const StudentFormScreen({super.key, this.student});
  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _feeBase, _feeReg, _feeExam, _inst1, _inst2, _inst3;
  late Stage _stage;
  late Gender _gender;
  late int _cls;
  bool _hasReg = false, _hasExam = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _name = TextEditingController(text: s?.name ?? '');
    _stage = s?.stage ?? Stage.primary;
    _gender = s?.gender ?? Gender.boys;
    _cls = s?.cls ?? 1;
    _hasReg = s?.hasReg ?? false;
    _hasExam = s?.hasExam ?? false;
    _feeBase = TextEditingController();
    _feeReg = TextEditingController();
    _feeExam = TextEditingController();
    _inst1 = TextEditingController();
    _inst2 = TextEditingController();
    _inst3 = TextEditingController();

    if (s != null) {
      _feeBase.text = s.feeBase.toStringAsFixed(0);
      _feeReg.text = s.feeReg.toStringAsFixed(0);
      _feeExam.text = s.feeExam.toStringAsFixed(0);
      _inst1.text = s.inst1.toStringAsFixed(0);
      _inst2.text = s.inst2.toStringAsFixed(0);
      _inst3.text = s.inst3.toStringAsFixed(0);
    } else {
      _loadFees();
    }
  }

  void _loadFees() {
    final app = context.read<AppProvider>();
    final key = '${_stage.name}-$_cls';
    final fees = app.getFeesForKey(key);
    _feeBase.text = fees['base']?.toStringAsFixed(0) ?? '0';
    _feeReg.text = fees['reg']?.toStringAsFixed(0) ?? '0';
    _feeExam.text = fees['exam']?.toStringAsFixed(0) ?? '0';
    _hasReg = isFirstClass(_stage, _cls) && (double.tryParse(_feeReg.text) ?? 0) > 0;
    _hasExam = isFinalClass(_stage, _cls) && (double.tryParse(_feeExam.text) ?? 0) > 0;
    _recalcInstallments();
  }

  void _recalcInstallments() {
    final base = double.tryParse(_feeBase.text) ?? 0;
    final app = context.read<AppProvider>();
    final a = (base * app.settings.pctA / 100).roundToDouble();
    final b = (base * app.settings.pctB / 100).roundToDouble();
    _inst1.text = a.toStringAsFixed(0);
    _inst2.text = b.toStringAsFixed(0);
    _inst3.text = (base - a - b).toStringAsFixed(0);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppProvider>();
    final data = Student(
      id: widget.student?.id ?? app.newId(),
      name: _name.text.trim(), stage: _stage, cls: _cls, gender: _gender,
      hasReg: _hasReg, hasExam: _hasExam,
      feeBase: double.tryParse(_feeBase.text) ?? 0,
      feeReg: _hasReg ? (double.tryParse(_feeReg.text) ?? 0) : 0,
      feeExam: _hasExam ? (double.tryParse(_feeExam.text) ?? 0) : 0,
      inst1: double.tryParse(_inst1.text) ?? 0,
      inst2: double.tryParse(_inst2.text) ?? 0,
      inst3: double.tryParse(_inst3.text) ?? 0,
      payments: widget.student?.payments ?? [],
    );
    if (widget.student == null) await app.addStudent(data);
    else await app.updateStudent(data);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context), // خلفية الثيم الملكية
      appBar: AppBar(
        title: Text(widget.student == null ? 'إضافة طالب جديد' : 'تعديل بيانات الطالب', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              title: 'بيانات الطالب',
              icon: Icons.person,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: _inputDecoration('اسم الطالب بالكامل', prefixIcon: const Icon(Icons.badge)),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Stage>(
                        value: _stage,
                        decoration: _inputDecoration('المرحلة'),
                        items: stagesList.map((s) => DropdownMenuItem(value: s.stage, child: Text(s.name))).toList(),
                        onChanged: (v) { if (v != null) setState(() { _stage = v; if (_cls > stageCount(v)) _cls = 1; _loadFees(); }); },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _cls,
                        decoration: _inputDecoration('الصف'),
                        items: List.generate(stageCount(_stage), (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))),
                        onChanged: (v) { if (v != null) setState(() { _cls = v; _loadFees(); }); },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Gender>(
                  value: _gender,
                  decoration: _inputDecoration('النوع'),
                  items: const [
                    DropdownMenuItem(value: Gender.boys, child: Text('بنين')),
                    DropdownMenuItem(value: Gender.girls, child: Text('بنات')),
                  ],
                  onChanged: (v) { if (v != null) setState(() => _gender = v); },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildCard(
              title: 'الرسوم والأقساط',
              icon: Icons.payments,
              children: [
                TextFormField(
                  controller: _feeBase,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('الرسوم الأساسية'),
                  onChanged: (_) => setState(_recalcInstallments),
                ),
                const SizedBox(height: 16),
                const Text('توزيع الأقساط (قابل للتعديل)', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _inst1, keyboardType: TextInputType.number, decoration: _inputDecoration('القسط 1'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _inst2, keyboardType: TextInputType.number, decoration: _inputDecoration('القسط 2'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(controller: _inst3, keyboardType: TextInputType.number, decoration: _inputDecoration('القسط 3'))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('حفظ البيانات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: AppColors.primary(context).withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.surface(context), // حقل يأخذ لون البطاقة
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder(context), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 24, color: AppColors.primary(context)),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary(context))),
          ]),
          const Divider(height: 30),
          ...children,
        ],
      ),
    );
  }
}
