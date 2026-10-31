import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import '../widgets/stat_card.dart';
import 'student_form_screen.dart';
import 'student_detail_screen.dart';
import 'payments_screen.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  Stage? _stageFilter;
  int? _clsFilter;
  String _sortBy = 'name'; // name | remaining

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    if (app.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        title: const Text('دفتر رسوم الطلاب'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'التنبيهات',
            icon: Badge(
              label: Text('${app.allAlerts.length}'),
              isLabelVisible: app.allAlerts.isNotEmpty,
              backgroundColor: Colors.red,
              child: const Icon(Icons.notifications),
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlertsScreen())),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStats(app),
          _buildFilters(app),
          Expanded(child: _buildList(app)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const StudentFormScreen(student: null)),
        ).then((_) => setState(() {})),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add),
        label: const Text('طالب جديد'),
      ),
    );
  }

  Widget _buildStats(AppProvider app) {
    return Container(
      color: kPrimaryColor,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: StatsGrid(
        cards: [
          StatCard(
            label: 'الطلاب',
            value: '${app.students.length}',
            icon: Icons.people,
            color: Colors.white,
          ),
          StatCard(
            label: 'المطلوب',
            value: money(app.totalRequired),
            icon: Icons.assignment,
            color: Colors.amber.shade300,
          ),
          StatCard(
            label: 'المدفوع',
            value: money(app.totalPaid),
            icon: Icons.check_circle,
            color: Colors.green.shade300,
            progress: app.paidPct,
          ),
          StatCard(
            label: 'المتبقي',
            value: money(app.totalRemaining),
            icon: Icons.account_balance_wallet,
            color: Colors.red.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppProvider app) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'بحث بالاسم...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Stage?>(
                  value: _stageFilter,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'المرحلة',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('الكل')),
                    DropdownMenuItem(
                        value: Stage.primary, child: Text('ابتدائي')),
                    DropdownMenuItem(
                        value: Stage.middle, child: Text('متوسط')),
                    DropdownMenuItem(
                        value: Stage.high, child: Text('ثانوي')),
                  ],
                  onChanged: (v) => setState(() {
                    _stageFilter = v;
                    _clsFilter = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _clsFilter,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'الصف',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ...List.generate(
                      _stageFilter != null
                          ? stageCount(_stageFilter!)
                          : 6,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text(classNames[i])),
                    ),
                  ],
                  onChanged: (v) => setState(() => _clsFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('الاسم')),
                    DropdownMenuItem(
                        value: 'remaining', child: Text('المتبقي')),
                  ],
                  onChanged: (v) => setState(() => _sortBy = v ?? 'name'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppProvider app) {
    var list = app.filterStudents(
      search: _searchCtrl.text.trim(),
      stage: _stageFilter,
      cls: _clsFilter,
    );

    if (_sortBy == 'remaining') {
      list.sort((a, b) => b.remaining.compareTo(a.remaining));
    } else {
      final order = {
        Stage.primary: 0,
        Stage.middle: 1,
        Stage.high: 2,
      };
      list.sort((a, b) {
        if (order[a.stage] != order[b.stage]) {
          return order[a.stage]! - order[b.stage]!;
        }
        if (a.cls != b.cls) return a.cls - b.cls;
        return a.name.compareTo(b.name);
      });
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('لا يوجد طلاب مطابقون',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              app.students.isEmpty
                  ? 'اضغط زر "طالب جديد" للبدء'
                  : 'جرّب تعديل الفلاتر',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: list.length,
      itemBuilder: (_, i) => _studentTile(list[i]),
    );
  }

  Widget _studentTile(Student s) {
    final pct = s.paidPct;
    Color c;
    if (pct >= 1) {
      c = kOkColor;
    } else if (pct > 0) {
      c = kPartialColor;
    } else {
      c = kNoneColor;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: s.id)),
        ).then((_) => setState(() {})),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: c.withOpacity(0.15),
                child: Icon(Icons.person, color: c, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stageName(s.stage)} — ${classNames[s.cls - 1]}',
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade200,
                        color: c,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'مدفوع: ${money(s.totalPaid)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: c,
                              fontWeight: FontWeight.bold),
                        ),
                        const Text(' • ',
                            style: TextStyle(color: Colors.grey)),
                        Text(
                          'متبقي: ${money(s.remaining)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
