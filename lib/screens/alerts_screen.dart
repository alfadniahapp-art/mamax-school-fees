import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import 'student_detail_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final alerts = app.allAlerts;

    return Scaffold(
      appBar: AppBar(title: const Text('التنبيهات')),
      body: alerts.isEmpty
          ? const Center(child: Text('لا توجد تنبيهات حالياً', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (_, i) {
                final a = alerts[i];
                final s = a['student'] as Student;
                final days = a['days'] as int;
                final overdue = days < 0;
                final c = overdue ? AppColors.none : AppColors.partial;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(overdue ? Icons.warning : Icons.access_time, color: c),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${feeTypeLabel(a['type'] as FeeType)} - متبقي ${money(a['remaining'] as double)}'),
                    trailing: Text(overdue ? 'متأخر' : 'قريب', style: TextStyle(color: c, fontWeight: FontWeight.bold)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id))),
                  ),
                );
              },
            ),
    );
  }
}
