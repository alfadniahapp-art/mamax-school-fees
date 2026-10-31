import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});
  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('إدارة وتسجيل الفصول')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeesTable(),
          const SizedBox(height: 16),
          _buildClassRegistration(),
        ],
      ),
    );
  }

  Widget _buildFeesTable() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الرسوم لكل الفصول', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary(context))),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('المرحلة')),
                  DataColumn(label: Text('الصف')),
                  DataColumn(label: Text('الرسوم الأساسية')),
                ],
                rows: stagesList.expand((st) {
                  return List.generate(stageCount(st.stage), (i) {
                    return DataRow(cells: [
                      DataCell(Text(st.name)),
                      DataCell(Text(classNames[i])),
                      DataCell(Text(money(150000))), // يمكنك ربطها بمتغيرات حقيقية
                    ]);
                  });
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassRegistration() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('تسجيل الفصول قيد التطوير', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
