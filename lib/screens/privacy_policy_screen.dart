import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F3460),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Heading('BeastBlocks – Privacy Policy'),
              _Body('Last updated: April 2026'),
              SizedBox(height: 16),

              _Heading('1. Who is responsible for your data?'),
              _Body(
                'BeastBlocks is a hobby project. If you have questions about your personal '
                'data, contact: beastris@alskami.se',
              ),
              SizedBox(height: 16),

              _Heading('2. What data do we collect and why?'),
              _SubHeading('Account data (only if you register)'),
              _Body(
                '• E-mail address — used to identify your account and send password-reset emails.\n'
                '• Alias — a public name shown on the global leaderboard.\n'
                '• Real name (optional) — stored in your profile, never shown publicly.\n'
                '• Country (optional) — shown as a flag emoji next to your leaderboard entry.\n\n'
                'Legal basis: performance of a contract (Article 6(1)(b) GDPR). '
                'You choose to create an account in order to use the leaderboard feature.',
              ),
              SizedBox(height: 8),
              _SubHeading('Game results'),
              _Body(
                '• Score, lines cleared, level — stored locally on your device at all times.\n'
                '• If you are signed in, qualifying results are also uploaded to the global '
                'leaderboard together with your alias and country code.\n\n'
                'Legal basis: performance of a contract (Article 6(1)(b) GDPR).',
              ),
              SizedBox(height: 8),
              _SubHeading('Technical data'),
              _Body(
                'Firebase (Google) automatically processes your IP address when you '
                'connect to their services. See Google\'s privacy policy for details: '
                'https://policies.google.com/privacy',
              ),
              SizedBox(height: 16),

              _Heading('3. Where is data stored?'),
              _Body(
                'Account data and leaderboard entries are stored in Google Firebase '
                'Firestore (region: europe-west1, Belgium). Google is certified under '
                'EU Standard Contractual Clauses and is a GDPR-compliant data processor.',
              ),
              SizedBox(height: 16),

              _Heading('4. How long is data kept?'),
              _Body(
                'Your data is kept for as long as your account exists. You can delete '
                'your account at any time (see section 5). Leaderboard entries posted '
                'while signed in are deleted together with your account.',
              ),
              SizedBox(height: 16),

              _Heading('5. Your rights (GDPR)'),
              _Body(
                '• Right to access — you can see all your profile data in the app.\n'
                '• Right to rectification — edit your alias, name, and country in your profile.\n'
                '• Right to erasure ("right to be forgotten") — delete your account in the '
                'app under Profile → Delete Account. This permanently removes your e-mail, '
                'profile, and all leaderboard entries.\n'
                '• Right to data portability — contact us to receive a copy of your data.\n'
                '• Right to object — you can stop using the service and delete your account at any time.\n\n'
                'To exercise any of these rights, contact: beastris@alskami.se',
              ),
              SizedBox(height: 16),

              _Heading('6. Cookies and tracking'),
              _Body(
                'The app does not use cookies or third-party tracking. Firebase may '
                'collect anonymised analytics data; this can be reviewed in their privacy policy.',
              ),
              SizedBox(height: 16),

              _Heading('7. Children'),
              _Body(
                'BeastBlocks is not directed at children under 13. We do not knowingly '
                'collect data from children.',
              ),
              SizedBox(height: 16),

              _Heading('8. Changes to this policy'),
              _Body(
                'If this policy changes materially, a notice will be shown in the app. '
                'Continued use after changes constitutes acceptance.',
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}

class _SubHeading extends StatelessWidget {
  final String text;
  const _SubHeading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) => Text(text);
}
