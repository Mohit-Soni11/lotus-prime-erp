import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class LocalPasswordHasher {
  final _algorithm = Argon2id(
    memory: 19456,
    iterations: 2,
    parallelism: 1,
    hashLength: 32,
  );

  Uint8List newSalt() => Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)));

  Future<Uint8List> hash(String secret, Uint8List salt) async {
    final key = await _algorithm.deriveKeyFromPassword(
      password: secret,
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  Future<bool> verify(String secret, List<int> salt, List<int> expected) async {
    final actual = await hash(secret, Uint8List.fromList(salt));
    var difference = actual.length ^ expected.length;
    for (var index = 0;
        index < actual.length && index < expected.length;
        index++) {
      difference |= actual[index] ^ expected[index];
    }
    return difference == 0;
  }

  String newRecoveryCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final chars =
        List.generate(20, (_) => alphabet[random.nextInt(alphabet.length)]);
    return [
      chars.sublist(0, 5).join(),
      chars.sublist(5, 10).join(),
      chars.sublist(10, 15).join(),
      chars.sublist(15, 20).join(),
    ].join('-');
  }
}
