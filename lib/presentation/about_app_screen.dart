import 'package:flutter/cupertino.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('حول النظام')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/475686060_122111624468716899_7070205537672805384_n.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    CupertinoIcons.exclamationmark_circle,
                    size: 120,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'نظام مرن لإدارة نقاط البيع والملابس',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'هذا النظام يوفر حلولاً متكاملة لإدارة المخزون، المبيعات، الفواتير، التقارير، والعديد من الميزات الذكية لتسهيل عملك التجاري.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'جميع الحقوق محفوظة © 2025',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}
