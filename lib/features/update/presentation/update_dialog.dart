import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../update/data/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateConfig config;

  const UpdateDialog({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !config.forceUpdate, // Prevent back button if forced
      onPopInvoked: (didPop) {
        if (!didPop && config.forceUpdate) {
           // Exit app if they try to back out of force update
           SystemNavigator.pop();
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'আপডেট উপলব্ধ', // "Update Available"
          style: GoogleFonts.tiroBangla(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.system_update, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              config.updateMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.tiroBangla(fontSize: 16),
            ),
            if (config.forceUpdate) ...[
              const SizedBox(height: 10),
              Text(
                'অ্যাপটি ব্যবহার চালিয়ে যেতে অনুগ্রহ করে আপডেট করুন।', // Force update note
                textAlign: TextAlign.center,
                style: GoogleFonts.tiroBangla(fontSize: 14, color: Colors.red),
              ),
            ]
          ],
        ),
        actions: [
          if (!config.forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'পরে', // "Later"
                style: GoogleFonts.tiroBangla(color: Colors.grey),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _launchPlayStore(),
            child: Text(
              'আপডেট করুন', // "Update"
              style: GoogleFonts.tiroBangla(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPlayStore() async {
    final uri = Uri.parse(config.playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
