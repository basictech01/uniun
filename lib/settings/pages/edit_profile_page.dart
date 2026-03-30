import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/settings/cubit/edit_profile_cubit.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditProfileCubit(),
      child: const _EditProfileContent(),
    );
  }
}

class _EditProfileContent extends StatefulWidget {
  const _EditProfileContent();

  @override
  State<_EditProfileContent> createState() => _EditProfileContentState();
}

class _EditProfileContentState extends State<_EditProfileContent> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _about;
  late final TextEditingController _avatarUrl;
  late final TextEditingController _nip05;
  bool _controllersInit = false;
  final _picker = ImagePicker();

  Future<void> _pickAvatar(EditProfileCubit cubit) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    // Update the avatarUrl field with the local path so the preview refreshes.
    // The actual Blossom upload happens on save (future scope).
    cubit.updateAvatarUrl(file.path);
    _avatarUrl.text = file.path;
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _about.dispose();
    _avatarUrl.dispose();
    _nip05.dispose();
    super.dispose();
  }

  void _initControllers(EditProfileState state) {
    if (_controllersInit) return;
    _name = TextEditingController(text: state.name);
    _username = TextEditingController(text: state.username);
    _about = TextEditingController(text: state.about);
    _avatarUrl = TextEditingController(text: state.avatarUrl);
    _nip05 = TextEditingController(text: state.nip05);
    _controllersInit = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileCubit, EditProfileState>(
      listener: (context, state) {
        if (state.status == EditProfileStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved')),
          );
          Navigator.pop(context);
        }
        if (state.status == EditProfileStatus.error &&
            state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == EditProfileStatus.loading) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        _initControllers(state);
        final cubit = context.read<EditProfileCubit>();
        final isSaving = state.status == EditProfileStatus.saving;

        return Scaffold(
          backgroundColor: AppColors.surface,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: true,
          appBar: _buildAppBar(context, isSaving, cubit),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: ListView(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 64 + 12,
                left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 48),
            children: [
              // ── Avatar preview ────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => _pickAvatar(cubit),
                  child: Stack(
                    children: [
                      UserAvatar(
                        seed: state.username.isNotEmpty
                            ? state.username
                            : state.name,
                        photoUrl: state.avatarUrl.isNotEmpty
                            ? state.avatarUrl
                            : null,
                        size: 96,
                        showBorder: true,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.surface, width: 2),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Fields ────────────────────────────────────────────────
              _FieldGroup(
                label: 'Display Name',
                controller: _name,
                hint: 'e.g. Satoshi',
                onChanged: cubit.updateName,
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Username',
                controller: _username,
                hint: 'e.g. satoshi',
                prefix: '@',
                onChanged: cubit.updateUsername,
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'About',
                controller: _about,
                hint: 'Tell the world who you are…',
                maxLines: 4,
                onChanged: cubit.updateAbout,
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'Avatar URL',
                controller: _avatarUrl,
                hint: 'https://…',
                onChanged: cubit.updateAvatarUrl,
              ),
              const SizedBox(height: 16),
              _FieldGroup(
                label: 'NIP-05 Identifier',
                controller: _nip05,
                hint: 'you@yourdomain.com',
                onChanged: cubit.updateNip05,
              ),

              const SizedBox(height: 32),

              // ── Save button ───────────────────────────────────────────
              FilledButton(
                onPressed: isSaving ? null : () => cubit.save(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
          ),  // GestureDetector
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isSaving,
    EditProfileCubit cubit,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.surface.withValues(alpha: 0.80),
            child: SafeArea(
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.prefix,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final String? prefix;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            hintStyle: const TextStyle(
              color: AppColors.outline,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
