class AppSettings {
  double pctA, pctB, pctC;
  int warnDays, alertRepeatCount;
  String bankName, bankAccountName, bankAccountNumber, bankPhone;
  String schoolName, accountantName; // الحقول الجديدة

  AppSettings({
    this.pctA = 50, this.pctB = 25, this.pctC = 25,
    this.warnDays = 14, this.alertRepeatCount = 1,
    this.bankName = '', this.bankAccountName = '',
    this.bankAccountNumber = '', this.bankPhone = '',
    this.schoolName = 'اسم المدرسة', // القيمة الافتراضية
    this.accountantName = 'اسم المحاسب',
  });

  Map<String, dynamic> toJson() => {
        'pctA': pctA, 'pctB': pctB, 'pctC': pctC,
        'warnDays': warnDays, 'alertRepeatCount': alertRepeatCount,
        'bankName': bankName, 'bankAccountName': bankAccountName,
        'bankAccountNumber': bankAccountNumber, 'bankPhone': bankPhone,
        'schoolName': schoolName, 'accountantName': accountantName,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        pctA: (j['pctA'] ?? 50).toDouble(), pctB: (j['pctB'] ?? 25).toDouble(), pctC: (j['pctC'] ?? 25).toDouble(),
        warnDays: j['warnDays'] ?? 14, alertRepeatCount: j['alertRepeatCount'] ?? 1,
        bankName: j['bankName'] ?? '', bankAccountName: j['bankAccountName'] ?? '',
        bankAccountNumber: j['bankAccountNumber'] ?? '', bankPhone: j['bankPhone'] ?? '',
        schoolName: j['schoolName'] ?? 'اسم المدرسة',
        accountantName: j['accountantName'] ?? 'اسم المحاسب',
      );
}
