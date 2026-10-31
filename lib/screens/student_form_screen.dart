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
      appBar: AppBar(title: Text(widget.student == null ? 'إضافة طالب' : 'تعديل طالب')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الطالب'), validator: (v) => v!.isEmpty ? 'مطلوب' : null),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Stage>(
                    value: _stage,
                    decoration: const InputDecoration(labelText: 'المرحلة'),
                    items: stagesList.map((s) => DropdownMenuItem(value: s.stage, child: Text(s.name))).toList(),
                    onChanged: (v) { if (v != null) setState(() { _stage = v; if (_cls > stageCount(v)) _cls = 1; _loadFees(); }); },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _cls,
                    decoration: const InputDecoration(labelText: 'الصف'),
                    items: List.generate(stageCount(_stage), (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))),
                    onChanged: (v) { if (v != null) setState(() { _cls = v; _loadFees(); }); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Gender>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'النوع'),
              items: const [
                DropdownMenuItem(value: Gender.boys, child: Text('بنين')),
                DropdownMenuItem(value: Gender.girls, child: Text('بنات')),
              ],
              onChanged: (v) { if (v != null) setState(() => _gender = v); },
            ),
            const SizedBox(height: 20),
            TextFormField(controller: _feeBase, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الرسوم الأساسية'), onChanged: (_) => setState(_recalcInstallments)),
            const SizedBox(height: 16),
            TextFormField(controller: _inst1, decoration: const InputDecoration(labelText: 'القسط الأول')),
            const SizedBox(height: 10),
            TextFormField(controller: _inst2, decoration: const InputDecoration(labelText: 'القسط الثاني')),
            const SizedBox(height: 10),
            TextFormField(controller: _inst3, decoration: const InputDecoration(labelText: 'القسط الثالث')),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('حفظ البيانات')),
          ],
        ),
      ),
    );
  }
}
