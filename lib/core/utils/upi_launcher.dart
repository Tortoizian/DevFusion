import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class UpiLauncher {
  static Uri buildUri({
    required String vpa,
    required String payeeName,
    required double amount,
    required String memo,
  }) {
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': vpa.trim(),
        'pn': payeeName.trim(),
        'am': amount.toStringAsFixed(2),
        'cu': 'INR',
        'tn': memo.trim(),
      },
    );
  }

  static Future<bool> launchSettlement({
    required String vpa,
    required String payeeName,
    required double amount,
    required String memo,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final uri = buildUri(vpa: vpa, payeeName: payeeName, amount: amount, memo: memo);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
