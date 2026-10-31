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
import 'treasury_screen.dart';

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

  // متغيرات البحث في نافذة الدفع السريع
  String _quickSearch = '';
  Stage? _quickStage;
  int? _quickCls;
  Gender? _quickGender;

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

    final filteredRequired = list.fold(0.0, (sum, s) => sum + s.totalRequired);
    final filteredPaid = list.fold(0.0, (sum, s) => sum + s.totalPaid);
    final filteredRemaining = filteredRequired - filteredPaid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.account_balance_wallet), tooltip: 'الخزينة', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TreasuryScreen()))),
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
          _buildTopStats(app, list.length, filteredRequired, filteredPaid, filteredRemaining),
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
                  const SliverFillRemaining(child: Center(child: Text('لا يوجد طلاب مطابقون للبحث', style: TextStyle(color: Colors.grey)))),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionBtn('تسجيل دفعة', Icons.payment, const Color(0xFF10B981), () => _showQuickPayment(context, app)),
            _buildActionBtn('إضافة طالب', Icons.person_add, AppColors.primary(context), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFormScreen())).then((_) => setState(() {}))),
            _buildActionBtn('إدارة الفصول', Icons.group, const Color(0xFFD97706), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen())).then((_) => setState(() {}))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]),
        ),
      ),
    );
  }

  void _showQuickPayment(BuildContext context, AppProvider app) {
    if (app.students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف طالباً أولاً')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // الفلترة للبحث السريع
            var filtered = app.students.where((s) {
              if (_quickStage != null && s.stage != _quickStage) return false;
              if (_quickCls != null && s.cls != _quickCls) return false;
              if (_quickGender != null && s.gender != _quickGender) return false;
              if (_quickSearch.isNotEmpty && !s.name.contains(_quickSearch)) return false;
              return true;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تسجيل دفعة سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  
                  // أدوات البحث والفلترة
                  TextField(
                    decoration: InputDecoration(hintText: 'بحث بالاسم...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    onChanged: (v) => setModalState(() => _quickSearch = v.trim()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Stage?>(
                          value: _quickStage,
                          decoration: const InputDecoration(labelText: 'المرحلة', isDense: true),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('الكل')),
                            DropdownMenuItem(value: Stage.primary, child: Text('ابتدائي')),
                            DropdownMenuItem(value: Stage.middle, child: Text('متوسط')),
                            DropdownMenuItem(value: Stage.high, child: Text('ثانوي')),
                          ],
                          onChanged: (v) => setModalState(() { _quickStage = v; _quickCls = null; }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: _quickCls,
                          decoration: const InputDecoration(labelText: 'الصف', isDense: true),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('الكل')),
                            ...List.generate(_quickStage != null ? stageCount(_quickStage!) : 6, (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i]))),
                          ],
                          onChanged: (v) => setModalState(() => _quickCls = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Gender?>(
                    value: _quickGender,
                    decoration: const InputDecoration(labelText: 'القسم', isDense: true),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('الكل')),
                      DropdownMenuItem(value: Gender.boys, child: Text('بنين')),
                      DropdownMenuItem(value: Gender.girls, child: Text('بنات')),
                    ],
                    onChanged: (v) => setModalState(() => _quickGender = v),
                  ),
                  
                  const SizedBox(height: 16),
                  Expanded(
                    child: filtered.isEmpty 
                      ? const Center(child: Text('لا يوجد طلاب مطابقون', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final s = filtered[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${stageName(s.stage)} • ${classNames[s.cls - 1]} • ${genderName(s.gender)}'),
                                trailing: Text(money(s.remaining), style: const TextStyle(color: AppColors.none, fontWeight: FontWeight.bold)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id)));
                                },
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopStats(AppProvider app, int count, double req, double paid, double rem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.primary(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: AppColors.primary(context).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('الصندوق', money(app.cashBalance), Icons.money),
              _miniStat('البنك', money(app.bankBalance), Icons.account_balance),
              _miniStat('إجمالي الخزينة', money(app.cashBalance + app.bankBalance), Icons.account_balance_wallet),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('الطلاب', '$count', Icons.people),
              _miniStat('المطلوب', money(req), Icons.assignment),
              _miniStat('المدفوع', money(paid), Icons.check_circle),
              _miniStat('المتبقي', money(rem), Icons.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildFilters() {
    int maxClasses = _stageFilter != null ? stageCount(_stageFilter!) : 6;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'بحث بالاسم...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (_) => setState(() {})),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withOpacity(0.2), width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
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
                    CircleAvatar(radius: 22, backgroundColor: c.withOpacity(0.15), child: Text(s.name.substring(0, 1), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18))),
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
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct, color: c, backgroundColor: Colors.grey.shade100, minHeight: 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
