import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/student.dart';
import '../models/payment.dart';
import '../models/settings.dart';
import 'helpers.dart';

class ReceiptGenerator {
  static Future<void> printReceipt({
    required Student student,
    required Payment payment,
    required AppSettings settings,
    required double remainingAfterPayment,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    // مقاس A5 (نصف ورقة A4)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // رأس الإيصال (شعار واسم المدرسة)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(settings.schoolName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('إيصال استلام نقدية', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // بيانات الطالب والدفعة
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('اسم الطالب: ${student.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text('الصف: ${stageName(student.stage)} - ${classNames[student.cls - 1]}'),
                      pw.SizedBox(height: 4),
                      pw.Text('التاريخ: ${dateStr(payment.date)}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('رقم الإيصال: ${payment.id.substring(0, 6).toUpperCase()}'),
                      pw.SizedBox(height: 4),
                      pw.Text('طريقة الدفع: ${methodLabel(payment.method)}'),
                      if (payment.reference.isNotEmpty) 
                        pw.Text('المرجع: ${payment.reference}'),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // تفاصيل المبلغ
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المبلغ المدفوع:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${money(payment.amount)} ج.س', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('المتبقي على الطالب: ${money(remainingAfterPayment)} ج.س', style: pw.TextStyle(color: PdfColors.red800)),
                  pw.Text('نوع الدفعة: ${feeTypeLabel(payment.type)}'),
                ],
              ),
              
              pw.Spacer(),

              // التوقيع
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('توقيع المستلم'),
                      pw.SizedBox(height: 20),
                      pw.Text('.......................'),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('المحاسب: ${settings.accountantName}'),
                      pw.SizedBox(height: 20),
                      pw.Text('.......................'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('شكراً لتعاملكم معنا', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    // عرض المعاينة للطباعة
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Receipt_${student.name}_${payment.id.substring(0, 6)}.pdf',
    );
  }
}
