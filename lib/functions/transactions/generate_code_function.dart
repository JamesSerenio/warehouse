import 'dart:math';

abstract final class GenerateCodeFunction {
  static const _characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate({Random? random}) {
    final generator = random ?? Random.secure();
    return List.generate(
      4,
      (_) => _characters[generator.nextInt(_characters.length)],
    ).join();
  }
}
