import 'payment.dart';

/// المراحل الدراسية
enum Stage { primary, middle, high }

class StageInfo {
  final Stage stage;
  final String name;
  final int classCount;
  const StageInfo(this.stage, this.name, this.classCount);
}

const stagesList = [
  StageInfo(Stage.primary, 'الابتدائي', 6),
  StageInfo(Stage.middle, 'المتوسط', 3),
  StageInfo(Stage.high, 'الثانوي', 3),
];

const classNames = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس'];

String stageName(Stage s) =>
    stagesList.firstWhere((e) => e.stage == s).name;

int stageCount(Stage s) =>
    stagesList.firstWhere((e) => e.stage == s).classCount;

bool isFirstClass(Stage s, int cls) => cls == 1;

bool isFinalClass(Stage s, int cls) {
  if (s == Stage.primary) return cls == 6;
  return cls == 3;
}

/// أنواع الرسوم
enum FeeType { base, reg, exam, inst1, inst2, inst3 }

String feeTypeLabel(FeeType t) {
  switch (t) {
    case FeeType.base:
      return 'رسوم أساسية';
    case FeeType.reg:
      return 'رسوم تسجيل';
    case FeeType.exam:
      return 'رسوم امتحانات';
    case FeeType.inst1:
      return 'القسط الأول';
    case FeeType.inst2:
      return 'القسط الثاني';
    case FeeType.inst3:
      return 'القسط الثالث';
  }
}

class Student {
  String id;
  String name;
  Stage stage;
  int cls;
  bool hasReg;
  bool hasExam;
  double feeBase;
  double feeReg;
  double feeExam;
  double inst1;
  double inst2;
  double inst3;
  List<Payment> payments;
  DateTime? due2;
  DateTime? due3;

  Student({
    required this.id,
    required this.name,
    required this.stage,
    required this.cls,
    this.hasReg = false,
    this.hasExam = false,
    this.feeBase = 0,
    this.feeReg = 0,
    this.feeExam = 0,
    this.inst1 = 0,
    this.inst2 = 0,
    this.inst3 = 0,
    List<Payment>? payments,
    this.due2,
    this.due3,
  }) : payments = payments ?? [];

  /// إجمالي الرسوم المطلوبة (الأساسية + التسجيل + الامتحانات)
  double get totalRequired => feeBase + feeReg + feeExam;

  /// إجمالي المدفوع
  double get totalPaid => payments.fold(0, (s, p) => s + p.amount);

  /// المتبقي
  double get remaining => totalRequired - totalPaid;

  /// نسبة السداد
  double get paidPct =>
      totalRequired > 0 ? (totalPaid / totalRequired).clamp(0.0, 1.0) : 0.0;

  /// المدفوع لبند معين
  double paidFor(FeeType t) =>
      payments.where((p) => p.type == t).fold(0.0, (s, p) => s + p.amount);

  /// المتبقي لبند معين
  double remainingFor(FeeType t) {
    switch (t) {
      case FeeType.inst1:
        return (inst1 - paidFor(FeeType.inst1)).clamp(0, double.infinity);
      case FeeType.inst2:
        return (inst2 - paidFor(FeeType.inst2)).clamp(0, double.infinity);
      case FeeType.inst3:
        return (inst3 - paidFor(FeeType.inst3)).clamp(0, double.infinity);
      case FeeType.reg:
        return (feeReg - paidFor(FeeType.reg)).clamp(0, double.infinity);
      case FeeType.exam:
        return (feeExam - paidFor(FeeType.exam)).clamp(0, double.infinity);
      case FeeType.base:
        return 0;
    }
  }

  /// المطلوب لبند معين
  double amountFor(FeeType t) {
    switch (t) {
      case FeeType.inst1:
        return inst1;
      case FeeType.inst2:
        return inst2;
      case FeeType.inst3:
        return inst3;
      case FeeType.reg:
        return feeReg;
      case FeeType.exam:
        return feeExam;
      case FeeType.base:
        return feeBase;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stage': stage.index,
        'cls': cls,
        'hasReg': hasReg,
        'hasExam': hasExam,
        'feeBase': feeBase,
        'feeReg': feeReg,
        'feeExam': feeExam,
        'inst1': inst1,
        'inst2': inst2,
        'inst3': inst3,
        'due2': due2?.toIso8601String(),
        'due3': due3?.toIso8601String(),
        'payments': payments.map((p) => p.toJson()).toList(),
      };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        name: j['name'],
        stage: Stage.values[j['stage']],
        cls: j['cls'],
        hasReg: j['hasReg'] ?? false,
        hasExam: j['hasExam'] ?? false,
        feeBase: (j['feeBase'] ?? 0).toDouble(),
        feeReg: (j['feeReg'] ?? 0).toDouble(),
        feeExam: (j['feeExam'] ?? 0).toDouble(),
        inst1: (j['inst1'] ?? 0).toDouble(),
        inst2: (j['inst2'] ?? 0).toDouble(),
        inst3: (j['inst3'] ?? 0).toDouble(),
        due2: j['due2'] != null ? DateTime.parse(j['due2']) : null,
        due3: j['due3'] != null ? DateTime.parse(j['due3']) : null,
        payments: (j['payments'] as List? ?? [])
            .map((e) => Payment.fromJson(e))
            .toList(),
      );
}
