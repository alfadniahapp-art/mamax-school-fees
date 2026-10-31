class AppSettings {
  double pctA, pctB, pctC;
  int warnDays1, warnDays2, warnDays3; // 3 تنبيهات
  int alertRepeatCount;
  String bankName, bankAccountName, bankAccountNumber, bankPhone;
  String schoolName, accountantName;

  AppSettings({
    this.pctA = 50, this.pctB = 25, this.pctC = 25,
    this.warnDays1 = 14, // افتراضي 14 يوم
    this.warnDays2 = 7,  // افتراضي 7 أيام
    this.warnDays3 = 1,  // افتراضي يوم واحد
    this.alertRepeatCount = 1,
    this.bankName = '', this.bankAccountName = '',
    this.bankAccountNumber = '', this.bankPhone = '',
    this.schoolName = 'اسم المدرسة',
    this.accountantName = 'اسم المحاسب',
  });

  Map<String, dynamic> toJson() => {
        'pctA': pctA, 'pctB': pctB, 'pctC': pctC,
        'warnDays1': warnDays1, 'warnDays2': warnDays2, 'warnDays3': warnDays3,
        'alertRepeatCount': alertRepeatCount,
        'bankName': bankName, 'bankAccountName': bankAccountName,
        'bankAccountNumber': bankAccountNumber, 'bankPhone': bankPhone,
        'schoolName': schoolName, 'accountantName': accountantName,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        pctA: (j['pctA'] ?? 50).toDouble(), pctB: (j['pctB'] ?? 25).toDouble(), pctC: (j['pctC'] ?? 25).toDouble(),
        warnDays1: j['warnDays1'] ?? 14,
        warnDays2: j['warnDays2'] ?? 7,
        warnDays3: j['warnDays3'] ?? 1,
        alertRepeatCount: j['alertRepeatCount'] ?? 1,
        bankName: j['bankName'] ?? '', bankAccountName: j['bankAccountName'] ?? '',
        bankAccountNumber: j['bankAccountNumber'] ?? '', bankPhone: j['bankPhone'] ?? '',
        schoolName: j['schoolName'] ?? 'اسم المدرسة',
        accountantName: j['accountantName'] ?? 'اسم المحاسب',
      );
}
