import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinCtrl = TextEditingController();
  String _error = '';
  int _tapCount = 0;

  void _submit() {
    final app = context.read<AppProvider>();
    if (app.checkPin(_pinCtrl.text)) {
      app.unlock();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => _error = 'كلمة السر غير صحيحة');
      _pinCtrl.clear();
    }
  }

  void _handleSecretTap() {
    _tapCount++;
    if (_tapCount >= 7) {
      _tapCount = 0;
      _showAdminPinDialog();
    }
  }

  void _showAdminPinDialog() {
    final adminPinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دخول المطور'),
        content: TextField(
          controller: adminPinCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'كلمة سر المطور'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (adminPinCtrl.text == 'Rua@05005') {
                Navigator.pop(ctx);
                _showChangePinDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة سر المطور خاطئة'), backgroundColor: AppColors.none));
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    final newPinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل كلمة سر التطبيق'),
        content: TextField(
          controller: newPinCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'كلمة السر الجديدة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (newPinCtrl.text.length >= 4) {
                await context.read<AppProvider>().savePin(newPinCtrl.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ تم تعديل كلمة السر'), backgroundColor: AppColors.ok));
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _handleSecretTap,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.primary(context).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.lock_outline, size: 64, color: AppColors.primary(context)),
                ),
                const SizedBox(height: 24),
                const Text('رسومك الدراسية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('أدخل كلمة السر للدخول', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 32),
                TextField(
                  controller: _pinCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(hintText: '••••'),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_error, style: const TextStyle(color: AppColors.none, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _submit, child: const Text('دخول')),
                ),
                const SizedBox(height: 16),
                const Text('كلمة السر الافتراضية: 1234', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
