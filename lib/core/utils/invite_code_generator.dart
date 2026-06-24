import 'dart:math';

/// Generates 6-character uppercase alphanumeric invite codes for groups.
abstract final class InviteCodeGenerator {
  static const _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const _length = 6;
  static final _random = Random();

  static String generate() {
    return List.generate(
      _length,
      (_) => _charset[_random.nextInt(_charset.length)],
    ).join();
  }
}
