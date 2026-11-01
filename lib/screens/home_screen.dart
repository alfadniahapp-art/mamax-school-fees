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
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
        centerTitle: true,
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
                SliverToBoxAdapter(child: _buildFilters(context)),
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
                  const SliverFillRemaining(child: Center(child: Text('لا يوجد طلاب مطابقون للبحث', style: TextStyle(color: Colors.grey, fontSize: 16)))),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: color, 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(vertical: 14), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
            elevation: 4,
            shadowColor: color.withOpacity(0.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 24), const SizedBox(height: 6), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]),
        ),
      ),
    );
  }

  // نافذة تسجيل دفعة سريعة
  void _showQuickPayment(BuildContext context, AppProvider app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // الفلترة
            var filtered = app.students.where((s) {
              if (_quickStage != null && s.stage != _quickStage) return false;
              if (_quickCls != null && s.cls != _quickCls) return false;
              if (_quickGender != null && s.gender != _quickGender) return false;
              if (_quickSearch.isNotEmpty && !s.name.contains(_quickSearch)) return false;
              return true;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('تسجيل دفعة سريعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark(context))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  
                  // زر إضافة طالب جديد (تم إصلاح خطأ const)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx); // إغلاق نافذة الدفع
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentFormScreen())).then((_) => setState(() {}));
                      },
                      icon: Icon(Icons.person_add, color: AppColors.primary(context)),
                      label: Text('إضافة طالب جديد', style: TextStyle(color: AppColors.primary(context), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.primary(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // حقول البحث
                  TextField(
                    decoration: _inputDecoration(context, '', prefixIcon: Icons.search, hintText: 'بحث بالاسم...'),
                    onChanged: (v) => setModalState(() => _quickSearch = v.trim()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Stage?>(
                          value: _quickStage,
                          decoration: _inputDecoration(context, 'المرحلة'),
                          items: const [DropdownMenuItem(value: null, child: Text('الكل')), DropdownMenuItem(value: Stage.primary, child: Text('ابتدائي')), DropdownMenuItem(value: Stage.middle, child: Text('متوسط')), DropdownMenuItem(value: Stage.high, child: Text('ثانوي'))],
                          onChanged: (v) => setModalState(() { _quickStage = v; _quickCls = null; }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          value: _quickCls,
                          decoration: _inputDecoration(context, 'الصف'),
                          items: [const DropdownMenuItem(value: null, child: Text('الكل')), ...List.generate(_quickStage != null ? stageCount(_quickStage!) : 6, (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i])))],
                          onChanged: (v) => setModalState(() => _quickCls = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Gender?>(
                    value: _quickGender,
                    decoration: _inputDecoration(context, 'القسم'),
                    items: const [DropdownMenuItem(value: null, child: Text('الكل')), DropdownMenuItem(value: Gender.boys, child: Text('بنين')), DropdownMenuItem(value: Gender.girls, child: Text('بنات'))],
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
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder(context), width: 1.5),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark(context))),
                                subtitle: Text('${stageName(s.stage)} • ${classNames[s.cls - 1]} • ${genderName(s.gender)}', style: const TextStyle(fontSize: 12)),
                                trailing: Text(money(s.remaining), style: const TextStyle(color: AppColors.none, fontWeight: FontWeight.bold, fontSize: 14)),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      decoration: BoxDecoration(
        color: AppColors.primary(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: AppColors.primary(context).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
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
          const Divider(color: Colors.white24, height: 28),
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
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    int maxClasses = _stageFilter != null ? stageCount(_stageFilter!) : 6;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppColors.cardBorder(context), width: 1.5), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl, 
            decoration: _inputDecoration(context, '', prefixIcon: Icons.search, hintText: 'بحث بالاسم...'), 
            onChanged: (_) => setState(() {})
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Stage?>(
                  value: _stageFilter,
                  decoration: _inputDecoration(context, 'المرحلة'),
                  items: const [DropdownMenuItem(value: null, child: Text('الكل')), DropdownMenuItem(value: Stage.primary, child: Text('ابتدائي')), DropdownMenuItem(value: Stage.middle, child: Text('متوسط')), DropdownMenuItem(value: Stage.high, child: Text('ثانوي'))],
                  onChanged: (v) => setState(() { _stageFilter = v; _clsFilter = null; }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _clsFilter,
                  decoration: _inputDecoration(context, 'الصف'),
                  items: [const DropdownMenuItem(value: null, child: Text('الكل')), ...List.generate(maxClasses, (i) => DropdownMenuItem(value: i + 1, child: Text(classNames[i])))],
                  onChanged: (v) => setState(() => _clsFilter = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label, {IconData? prefixIcon, String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      filled: true,
      fillColor: AppColors.surface(context),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.inputBorder(context), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary(context), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildStudentCard(Student s) {
    final pct = s.paidPct;
    final c = pct >= 1 ? AppColors.ok : pct > 0 ? AppColors.partial : AppColors.none;
    return Container(
      margin: const EdgeInsets.only(bottom: 12, right: 16, left: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: AppColors.cardBorder(context), width: 1.5), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id))).then((_) => setState(() {})),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26, 
                      backgroundColor: c.withOpacity(0.15), 
                      child: Text(s.name.substring(0, 1), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 20))
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark(context))),
                          const SizedBox(height: 4),
                          Text('${stageName(s.stage)} • ${classNames[s.cls - 1]} • ${genderName(s.gender)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(money(s.remaining), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 15)),
                        const Text('المتبقي', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8), 
                  child: LinearProgressIndicator(value: pct, color: c, backgroundColor: Colors.grey.shade100, minHeight: 8)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
