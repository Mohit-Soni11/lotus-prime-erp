import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/core/storage/file_signature_validator.dart';

void main() {
  test('accepts genuine PDF and rejects an extension-only spoof', () async {
    final directory = await Directory.systemTemp.createTemp('lotus_signature_');
    try {
      final validPdf = File('${directory.path}/certificate.pdf');
      await validPdf.writeAsBytes(const [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]);
      final spoofedPdf = File('${directory.path}/spoofed.pdf');
      await spoofedPdf.writeAsString('not a PDF');

      expect(await FileSignatureValidator.matchesDeclaredExtension(validPdf),
          isTrue);
      expect(await FileSignatureValidator.matchesDeclaredExtension(spoofedPdf),
          isFalse);
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('accepts matching image headers only', () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus_signature_image_');
    try {
      final validPng = File('${directory.path}/logo.png');
      await validPng.writeAsBytes(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);
      final mismatchedImage = File('${directory.path}/logo.jpg');
      await mismatchedImage.writeAsBytes(
        const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A],
      );

      expect(await FileSignatureValidator.matchesDeclaredExtension(validPng),
          isTrue);
      expect(
        await FileSignatureValidator.matchesDeclaredExtension(mismatchedImage),
        isFalse,
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
