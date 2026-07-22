import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum SupplierBillAttachmentMode { imageOnly, imageOrPdf }

final class SupplierBillAttachmentService {
  const SupplierBillAttachmentService._();

  static String fileName(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    return p.basename(path);
  }

  static Future<String?> pickAndCopy({
    required String batchCode,
    required SupplierBillAttachmentMode mode,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: mode == SupplierBillAttachmentMode.imageOnly
          ? FileType.image
          : FileType.custom,
      allowedExtensions: mode == SupplierBillAttachmentMode.imageOnly
          ? null
          : const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      allowMultiple: false,
    );

    final sourcePath = result?.files.single.path;
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return null;
    }

    final source = File(sourcePath);
    final docDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(
      p.join(docDir.path, 'lotus_erp', 'supplier_bills'),
    );
    await targetDir.create(recursive: true);
    final extension =
        p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
    final fileName =
        '${batchCode}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final target = File(p.join(targetDir.path, fileName));
    final copied = await source.copy(target.path);
    return copied.path;
  }
}
