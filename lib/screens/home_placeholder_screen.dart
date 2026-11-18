import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Temporary screen shown after a successful sign in.
/// We will replace this with the real Home (Hire) page next.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Signed in!\nHome page coming next.',
            textAlign: TextAlign.center,
            style: AppText.heading20,
          ),
        ),
      ),
    );
  }
}