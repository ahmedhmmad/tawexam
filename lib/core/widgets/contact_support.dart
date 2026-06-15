import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Developer/support contact via WhatsApp or email. Used on the login screen
/// and the student home so students can reach support (e.g. for a forgotten
/// password, since there's no self-service reset yet).
class ContactSupport extends StatelessWidget {
  const ContactSupport({super.key, this.prompt = 'هل تحتاج مساعدة؟'});

  final String prompt;

  static const _whatsappNumber = '972599742821';
  static const _email = 'cs@megaserv.xyz';

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No handler installed (e.g. WhatsApp not present) — silently ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          prompt,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _open(Uri.parse('https://wa.me/$_whatsappNumber')),
              icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
              label: const Text('واتساب'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _open(Uri(scheme: 'mailto', path: _email)),
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('البريد'),
            ),
          ],
        ),
      ],
    );
  }
}
