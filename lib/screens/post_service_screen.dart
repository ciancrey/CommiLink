import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/cta_button.dart';

/// PAGE · 25 · Post a service (freelancers) (Figma node 11:1520)
/// Saves a row in `services` and uploads portfolio images to the public
/// "portfolio" storage bucket.
class PostServiceScreen extends StatefulWidget {
  const PostServiceScreen({super.key});

  @override
  State<PostServiceScreen> createState() => _PostServiceScreenState();
}

class _PostServiceScreenState extends State<PostServiceScreen> {
  static const List<String> _categories = [
    'Design',
    'Programming',
    'Video',
    'Writing',
  ];
  static const int _maxImages = 5;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _daysController = TextEditingController();
  final _picker = ImagePicker();

  String _category = 'Programming';
  final List<XFile> _images = [];
  final List<Uint8List> _previews = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickImages() async {
    final left = _maxImages - _images.length;
    if (left <= 0) {
      _toast('You can add up to $_maxImages images.');
      return;
    }
    final picked = await _picker.pickMultiImage(maxWidth: 1600, imageQuality: 85);
    if (picked.isEmpty) return;
    final take = picked.take(left).toList();
    final bytes = await Future.wait(take.map((x) => x.readAsBytes()));
    setState(() {
      _images.addAll(take);
      _previews.addAll(bytes);
    });
    if (picked.length > left) _toast('Only the first $left images were added.');
  }

  void _removeImage(int i) => setState(() {
        _images.removeAt(i);
        _previews.removeAt(i);
      });

  int? _int(String v) =>
      int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));

  String? _validateTitle(String? v) {
    final text = (v ?? '').trim();
    if (text.length < 5) return 'Title must be at least 5 characters';
    if (text.length > 120) return 'Title is too long';
    return null;
  }

  String? _validatePrice(String? v) {
    final n = _int(v ?? '');
    if (n == null || n < 50 || n > 50000) return '₱50 – ₱50,000';
    return null;
  }

  String? _validateDays(String? v) {
    final n = _int(v ?? '');
    if (n == null || n < 1 || n > 60) return '1 – 60 days';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await AppState.instance.createService(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        price: _int(_priceController.text)!,
        deliveryDays: _int(_daysController.text)!,
        images: _images,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Service posted. Clients can see it now.')),
      );
    } on AppException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppText.body14.copyWith(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.wine700, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppText.small12Medium),
      );

  Widget _helper(String text) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 2),
        child: Text(text, style: AppText.caption11),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: 'Post a service'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPortfolio(),
                      const SizedBox(height: 18),
                      _label('Service title'),
                      TextFormField(
                        controller: _titleController,
                        style: AppText.body14,
                        textInputAction: TextInputAction.next,
                        validator: _validateTitle,
                        decoration:
                            _decoration('e.g. One-page responsive website'),
                      ),
                      const SizedBox(height: 16),
                      _label('Category'),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        style: AppText.body14
                            .copyWith(color: AppColors.textPrimary),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textTertiary),
                        decoration: _decoration(''),
                        borderRadius: BorderRadius.circular(16),
                        dropdownColor: AppColors.surface,
                        items: [
                          for (final c in _categories)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) =>
                            setState(() => _category = v ?? _category),
                      ),
                      const SizedBox(height: 16),
                      _label('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        style: AppText.body14,
                        decoration: _decoration(
                          'What the client gets, revisions, files…',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Price (PHP)'),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  style: AppText.body14,
                                  validator: _validatePrice,
                                  decoration: _decoration('₱3,000'),
                                ),
                                _helper('₱50 – ₱50,000'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Delivery (days)'),
                                TextFormField(
                                  controller: _daysController,
                                  keyboardType: TextInputType.number,
                                  style: AppText.body14,
                                  validator: _validateDays,
                                  decoration: _decoration('6'),
                                ),
                                _helper('1 – 60 days'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: CtaButton(
                label: _saving ? 'Posting…' : 'Post service',
                icon: Icons.check_rounded,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolio() {
    final box = GestureDetector(
      onTap: _pickImages,
      child: CustomPaint(
        painter: _DashedBorder(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(
            color: AppColors.peach100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.upload_rounded,
                  size: 26, color: AppColors.wine700),
              const SizedBox(height: 8),
              Text(
                'Add portfolio images',
                style: AppText.label14.copyWith(color: AppColors.wine700),
              ),
              const SizedBox(height: 4),
              Text(
                _images.isEmpty
                    ? 'PNG or JPG · up to $_maxImages images'
                    : '${_images.length} of $_maxImages added · tap to add more',
                style: AppText.caption11,
              ),
            ],
          ),
        ),
      ),
    );

    if (_previews.isEmpty) return box;

    return Column(
      children: [
        box,
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _previews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(_previews[i],
                      width: 72, height: 72, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => _removeImage(i),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xAA000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashed peach outline for the upload box.
class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.peach400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 8), paint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
