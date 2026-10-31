import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import 'student_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filter = 'all'; // all | overdue | soon

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    var alerts = app.allAlerts;

    if (_filter == 'overdue') {
      alerts = alerts.where((a) => a['overdue'] == true).toList();
    } else if (_filter == 'soon') {
      alerts = alerts.where((a) => a['overdue'] == false).toList();
    }

    final overdueCount =
        app.allAlerts.where((a) => a['overdue'] == true).length;
    final soonCount =
        app.allAlerts.where((a) => a['overdue'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        title: const Text('تنبيهات الأقساط'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // معلومات عن فترة التنبيه
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.amber.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'التنبيه قبل ${app.settings.warnDays} يوم من تاريخ الاستحقاق',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // فلاتر
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('الكل'),
                        const SizedBox(width: 6),
                        _badge('${overdueCount + soonCount}', Colors.grey),
                      ],
                    ),
                    selected: _filter == 'all',
                    onSelected: (_) => setState(() => _filter = 'all'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('متأخر'),
                        const SizedBox(width: 6),
                        _badge('$overdueCount', Colors.red),
                      ],
                    ),
                    selected: _filter == 'overdue',
                    selectedColor: Colors.red.shade100,
                    onSelected: (_) => setState(() => _filter = 'overdue'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ChoiceChip(
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('قريب'),
                        const SizedBox(width: 6),
                        _badge('$soonCount', Colors.orange),
                      ],
                    ),
                    selected: _filter == 'soon',
                    selectedColor: Colors.orange.shade100,
                    onSelected: (_) => setState(() => _filter = 'soon'),
                  ),
                ),
              ],
            ),
          ),
          // القائمة
          Expanded(
            child: alerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            size: 72, color: Colors.green.shade400),
                        const SizedBox(height: 12),
                        const Text('لا توجد تنبيهات حالياً',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('كل الأقساط في مواعيدها 👌',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: alerts.length,
                    itemBuilder: (_, i) => _alertTile(alerts[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String txt, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        txt,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _alertTile(Map<String, dynamic> a) {
    final s = a['student'] as Student;
    final days = a['days'] as int;
    final overdue = days < 0;
    final color = overdue ? kNoneColor : kPartialColor;
    final due = a['due'] as DateTime?;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.4), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: s.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  overdue ? Icons.warning : Icons.access_time,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            overdue
                                ? 'متأخر ${days.abs()} يوم'
                                : days == 0
                                    ? 'اليوم'
                                    : 'بعد $days يوم',
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${stageName(s.stage)} — ${classNames[s.cls - 1]}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.payment, size: 12, color: color),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${feeTypeLabel(a['type'] as FeeType)} — متبقي ${money(a['remaining'] as double)}',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: color,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (due != null)
                      Text(
                        'الاستحقاق: ${dateStr(due)}',
                        style: const TextStyle(
                            fontSize: 10.5, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
