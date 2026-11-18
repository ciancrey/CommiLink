import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

/// Who the user wants to be in the app.
/// (We will move this to a models file later.)
enum UserRole { client, freelancer }

/// Page 03 · Create account (Figma node 6:146)
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();

  UserRole _role = UserRole.client;
  XFile? _photo;
  bool _hidePassword = true;
  bool _agreed = false;
  bool _showPhotoError = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _photo = picked;
      _showPhotoError = false;
    });
  }

  void _showPhotoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Choose from gallery', style: AppText.body14),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Take a photo', style: AppText.body14),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    setState(() {
      _showPhotoError = _photo == null;
      _showTermsError = !_agreed;
    });
    if (!formOk || _photo == null || !_agreed) return;

    // TODO: save the new account (next steps).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Create account'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Join CommiLink', style: AppText.heading24),
                      const SizedBox(height: 16),
                      _buildPhotoPicker(),
                      const SizedBox(height: 16),
                      Text('I want to', style: AppText.small12Medium),
                      const SizedBox(height: 8),
                      _RoleToggle(
                        value: _role,
                        onChanged: (role) => setState(() => _role = role),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Full name',
                        controller: _nameController,
                        hint: 'Your full name',
                        textInputAction: TextInputAction.next,
                        validator: Validators.fullName,
                      ),
                      const SizedBox(height: 16),
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
                        hint: 'At least 6 characters',
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
                      _buildTermsRow(),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Create account',
                        icon: Icons.person_add_alt_1_outlined,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          spacing: 4,
                          children: [
                            Text(
                              'Already have an account?',
                              style: AppText.body14.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text(
                                'Sign in',
                                style: AppText.label14.copyWith(
                                  color: AppColors.wine700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showPhotoSheet,
          child: SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.peach100,
                    border: Border.all(color: AppColors.peach400, width: 1.7),
                  ),
                  child: _photo == null
                      ? const Icon(
                    Icons.person_outline_rounded,
                    size: 38,
                    color: AppColors.wine500,
                  )
                      : (kIsWeb
                      ? Image.network(
                    _photo!.path,
                    fit: BoxFit.cover,
                    width: 96,
                    height: 96,
                  )
                      : Image.file(
                    File(_photo!.path),
                    fit: BoxFit.cover,
                    width: 96,
                    height: 96,
                  )),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 33,
                    height: 33,
                    decoration: BoxDecoration(
                      color: AppColors.wine700,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 15,
                      color: AppColors.textOnBrand,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Profile photo', style: AppText.label14),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Required',
                      style: AppText.caption11.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "A clear photo of your face helps people trust who they're working with.",
                style: AppText.small12,
              ),
              GestureDetector(
                onTap: _showPhotoSheet,
                child: Text(
                  _photo == null ? 'Upload photo' : 'Change photo',
                  style: AppText.small12Medium.copyWith(
                    color: AppColors.wine700,
                  ),
                ),
              ),
              if (_showPhotoError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Please add a profile photo',
                    style: AppText.small12.copyWith(color: AppColors.danger),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _agreed = !_agreed;
            if (_agreed) _showTermsError = false;
          }),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _agreed ? AppColors.wine700 : AppColors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: _agreed
                      ? null
                      : Border.all(
                    color: _showTermsError
                        ? AppColors.danger
                        : AppColors.textTertiary,
                    width: 1.5,
                  ),
                ),
                child: _agreed
                    ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.textOnBrand,
                )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'I agree to the Terms and the payment holding policy.',
                  style: AppText.small12,
                ),
              ),
            ],
          ),
        ),
        if (_showTermsError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 32),
            child: Text(
              'You need to agree to continue',
              style: AppText.small12.copyWith(color: AppColors.danger),
            ),
          ),
      ],
    );
  }
}

/// "Hire talent" / "Offer services" switch.
class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleSegment(
              label: 'Hire talent',
              icon: Icons.search_rounded,
              selected: value == UserRole.client,
              onTap: () => onChanged(UserRole.client),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _RoleSegment(
              label: 'Offer services',
              icon: Icons.edit_outlined,
              selected: value == UserRole.freelancer,
              onTap: () => onChanged(UserRole.freelancer),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSegment extends StatelessWidget {
  const _RoleSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textOnBrand : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.wine700 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: AppText.label14.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}