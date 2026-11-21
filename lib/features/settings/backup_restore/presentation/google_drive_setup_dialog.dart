import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleDriveSetupDialog extends StatelessWidget {
  const GoogleDriveSetupDialog({super.key});
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Set Up Google Drive Backup'),
        content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text(
                      'One-time setup for your Lotus ERP application. Your Gmail password is never required.'),
                  const SizedBox(height: 18),
                  const Text(
                      '1. Create or select a Google Cloud project and enable Google Drive API.'),
                  const SizedBox(height: 12),
                  const Text(
                      '2. Configure Google Auth Platform branding and audience. While testing, add your Google account as a test user.'),
                  const SizedBox(height: 12),
                  const Text(
                      '3. Create an OAuth client with application type “Desktop app”. Download its JSON file.'),
                  const SizedBox(height: 12),
                  const Text(
                      '4. Import that JSON below, then connect your Google account and approve Lotus ERP backup access.'),
                  const SizedBox(height: 16),
                  TextButton.icon(
                      onPressed: () => launchUrl(
                          Uri.parse(
                              'https://console.cloud.google.com/apis/library/drive.googleapis.com'),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: const Text('Open Google Cloud Setup')),
                  const SizedBox(height: 8),
                  const Text(
                      'For long-term scheduled access, publish the OAuth app when your Google setup is ready. Google test-mode authorization can expire and require reconnection.',
                      style: TextStyle(fontSize: 12)),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close')),
          FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.file_open_outlined, size: 18),
              label: const Text('Import Desktop Client JSON'))
        ],
      );
}
