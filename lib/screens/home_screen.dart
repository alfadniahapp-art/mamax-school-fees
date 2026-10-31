import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import 'student_detail_screen.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';
import 'lock_screen.dart';
import 'class_management_screen.dart';
import 'reports_screen.dart';
import 'student_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  Stage? _stageFilter;
  int? _clsFilter;
  Gender? _genderFilter;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    var list = app.students.where((s) {
      if (_stageFilter != null && s.stage != _stageFilter) return false;
      if (_clsFilter != null && s.cls != _clsFilter) return false;
      if (_genderFilter != null && s.gender != _genderFilter) return false;
      if (_searchCtrl.text.isNotEmpty && !s.name.contains(_searchCtrl.text.trim())) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), tooltip: 'التقارير', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
          IconButton(icon: const Icon(Icons.settings), tooltip: 'الإعدادات', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          IconButton(icon: const Icon(Icons.lock_outline), tooltip: 'قفل', onPressed: () {
            app.lock();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockScreen()));
          }),
        ],
      ),
      body: Column(
        children: [
          _buildTopStats(app),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildFilters()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (list.isEmpty) return const SizedBox.shrink();
                      return _buildStudentCard(list[index]);
                    },
                    childCount: list.length,
                  ),
                ),
                if (list.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('لا يوجد طلاب مسجلون حالياً', style: TextStyle(color: Colors.grey)))),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'report',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen())).then((_) => setState(() {})),
            backgroundColor: const Color(0xFFD97706),
            icon: const Icon(Icons.group_add),
            label: const Text('إدارة الفصول'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFormScreen())).then((_) => setState(() {})),
            backgroundColor: AppColors.primary(context),
            icon: const Icon(Icons.person_add),
            label: const Text('طالب جديد'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStats(AppProvider app) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.primary(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: AppColors.primary(context).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _miniStat('الطلاب', '${app.students.length}', Icons.people),
          _miniStat('المطلوب', money(app.totalRequired), Icons.assignment),
          _miniStat('المدفوع', money(app.totalPaid), Icons.check_circle),
          _miniStat('المتبقي', money(app.totalRemaining), Icons.warning),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildFilters() {
    int maxClasses = _stageFilter != null ? stageCount(_stageFilter!) : 6;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو رقم الهاتف...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Stage?>(
                  value: _stageFilter,
                  decoration: const InputDecoration(labelText: 'المرحلة', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: Stage.primary, child: Text('ابتدائي')),
                    DropdownMenuItem(value: Stage.middle, child: Text('متوسط')),
                    DropdownMenuItem(value: Stage.high, child: Text('ثانوي')),
                  ],
                  onChanged: (v) => setState(() { _stageFilter = v; _clsFilter = null; }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _clsFilter,
                  decoration: const InputDecoration(labelText: 'الصف', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ...List.generate(maxClasses, (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))),
                  ],
                  onChanged: (v) => setState(() => _clsFilter = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Student s) {
    final pct = s.paidPct;
    final c = pct >= 1 ? AppColors.ok : pct > 0 ? AppColors.partial : AppColors.none;
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 16, left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id))).then((_) => setState(() {})),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: c.withOpacity(0.15),
                      child: Text(s.name.substring(0, 1), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('${stageName(s.stage)} • ${classNames[s.cls - 1]} • ${genderName(s.gender)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(money(s.remaining), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 14)),
                        const Text('المتبقي', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: pct, color: c, backgroundColor: Colors.grey.shade100, minHeight: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
