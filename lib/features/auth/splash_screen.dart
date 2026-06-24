import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 72, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('SplitSmart', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('No more WhatsApp math.', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
