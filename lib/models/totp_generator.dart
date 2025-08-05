import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:base32/base32.dart';

class TOTPGenerator {
  static String generateTOTP(String secret, {int digits = 6, int period = 30}) {
    try {
      // Decode base32 secret
      final key = base32.decode(secret.replaceAll(' ', '').toUpperCase());

      // Get current time step
      final timeStep = (DateTime.now().millisecondsSinceEpoch / 1000 / period)
          .floor();

      // Convert time step to 8-byte array
      final timeBytes = ByteData(8);
      timeBytes.setUint64(0, timeStep, Endian.big);

      // Generate HMAC-SHA1
      final hmac = Hmac(sha1, key);
      final hash = hmac.convert(timeBytes.buffer.asUint8List());

      // Dynamic truncation
      final offset = hash.bytes.last & 0x0F;
      final truncatedHash = ByteData.sublistView(
        Uint8List.fromList(hash.bytes),
        offset,
        offset + 4,
      );

      final code = truncatedHash.getUint32(0, Endian.big) & 0x7FFFFFFF;
      final otp = (code % pow(10, digits)).toString().padLeft(digits, '0');

      return otp;
    } catch (e) {
      return '000000';
    }
  }

  static int getRemainingSeconds({int period = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    return period - (now % period).floor();
  }
}
