import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'issued_invoice_archive.dart';

/// Lets a user restore an existing issued PDF that was never archived.
Future<Uint8List?> requestMissingIssuedPdf({
  required BuildContext context,
  required String documentNumber,
  required Future<Uint8List?> Function(Uint8List bytes) attachOriginal,
}) async {
  final shouldAttach = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Original PDF not archived'),
      content: Text(
        'The invoice $documentNumber is saved, but its original issued PDF '
        'is missing from the archive. If you have that PDF, attach it to '
        'restore View, Print and Share.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Attach original PDF'),
        ),
      ],
    ),
  );
  if (shouldAttach != true || !context.mounted) return null;

  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    final path = result?.files.singleOrNull?.path;
    if (path == null) return null;
    final bytes = await File(path).readAsBytes();
    IssuedInvoiceArchive.validatePdf(bytes);
    return await attachOriginal(bytes);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('This PDF could not be attached. Check the file and retry.'),
      ));
    }
    return null;
  }
}
