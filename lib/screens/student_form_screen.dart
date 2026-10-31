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
  late TextEditingController _name;
  late Stage _stage;
  late int _cls;
  bool _hasReg = false, _hasExam = false;
  late TextEditingController _feeBase, _feeReg, _feeExam;
  late TextEditingController _inst1, _inst2, _inst3;
  DateTime? _due2, _due3;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _name = TextEditingController(text: s?.name ?? '');
    _stage = s?.stage ?? Stage.primary;
    _cls = s?.cls ?? 1;
    _hasReg = s?.hasReg ?? false;
    _hasExam = s?.hasExam ?? false;
    _feeBase = TextEditingController();
    _feeReg = TextEditingController();
    _feeExam = TextEditingController();
    _inst1 = TextEditingController();
    _inst2 = TextEditingController();
    _inst3 = TextEditingController();
    _due2 = s?.due2;
    _due3 = s?.due3;

    if (s != null) {
      _feeBase.text = s.feeBase.toStringAsFixed(0);
      _feeReg.text = s.feeReg.toStringAsFixed(0);
      _feeExam.text = s.feeExam.toStringAsFixed(0);
      _inst1.text = s.inst1.toStringAsFixed(0);
      _inst2.text = s.inst2.toStringAsFixed(0);
      _inst3.text = s.inst3.toStringAsFixed(0);
    } else {
      _loadFeesFromSettings();
    }
  }

  void _loadFeesFromSettings() {
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
    final c = base - a - b;
    _inst1.text = a.toStringAsFixed(0);
    _inst2.text = b.toStringAsFixed(0);
    _inst3.text = c.toStringAsFixed(0);
  }

  double get _total =>
      (double.tryParse(_feeBase.text) ?? 0) +
      (double.tryParse(_feeReg.text) ?? 0) +
      (double.tryParse(_feeExam.text) ?? 0);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppProvider>();
    
    final data = Student(
      id: widget.student?.id ?? app.newId(),
      name: _name.text.trim(),
      stage: _stage,
      cls: _cls,
      hasReg: _hasReg,
      hasExam: _hasExam,
      feeBase: double.tryParse(_feeBase.text) ?? 0,
      feeReg: _hasReg ? (double.tryParse(_feeReg.text) ?? 0) : 0,
      feeExam: _hasExam ? (double.tryParse(_feeExam.text) ?? 0) : 0,
      inst1: double.tryParse(_inst1.text) ?? 0,
      inst2: double.tryParse(_inst2.text) ?? 0,
      inst3: double.tryParse(_inst3.text) ?? 0,
      payments: widget.student?.payments ?? [],
      due2: _due2,
      due3: _due3,
    );

    if (widget.student == null) {
      await app.addStudent(data);
    } else {
      await app.updateStudent(data);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.student == null ? '✓ تمت إضافة الطالب' : '✓ تم التحديث'),
          backgroundColor: AppColors.ok,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'إضافة طالب جديد' : 'تعديل بيانات الطالب'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'اسم الطالب الثلاثي',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Stage>(
                    value: _stage,
                    decoration: const InputDecoration(labelText: 'المرحلة'),
                    items: stagesList.map((s) => DropdownMenuItem(value: s.stage, child: Text(s.name))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _stage = v;
                        if (_cls > stageCount(v)) _cls = 1;
                        _loadFeesFromSettings();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _cls,
                    decoration: const InputDecoration(labelText: 'الصف'),
                    items: List.generate(
                      stageCount(_stage),
                      (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i])),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _cls = v;
                        _loadFeesFromSettings();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('الرسوم الأساسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const Divider(),
            const SizedBox(height: 10),
            TextFormField(
              controller: _feeBase,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الرسوم الدراسية الأساسية', suffixText: 'ج.س'),
              onChanged: (_) => setState(_recalcInstallments),
            ),
            const SizedBox(height: 16),
            if (_hasReg) ...[
              TextFormField(
                controller: _feeReg,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رسوم التسجيل', suffixText: 'ج.س'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],
            if (_hasExam) ...[
              TextFormField(
                controller: _feeExam,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رسوم الامتحانات', suffixText: 'ج.س'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 10),
            const Text('توزيع الأقساط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _numField('القسط الأول', _inst1)),
                const SizedBox(width: 10),
                Expanded(child: _numField('القسط الثاني', _inst2)),
                const SizedBox(width: 10),
                Expanded(child: _numField('القسط الثالث', _inst3)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(money(_total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _save, child: const Text('حفظ البيانات')),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
