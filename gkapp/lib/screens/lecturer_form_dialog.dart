import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/lecturer.dart';
import '../widgets/lecturer_avatar.dart';

class LecturerFormDialog extends StatefulWidget {
  const LecturerFormDialog({this.lecturer, super.key});

  final Lecturer? lecturer;

  @override
  State<LecturerFormDialog> createState() => _LecturerFormDialogState();
}

class _LecturerFormDialogState extends State<LecturerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _image;
  String? _imageError;
  String? _pickerError;

  bool get _isEditing => widget.lecturer != null;

  @override
  void initState() {
    super.initState();
    final lecturer = widget.lecturer;
    if (lecturer != null) {
      _nameController.text = lecturer.fullname;
      _classController.text = lecturer.sumClass.toString();
      _image = lecturer.image;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() => _pickerError = 'Ảnh phải có dung lượng tối đa 5 MB.');
        return;
      }

      final mimeType = file.mimeType ?? _mimeTypeFromName(file.name);
      if (!{
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/gif',
      }.contains(mimeType)) {
        setState(
          () => _pickerError = 'Chỉ hỗ trợ ảnh JPG, PNG, WEBP hoặc GIF.',
        );
        return;
      }

      setState(() {
        _image = 'data:$mimeType;base64,${base64Encode(bytes)}';
        _imageError = null;
        _pickerError = null;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _pickerError = 'Không thể chọn ảnh: ${error.message}');
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _pickerError = 'Không thể đọc ảnh: $error');
    }
  }

  String _mimeTypeFromName(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _showImageSources() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _imageError = _image == null || _image!.isEmpty
          ? 'Vui lòng chọn ảnh giảng viên.'
          : null;
    });
    if (!isValid || _imageError != null) return;

    Navigator.of(context).pop(
      LecturerDraft(
        fullname: _nameController.text.trim(),
        image: _image!,
        sumClass: int.parse(_classController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Cập nhật giảng viên' : 'Thêm giảng viên'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showImageSources,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            LecturerAvatar(image: _image ?? '', size: 104),
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary,
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showImageSources,
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Chọn hoặc chụp ảnh'),
                      ),
                      if (_imageError != null)
                        Text(
                          _imageError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      if (_pickerError != null)
                        Text(
                          _pickerError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Mã giảng viên (IDGV)',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  child: Text(
                    _isEditing
                        ? widget.lecturer!.id
                        : 'Tự động tạo khi lưu (GV001, GV002, ...)',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên (Fullname)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập họ và tên.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _classController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Tổng số lớp (SumClass)',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  validator: (value) {
                    final count = int.tryParse(value ?? '');
                    if (count == null) return 'Vui lòng nhập số lớp.';
                    if (count > 100000) return 'Số lớp vượt quá giới hạn.';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_rounded),
          label: Text(_isEditing ? 'Lưu thay đổi' : 'Thêm giảng viên'),
        ),
      ],
    );
  }
}
