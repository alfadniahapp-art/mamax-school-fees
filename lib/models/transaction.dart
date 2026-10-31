class FinancialTransaction {
  String id, type, method, fromAccount, toAccount, entityName;
  double amount;
  DateTime date;
  
  // حقول البنك الجديدة
  String bankName;
  String accountHolderName;
  String referenceNumber;

  FinancialTransaction({
    required this.id, required this.type, required this.method,
    this.fromAccount = '', this.toAccount = '',
    required this.entityName, required this.amount, required this.date,
    this.bankName = '', this.accountHolderName = '', this.referenceNumber = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'type': type, 'method': method,
        'fromAccount': fromAccount, 'toAccount': toAccount,
        'entityName': entityName, 'amount': amount, 'date': date.toIso8601String(),
        'bankName': bankName, 'accountHolderName': accountHolderName, 'referenceNumber': referenceNumber,
      };

  factory FinancialTransaction.fromJson(Map<String, dynamic> j) => FinancialTransaction(
        id: j['id'], type: j['type'], method: j['method'],
        fromAccount: j['fromAccount'] ?? '', toAccount: j['toAccount'] ?? '',
        entityName: j['entityName'] ?? '', amount: (j['amount'] ?? 0).toDouble(),
        date: DateTime.parse(j['date']),
        bankName: j['bankName'] ?? '', accountHolderName: j['accountHolderName'] ?? '', referenceNumber: j['referenceNumber'] ?? '',
      );
}
