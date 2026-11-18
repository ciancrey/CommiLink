import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/logo_lockup.dart';
import '../widgets/primary_button.dart';
import 'create_account_screen.dart';
import 'home_placeholder_screen.dart';

/// Page 02 · Sign in (Figma node 6:75)
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const String _demoPassword = 'demo1234';

  // Demo accounts shown as chips (label, email).
  static const List<(String, String)> _demoAccounts = [
    ('Lea · client · ₱5,000', 'lea@demo.com'),
    ('Maria · designer', 'maria@demo.com'),
    ('Josh · developer', 'josh@demo.com'),
    ('Admin', 'admin@demo.com'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemo(String email) {
    // Clear old validation errors first, then fill in the demo values.
    _formKey.currentState?.reset();
    setState(() {
      _emailController.text = email;
      _passwordController.text = _demoPassword;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: check the account against the real user data (next steps).
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePlaceholderScreen()),
    );
  }

  void _comingSoon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: LogoLockup(),
                ),
                const SizedBox(height: 40),
                Text('Welcome back', style: AppText.display32),
                const SizedBox(height: 8),
                Text(
                  'Find trusted freelancers. Get paid safely.',
                  style: AppText.body14.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  hint: 'Enter your password',
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () =>
                        _comingSoon('Password reset is not part of the demo.'),
                    child: Text(
                      'Forgot password?',
                      style: AppText.small12Medium.copyWith(
                        color: AppColors.wine700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Sign in',
                  icon: Icons.login_rounded,
                  onPressed: _submit,
                ),
                const SizedBox(height: 18),
                Center(
                  child: Wrap(
                    spacing: 4,
                    children: [
                      Text(
                        'New to CommiLink?',
                        style: AppText.body14.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateAccountScreen(),
                          ),
                        ),
                        child: Text(
                          'Join now',
                          style: AppText.label14.copyWith(
                            color: AppColors.wine700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Demo accounts · tap to fill',
                        style: AppText.caption11,
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final account in _demoAccounts)
                      _DemoChip(
                        label: account.$1,
                        onTap: () => _fillDemo(account.$2),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            label,
            style: AppText.body14Medium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}