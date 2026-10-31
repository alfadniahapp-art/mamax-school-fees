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
    _feeBase = TextEditingController(
        text: s != null ? s.feeBase.toStringAsFixed(0) : '150000');
    _feeReg = TextEditingController(
        text: s != null ? s.feeReg.toStringAsFixed(0) : '0');
    _feeExam = TextEditingController(
        text: s != null ? s.feeExam.toStringAsFixed(0) : '0');
    _inst1 = TextEditingController(
        text: s != null ? s.inst1.toStringAsFixed(0) : '75000');
    _inst2 = TextEditingController(
        text: s != null ? s.inst2.toStringAsFixed(0) : '37500');
    _inst3 = TextEditingController(
        text: s != null ? s.inst3.toStringAsFixed(0) : '37500');
    _due2 = s?.due2;
    _due3 = s?.due3;

    if (s == null) {
      _autoFlags();
      _recalcInstallments();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _feeBase.dispose();
    _feeReg.dispose();
    _feeExam.dispose();
    _inst1.dispose();
    _inst2.dispose();
    _inst3.dispose();
    super.dispose();
  }

  void _autoFlags() {
    _hasReg = isFirstClass(_stage, _cls);
    _hasExam = isFinalClass(_stage, _cls);
    if (_hasReg && (double.tryParse(_feeReg.text) ?? 0) == 0) {
      _feeReg.text = '25000';
    }
    if (_hasExam && (double.tryParse(_feeExam.text) ?? 0) == 0) {
      _feeExam.text = '50000';
    }
    if (!_hasReg) _feeReg.text = '0';
    if (!_hasExam) _feeExam.text = '0';
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

  Future<void> _pickDate(bool isDue2) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (isDue2 ? _due2 : _due3) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => isDue2 ? _due2 = d : _due3 = d);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final app = context.read<AppProvider>();
    final inst1 = double.tryParse(_inst1.text) ?? 0;
    final inst2 = double.tryParse(_inst2.text) ?? 0;
    final inst3 = double.tryParse(_inst3.text) ?? 0;
    final base = double.tryParse(_feeBase.text) ?? 0;

    if ((inst1 + inst2 + inst3 - base).abs() > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'مجموع الأقساط (${money(inst1 + inst2 + inst3)}) يجب أن يساوي الرسوم الأساسية (${money(base)})'),
          backgroundColor: kNoneColor,
        ),
      );
      return;
    }

    final data = Student(
      id: widget.student?.id ?? app.newId(),
      name: _name.text.trim(),
      stage: _stage,
      cls: _cls,
      hasReg: _hasReg,
      hasExam: _hasExam,
      feeBase: base,
      feeReg: double.tryParse(_feeReg.text) ?? 0,
      feeExam: double.tryParse(_feeExam.text) ?? 0,
      inst1: inst1,
      inst2: inst2,
      inst3: inst3,
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
          content: Text(widget.student == null
              ? '✓ تمت إضافة الطالب'
              : '✓ تم تحديث بيانات الطالب'),
          backgroundColor: kOkColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxCls = stageCount(_stage);
    final app = context.read<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null
            ? 'إضافة طالب جديد'
            : 'تعديل بيانات الطالب'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بيانات الطالب
            _sectionTitle('بيانات الطالب'),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'اسم الطالب الثلاثي',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Stage>(
                    value: _stage,
                    decoration: const InputDecoration(
                      labelText: 'المرحلة',
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: stagesList
                        .map((s) => DropdownMenuItem(
                            value: s.stage, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _stage = v;
                        if (_cls > stageCount(v)) _cls = 1;
                        _autoFlags();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _cls,
                    decoration: const InputDecoration(
                      labelText: 'الصف',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: List.generate(
                      maxCls,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text(classNames[i])),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _cls = v;
                        _autoFlags();
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _sectionTitle('أنواع الرسوم المشمولة'),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _hasReg,
                    title: const Text('رسوم التسجيل'),
                    subtitle: Text(
                      isFirstClass(_stage, _cls)
                          ? 'الافتراضي: مفعّلة لهذا الصف'
                          : 'الافتراضي: غير مطلوبة',
                      style: const TextStyle(fontSize: 11),
                    ),
                    activeColor: kPrimaryColor,
                    onChanged: (v) => setState(() {
                      _hasReg = v;
                      if (_hasReg &&
                          (double.tryParse(_feeReg.text) ?? 0) == 0) {
                        _feeReg.text = '25000';
                      }
                      if (!_hasReg) _feeReg.text = '0';
                    }),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _hasExam,
                    title: const Text('رسوم الامتحانات النهائية'),
                    subtitle: Text(
                      isFinalClass(_stage, _cls)
                          ? 'الافتراضي: مفعّلة لهذا الصف'
                          : 'الافتراضي: غير مطلوبة',
                      style: const TextStyle(fontSize: 11),
                    ),
                    activeColor: kPrimaryColor,
                    onChanged: (v) => setState(() {
                      _hasExam = v;
                      if (_hasExam &&
                          (double.tryParse(_feeExam.text) ?? 0) == 0) {
                        _feeExam.text = '50000';
                      }
                      if (!_hasExam) _feeExam.text = '0';
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('قيمة الرسوم'),
            _numField('الرسوم الأساسية', _feeBase,
                onChanged: (_) => setState(_recalcInstallments)),
            if (_hasReg) ...[
              const SizedBox(height: 10),
              _numField('رسوم التسجيل', _feeReg),
            ],
            if (_hasExam) ...[
              const SizedBox(height: 10),
              _numField('رسوم الامتحانات', _feeExam),
            ],

            const SizedBox(height: 20),
            _sectionTitle('توزيع الأقساط'),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.teal.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'النسب الحالية: ${app.settings.pctA.toStringAsFixed(0)}% / ${app.settings.pctB.toStringAsFixed(0)}% / ${app.settings.pctC.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.teal.shade800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(_recalcInstallments),
                    child: const Text('تحديث تلقائي',
                        style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _numField('قيمة القسط الأول', _inst1),
            const SizedBox(height: 10),
            _numField('قيمة القسط الثاني', _inst2),
            const SizedBox(height: 10),
            _numField('قيمة القسط الثالث', _inst3),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade100, Colors.teal.shade50],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المجموع الإجمالي',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    money(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionTitle('مواعيد استحقاق الأقساط'),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today,
                        color: kPrimaryColor),
                    title: const Text('استحقاق القسط الثاني'),
                    subtitle: Text(_due2 == null
                        ? 'غير محدد'
                        : dateStr(_due2)),
                    trailing: _due2 != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _due2 = null))
                        : const Icon(Icons.edit, size: 16),
                    onTap: () => _pickDate(true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.calendar_today,
                        color: kPrimaryColor),
                    title: const Text('استحقاق القسط الثالث'),
                    subtitle: Text(_due3 == null
                        ? 'غير محدد'
                        : dateStr(_due3)),
                    trailing: _due3 != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _due3 = null))
                        : const Icon(Icons.edit, size: 16),
                    onTap: () => _pickDate(false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.save),
              label: Text(
                widget.student == null
                    ? 'حفظ الطالب'
                    : 'تحديث البيانات',
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController c,
      {Function(String)? onChanged}) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'ج.س',
      ),
      onChanged: (v) {
        if (onChanged != null) onChanged(v);
        setState(() {});
      },
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n < 0) return 'أدخل رقماً صحيحاً';
        return null;
      },
    );
  }
}
