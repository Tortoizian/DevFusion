import 'package:flutter_test/flutter_test.dart';
import 'package:splitsmart/core/utils/upi_launcher.dart';

void main() {
  test('buildUri encodes settlement parameters', () {
    final uri = UpiLauncher.buildUri(
      vpa: 'test@upi',
      payeeName: 'Ananya',
      amount: 1240,
      memo: 'SplitSmart: Goa 2025 (6 expenses)',
    );

    expect(uri.scheme, 'upi');
    expect(uri.host, 'pay');
    expect(uri.queryParameters['pa'], 'test@upi');
    expect(uri.queryParameters['pn'], 'Ananya');
    expect(uri.queryParameters['am'], '1240.00');
    expect(uri.queryParameters['cu'], 'INR');
    expect(uri.queryParameters['tn'], 'SplitSmart: Goa 2025 (6 expenses)');
  });
}
