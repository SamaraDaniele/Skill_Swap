import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/error/failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import '../auth/auth_repository.dart';
import '../safety/terms_screens.dart';
import 'profile.dart';
import 'profile_photo.dart';
import 'skills.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({this.isEditing = false, super.key});

  final bool isEditing;

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final Set<String> _teach;
  late final Set<String> _learn;
  Uint8List? _photo;

  bool _photoRemoved = false;
  bool _isPreparingPhoto = false;
  bool _submitted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(currentProfileProvider).value;
    _name = TextEditingController(text: existing?.name);
    _bio = TextEditingController(text: existing?.bio);
    _teach = {...?existing?.teach};
    _learn = {...?existing?.learn};
    _photo = existing?.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool _consented = false;

  bool get _skillsValid => _teach.isNotEmpty && _learn.isNotEmpty;

  bool get _consentValid => widget.isEditing || _consented;

  Future<void> _pickPhoto() async {
    if (_isPreparingPhoto) return;
    setState(() => _isPreparingPhoto = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (file == null) return;
      final Uint8List source;
      try {
        if (await file.length() > ProfilePhoto.maxSourceBytes) {
          throw const InvalidImageFailure();
        }
        source = await file.readAsBytes();
      } on Failure {
        rethrow;
      } on Exception {
        throw const InvalidImageFailure();
      }
      final photo = await ProfilePhoto.prepare(source);
      if (mounted) {
        setState(() {
          _photo = photo;
          _photoRemoved = false;
        });
      }
    } on Failure catch (failure) {
      if (mounted) {
        showAppSnackBar(context, context.l10n.failureMessage(failure));
      }
    } on PlatformException catch (error) {
      if (mounted) {
        final l10n = context.l10n;
        showAppSnackBar(
          context,
          error.code.contains('denied')
              ? l10n.errorPermission
              : l10n.errorUnknown,
        );
      }
    } finally {
      if (mounted) setState(() => _isPreparingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final uid = ref.read(authStateProvider).value;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (_isSaving ||
        _isPreparingPhoto ||
        uid == null ||
        !formValid ||
        !_skillsValid ||
        !_consentValid) {
      return;
    }

    setState(() => _isSaving = true);
    final profile = UserProfile(
      id: uid,
      name: _name.text.trim(),
      bio: _bio.text.trim(),
      teach: Skills.all.where(_teach.contains).toList(),
      learn: Skills.all.where(_learn.contains).toList(),
      photo: _photo,
    );
    try {
      final repository = ref.read(profileRepositoryProvider);
      widget.isEditing
          ? await repository.save(profile, removePhoto: _photoRemoved)
          : await repository.createWithConsent(profile);
      if (!mounted) return;
      if (widget.isEditing) {
        showAppSnackBar(context, context.l10n.profileSaved);
        context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.failureMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: widget.isEditing
          ? AppBar(title: Text(l10n.editProfileTitle))
          : null,
      body: ContentWidth(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.giant,
              ),
              children: [
                if (!widget.isEditing) ...[
                  Text(
                    l10n.profileSetupTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.profileSetupSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
                ListenableBuilder(
                  listenable: _name,
                  builder: (context, _) => _PhotoPicker(
                    name: _name.text,
                    photo: _photo,
                    isLoading: _isPreparingPhoto,
                    onPick: _pickPhoto,
                    onRemove: () => setState(() {
                      _photo = null;
                      _photoRemoved = true;
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(labelText: l10n.nameLabel),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? l10n.validationRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _bio,
                  maxLength: 160,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.bioLabel,
                    hintText: l10n.bioHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                _SkillPicker(
                  title: l10n.teachSectionTitle,
                  selected: _teach,
                  showError: _submitted && _teach.isEmpty,
                  onToggle: (id) => setState(
                    () => _teach.contains(id)
                        ? _teach.remove(id)
                        : _teach.add(id),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _SkillPicker(
                  title: l10n.learnSectionTitle,
                  selected: _learn,
                  showError: _submitted && _learn.isEmpty,
                  onToggle: (id) => setState(
                    () => _learn.contains(id)
                        ? _learn.remove(id)
                        : _learn.add(id),
                  ),
                ),
                if (!widget.isEditing) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  ConsentCheckbox(
                    value: _consented,
                    showError: _submitted && !_consented,
                    onChanged: (value) => setState(() => _consented = value),
                  ),
                ],
                const SizedBox(height: AppSpacing.huge),
                PrimaryButton(
                  label: l10n.saveAction,
                  isLoading: _isSaving,
                  onPressed: _isPreparingPhoto ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.name,
    required this.photo,
    required this.isLoading,
    required this.onPick,
    required this.onRemove,
  });

  final String name;
  final Uint8List? photo;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasPhoto = photo != null;
    return Row(
      children: [
        SizedBox.square(
          dimension: 88,
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: l10n.photoProcessing,
                  ),
                )
              : ProfileAvatar(name: name, photo: photo, size: 88),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : onPick,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(
                      hasPhoto ? l10n.photoChangeAction : l10n.photoAddAction,
                    ),
                  ),
                  if (hasPhoto)
                    TextButton(
                      onPressed: isLoading ? null : onRemove,
                      child: Text(l10n.photoRemoveAction),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.photoHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillPicker extends StatelessWidget {
  const _SkillPicker({
    required this.title,
    required this.selected,
    required this.showError,
    required this.onToggle,
  });

  final String title;
  final Set<String> selected;
  final bool showError;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final id in Skills.all)
              FilterChip(
                label: Text(Skills.label(l10n, id)),
                selected: selected.contains(id),
                onSelected: (_) => onToggle(id),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: selected.contains(id)
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
          ],
        ),
        if (showError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.validationPickSkill,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
