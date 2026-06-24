import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
