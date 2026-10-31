import 'student.dart';

enum PaymentMethod { cash, bank }

String methodLabel(PaymentMethod m) => m == PaymentMethod.cash ? 'كاش' : 'تحويل بنكي';

class Payment {
  String id;
  FeeType type;
  double amount;
  PaymentMethod method;
  String reference; 
  DateTime date;

  Payment({
    required this.id, required this.type, required this.amount,
    required this.method, required this.reference, required this.date,
  });

  // إضافة اختصار (getter) لرقم العملية لكي يتوافق مع الكود
  String get ref => reference;

  Map<String, dynamic> toJson() => {
        'id': id, 'type': type.index, 'amount': amount,
        'method': method.index, 'reference': reference, 'date': date.toIso8601String(),
      };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'], type: FeeType.values[j['type']], amount: (j['amount'] ?? 0).toDouble(),
        method: PaymentMethod.values[j['method']], reference: j['reference'] ?? '',
        date: DateTime.parse(j['date']),
      );
}
