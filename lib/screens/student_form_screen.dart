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
    _feeBase = TextEditingController(text: s != null ? s.feeBase.toStringAsFixed(0) : '');
    _feeReg = TextEditingController(text: s != null ? s.feeReg.toStringAsFixed(0) : '');
    _feeExam = TextEditingController(text: s != null ? s.feeExam.toStringAsFixed(0) : '');
    _inst1 = TextEditingController(text: s != null ? s.inst1.toStringAsFixed(0) : '');
    _inst2 = TextEditingController(text: s != null ? s.inst2.toStringAsFixed(0) : '');
    _inst3 = TextEditingController(text: s != null ? s.inst3.toStringAsFixed(0) : '');

    if (s == null) {
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: Text(widget.student == null ? 'إضافة طالب' : 'تعديل طالب')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              title: 'بيانات الطالب',
              icon: Icons.person,
              children: [
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الطالب', filled: true, fillColor: Colors.white), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<Stage>(value: _stage, decoration: const InputDecoration(labelText: 'المرحلة', filled: true, fillColor: Colors.white), items: stagesList.map((s) => DropdownMenuItem(value: s.stage, child: Text(s.name))).toList(), onChanged: (v) { if (v != null) setState(() { _stage = v; if (_cls > stageCount(v)) _cls = 1; _loadFees(); }); })),
                    const SizedBox(width: 10),
                    Expanded(child: DropdownButtonFormField<int>(value: _cls, decoration: const InputDecoration(labelText: 'الصف', filled: true, fillColor: Colors.white), items: List.generate(stageCount(_stage), (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))), onChanged: (v) { if (v != null) setState(() { _cls = v; _loadFees(); }); })),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Gender>(value: _gender, decoration: const InputDecoration(labelText: 'النوع', filled: true, fillColor: Colors.white), items: const [DropdownMenuItem(value: Gender.boys, child: Text('بنين')), DropdownMenuItem(value: Gender.girls, child: Text('بنات'))], onChanged: (v) { if (v != null) setState(() => _gender = v); }),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'الرسوم والأقساط',
              icon: Icons.payments,
              children: [
                TextFormField(controller: _feeBase, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الرسوم الأساسية', filled: true, fillColor: Colors.white), onChanged: (_) => setState(_recalcInstallments)),
                if (_hasReg) ...[
                  const SizedBox(height: 10),
                  TextFormField(controller: _feeReg, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رسوم التسجيل', filled: true, fillColor: Colors.white), onChanged: (_) => setState(() {})),
                ],
                if (_hasExam) ...[
                  const SizedBox(height: 10),
                  TextFormField(controller: _feeExam, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رسوم الامتحانات', filled: true, fillColor: Colors.white), onChanged: (_) => setState(() {})),
                ],
                const SizedBox(height: 16),
                const Text('توزيع الأقساط', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _inst1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القسط 1', filled: true, fillColor: Colors.white))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: _inst2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القسط 2', filled: true, fillColor: Colors.white))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: _inst3, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'القسط 3', filled: true, fillColor: Colors.white))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('حفظ البيانات', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary(context), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
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
