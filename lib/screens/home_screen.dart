import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import '../widgets/stat_card.dart';
import 'student_form_screen.dart';
import 'student_detail_screen.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';
import 'lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  Stage? _stageFilter;
  int? _clsFilter;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    var list = app.filterStudents(search: _searchCtrl.text.trim(), stage: _stageFilter, cls: _clsFilter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رسومك الدراسية'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${app.allAlerts.length}'),
              isLabelVisible: app.allAlerts.isNotEmpty,
              child: const Icon(Icons.notifications),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () {
              app.lock();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStats(app),
          _buildFilters(),
          Expanded(child: _buildList(list)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFormScreen())).then((_) => setState(() {})),
        backgroundColor: AppColors.primary(context),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('طالب جديد'),
      ),
    );
  }

  Widget _buildStats(AppProvider app) {
    return Container(
      color: AppColors.primary(context),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: StatsGrid(
        cards: [
          StatCard(label: 'الطلاب', value: '${app.students.length}', icon: Icons.people, color: Colors.white),
          StatCard(label: 'المطلوب', value: money(app.totalRequired), icon: Icons.assignment, color: Colors.amber.shade300),
          StatCard(label: 'المدفوع', value: money(app.totalPaid), icon: Icons.check_circle, color: Colors.green.shade300, progress: app.paidPct),
          StatCard(label: 'المتبقي', value: money(app.totalRemaining), icon: Icons.account_balance_wallet, color: Colors.red.shade300),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    int maxClasses = _stageFilter != null ? stageCount(_stageFilter!) : 6;
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface(context),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(hintText: 'بحث بالاسم...', prefixIcon: Icon(Icons.search)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Stage?>(
                  value: _stageFilter,
                  decoration: const InputDecoration(labelText: 'المرحلة', isDense: true),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(value: Stage.primary, child: Text('ابتدائي')),
                    DropdownMenuItem(value: Stage.middle, child: Text('متوسط')),
                    DropdownMenuItem(value: Stage.high, child: Text('ثانوي')),
                  ],
                  onChanged: (v) => setState(() {
                    _stageFilter = v;
                    _clsFilter = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _clsFilter,
                  decoration: const InputDecoration(labelText: 'الصف', isDense: true),
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

  Widget _buildList(List<Student> list) {
    if (list.isEmpty) {
      return const Center(child: Text('لا يوجد طلاب', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final s = list[i];
        final pct = s.paidPct;
        final c = pct >= 1 ? AppColors.ok : pct > 0 ? AppColors.partial : AppColors.none;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(backgroundColor: c.withOpacity(0.15), child: Icon(Icons.person, color: c)),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${stageName(s.stage)} - ${classNames[s.cls - 1]}', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: pct, color: c, backgroundColor: Colors.grey.shade200, minHeight: 6),
              ],
            ),
            trailing: Text(money(s.remaining), style: const TextStyle(color: AppColors.none, fontWeight: FontWeight.bold, fontSize: 13)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id))).then((_) => setState(() {})),
          ),
        );
      },
    );
  }
}
