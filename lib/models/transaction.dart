class FinancialTransaction {
  String id;
  String type; // deposit, withdraw, transfer
  String method; // cash, bank
  String fromAccount; // cash, bank (للتحويل والسحب)
  String toAccount; // cash, bank (للتحويل)
  String entityName; // اسم المودع أو جهة السحب
  double amount;
  DateTime date;

  FinancialTransaction({
    required this.id,
    required this.type,
    required this.method,
    this.fromAccount = '',
    this.toAccount = '',
    required this.entityName,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'method': method,
        'fromAccount': fromAccount,
        'toAccount': toAccount,
        'entityName': entityName,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory FinancialTransaction.fromJson(Map<String, dynamic> j) => FinancialTransaction(
        id: j['id'],
        type: j['type'],
        method: j['method'],
        fromAccount: j['fromAccount'] ?? '',
        toAccount: j['toAccount'] ?? '',
        entityName: j['entityName'] ?? '',
        amount: (j['amount'] ?? 0).toDouble(),
        date: DateTime.parse(j['date']),
      );
}
