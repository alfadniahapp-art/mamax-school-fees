class AppSettings {
  double pctA; // نسبة القسط الأول (افتراضي 50%)
  double pctB; // نسبة القسط الثاني (افتراضي 25%)
  double pctC; // نسبة القسط الأخير (افتراضي 25%)
  
  int warnDays;         // التنبيه قبل الاستحقاق بـ (أيام)
  int alertRepeatCount; // عدد تكرار التنبيه
  
  // بيانات الحساب البنكي
  String bankAccountName;
  String bankAccountNumber;
  String bankPhone;

  AppSettings({
    this.pctA = 50,
    this.pctB = 25,
    this.pctC = 25,
    this.warnDays = 14,
    this.alertRepeatCount = 1,
    this.bankAccountName = '',
    this.bankAccountNumber = '',
    this.bankPhone = '',
  });

  Map<String, dynamic> toJson() => {
        'pctA': pctA,
        'pctB': pctB,
        'pctC': pctC,
        'warnDays': warnDays,
        'alertRepeatCount': alertRepeatCount,
        'bankAccountName': bankAccountName,
        'bankAccountNumber': bankAccountNumber,
        'bankPhone': bankPhone,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        pctA: (j['pctA'] ?? 50).toDouble(),
        pctB: (j['pctB'] ?? 25).toDouble(),
        pctC: (j['pctC'] ?? 25).toDouble(),
        warnDays: j['warnDays'] ?? 14,
        alertRepeatCount: j['alertRepeatCount'] ?? 1,
        bankAccountName: j['bankAccountName'] ?? '',
        bankAccountNumber: j['bankAccountNumber'] ?? '',
        bankPhone: j['bankPhone'] ?? '',
      );

  AppSettings copyWith({
    double? pctA,
    double? pctB,
    double? pctC,
    int? warnDays,
    int? alertRepeatCount,
    String? bankAccountName,
    String? bankAccountNumber,
    String? bankPhone,
  }) {
    return AppSettings(
      pctA: pctA ?? this.pctA,
      pctB: pctB ?? this.pctB,
      pctC: pctC ?? this.pctC,
      warnDays: warnDays ?? this.warnDays,
      alertRepeatCount: alertRepeatCount ?? this.alertRepeatCount,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankPhone: bankPhone ?? this.bankPhone,
    );
  }
}
