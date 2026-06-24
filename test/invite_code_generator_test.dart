import 'package:flutter_test/flutter_test.dart';
import 'package:splitsmart/core/utils/invite_code_generator.dart';

void main() {
  test('generate returns 6 uppercase alphanumeric characters', () {
    final pattern = RegExp(r'^[A-Z0-9]{6}$');

    for (var i = 0; i < 20; i++) {
      expect(InviteCodeGenerator.generate(), matches(pattern));
    }
  });
}
