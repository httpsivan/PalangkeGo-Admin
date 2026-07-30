import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/admin_widgets.dart';
import '../../data/repositories/mock_repository.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  static const _maxAvatarBytes = 2 * 1024 * 1024;
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  Uint8List? _selectedAvatarBytes;
  bool _removeAvatar = false;
  bool _pickingAvatar = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(adminProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    setState(() => _pickingAvatar = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (!mounted || result == null) return;
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read the selected image.')),
        );
        return;
      }
      if (bytes.length > _maxAvatarBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose an image smaller than 2 MB.')),
        );
        return;
      }
      setState(() {
        _selectedAvatarBytes = bytes;
        _removeAvatar = false;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the image picker.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  void _clearAvatar() {
    setState(() {
      _selectedAvatarBytes = null;
      _removeAvatar = true;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    if (password.isNotEmpty && password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(adminProfileProvider.notifier).updateProfile(
          name: name,
          password: password.isEmpty ? null : password,
          avatarBytes: _selectedAvatarBytes,
          removeAvatar: _removeAvatar,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _selectedAvatarBytes = null;
      _removeAvatar = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(adminProfileProvider);
    return Column(
      children: [
        const PageHeader(
          title: 'Change Profile',
          subtitle: 'Update your administrator profile and security settings.',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
            child: Align(
              alignment: Alignment.topLeft,
              child: DataPanel(
                title: 'Profile details',
                subtitle: 'Update the information used in the admin dashboard.',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _profilePictureEditor(context, profile),
                        const SizedBox(height: 22),
                        TextField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: profile.email,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Change password',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'New password',
                            hintText: 'Leave blank to keep current password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          onSubmitted: (_) => _save(),
                          decoration: const InputDecoration(
                            labelText: 'Confirm new password',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: semanticColors(context).danger,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Save changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profilePictureEditor(
    BuildContext context,
    AdminProfile profile,
  ) {
    final colors = semanticColors(context);
    final avatarBytes =
        _removeAvatar ? null : _selectedAvatarBytes ?? profile.avatarBytes;
    final preview = Stack(
      clipBehavior: Clip.none,
      children: [
        AvatarCircle(
          name: _nameController.text.isEmpty
              ? profile.name
              : _nameController.text,
          size: 88,
          imageBytes: avatarBytes,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Tooltip(
            message: 'Change profile picture',
            child: Material(
              color: colors.heroBackground,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _pickingAvatar ? null : _pickAvatar,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: _pickingAvatar
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.heroForeground,
                          ),
                        )
                      : Icon(
                          Icons.photo_camera_outlined,
                          size: 17,
                          color: colors.heroForeground,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile picture',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _pickingAvatar ? null : _pickAvatar,
              icon: const Icon(Icons.upload_outlined, size: 17),
              label: Text(avatarBytes == null ? 'Add photo' : 'Change photo'),
            ),
            if (avatarBytes != null)
              TextButton.icon(
                onPressed: _clearAvatar,
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Remove'),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Image files up to 2 MB.',
          style: TextStyle(color: colors.mutedText, fontSize: 11),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [preview, const SizedBox(height: 16), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            preview,
            const SizedBox(width: 20),
            Expanded(child: actions),
          ],
        );
      },
    );
  }
}
