import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../localization/ar.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/business_contact_type.dart';
import '../../domain/business_profile_management_gateway.dart';
import '../../domain/business_profile_validator.dart';
import '../../domain/managed_selectable_options.dart';
import '../business_profile_management_messages.dart';
import '../providers/business_profile_editor_provider.dart';

/// V1-R06 — OWNER/ADMIN public business-profile editor.
///
/// Key behaviors:
/// * PopScope unsaved-changes guard;
/// * verification-reset warning when verified + sensitive fields change;
/// * not-public notice for non-active lifecycle;
/// * conflict reload (P0CON);
/// * post-save Directory cache refresh;
/// * public preview deep-link.
class BusinessProfileEditScreen extends StatefulWidget {
  const BusinessProfileEditScreen({
    super.key,
    required this.entityId,
  });

  final String entityId;

  @override
  State<BusinessProfileEditScreen> createState() =>
      _BusinessProfileEditScreenState();
}

class _BusinessProfileEditScreenState extends State<BusinessProfileEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lonController;

  BusinessProfileEditorProvider? _provider;
  bool _syncing = false;

  // Snapshot of controller text at the last authoritative sync. Used to
  // compute dirty state without re-parsing partial coordinates on every
  // keystroke and without rewriting active controllers.
  DateTime? _lastSyncedUpdatedAt;
  String _syncedName = '';
  String _syncedDescription = '';
  String _syncedAddress = '';
  String _syncedLat = '';
  String _syncedLon = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _latController = TextEditingController();
    _lonController = TextEditingController();

    _nameController.addListener(_onNameChanged);
    _descriptionController.addListener(_onDescriptionChanged);
    _addressController.addListener(_onAddressChanged);
    // Coordinates are committed only on editing-complete / save so that raw
    // partial strings such as "-" or "-33." are not overwritten while typing.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<BusinessProfileEditorProvider>();
      _provider = provider;
      provider.addListener(_onProviderChanged);
      provider.load(widget.entityId);
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);

    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  /// Syncs controllers ONLY when the authoritative projection changes (initial
  /// load, conflict reload, successful save/reload). Never rewrites active
  /// controllers after routine user edits.
  void _onProviderChanged() {
    final provider = context.read<BusinessProfileEditorProvider>();
    final profile = provider.profile;
    final draft = provider.draft;
    if (profile == null || draft == null) return;
    if (_lastSyncedUpdatedAt != null &&
        _lastSyncedUpdatedAt!.isAtSameMomentAs(profile.updatedAt)) {
      return;
    }

    _syncing = true;
    _lastSyncedUpdatedAt = profile.updatedAt;
    _nameController.text = draft.name;
    _descriptionController.text = draft.description ?? '';
    final location = draft.primaryLocation;
    _addressController.text = location?.address ?? '';
    _latController.text = location?.latitude?.toString() ?? '';
    _lonController.text = location?.longitude?.toString() ?? '';

    _syncedName = _nameController.text;
    _syncedDescription = _descriptionController.text;
    _syncedAddress = _addressController.text;
    _syncedLat = _latController.text;
    _syncedLon = _lonController.text;
    _syncing = false;
  }

  bool get _controllersDirty {
    return _nameController.text != _syncedName ||
        _descriptionController.text != _syncedDescription ||
        _addressController.text != _syncedAddress ||
        _latController.text != _syncedLat ||
        _lonController.text != _syncedLon;
  }

  void _onNameChanged() {
    if (_syncing) return;
    context.read<BusinessProfileEditorProvider>().setName(_nameController.text);
  }

  void _onDescriptionChanged() {
    if (_syncing) return;
    final value = _descriptionController.text;
    context.read<BusinessProfileEditorProvider>().setDescription(
          value.isEmpty ? null : value,
        );
  }

  void _onAddressChanged() {
    if (_syncing) return;
    final value = _addressController.text;
    context.read<BusinessProfileEditorProvider>().setAddress(
          value.isEmpty ? null : value,
        );
  }

  void _commitCoordinates() {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    context.read<BusinessProfileEditorProvider>().setCoordinates(
          _latController.text.isEmpty ? null : lat,
          _lonController.text.isEmpty ? null : lon,
        );
  }

  Future<void> _save() async {
    final provider = context.read<BusinessProfileEditorProvider>();
    // Push any uncommitted controller state (coordinates) before validating.
    provider.setName(_nameController.text);
    provider.setDescription(
      _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );
    provider.setAddress(
      _addressController.text.isEmpty ? null : _addressController.text,
    );
    _commitCoordinates();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Ar.businessProfileSave),
        content: Text(
          provider.verificationResetWarningVisible
              ? '${Ar.businessProfileVerificationWarning}\n\n${Ar.businessProfileSave}'
              : Ar.businessProfileSave,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Ar.businessCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Ar.businessProfileSave),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await provider.save();
    if (mounted && ok) {
      provider.acknowledgeSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Ar.businessProfileSaved)),
      );
    }
  }

  Future<void> _reloadAfterConflict() async {
    final provider = context.read<BusinessProfileEditorProvider>();
    await provider.reloadAuthoritative();
  }

  void _resetControllersToSynced() {
    _syncing = true;
    _nameController.text = _syncedName;
    _descriptionController.text = _syncedDescription;
    _addressController.text = _syncedAddress;
    _latController.text = _syncedLat;
    _lonController.text = _syncedLon;
    _syncing = false;
  }

  Future<bool> _onWillPop() async {
    final provider = context.read<BusinessProfileEditorProvider>();
    if (provider.canPopSafely && !_controllersDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Ar.businessProfileUnsavedTitle),
        content: Text(Ar.businessProfileUnsavedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Ar.businessCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Ar.businessProfileDiscard),
          ),
        ],
      ),
    );
          if (discard == true) {
            provider.discardChanges();
            _resetControllersToSynced();
            return true;
          }
          return false;
        }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<BusinessProfileEditorProvider>();

    final isDirty = provider.isDirty || _controllersDirty;

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && isDirty) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            BusinessProfileManagementMessages.titleForEditor(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            if (provider.isPubliclyVisible)
              IconButton(
                icon: const Icon(Icons.open_in_browser_outlined),
                tooltip: Ar.businessProfilePreview,
                onPressed: () => context.push(
                  AppRoutes.directoryEntityDetailFor(provider.entityId!),
                ),
              ),
          ],
        ),
        body: _Body(
          provider: provider,
          nameController: _nameController,
          descriptionController: _descriptionController,
          addressController: _addressController,
          latController: _latController,
          lonController: _lonController,
          onSave: _save,
          onReload: _reloadAfterConflict,
        ),
        bottomNavigationBar: provider.state == BusinessProfileEditorState.data
            ? _SaveBar(
                enabled: isDirty && !(provider.lastValidation?.isValid == false),
                busy: provider.isSaving,
                onSave: _save,
              )
            : null,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.nameController,
    required this.descriptionController,
    required this.addressController,
    required this.latController,
    required this.lonController,
    required this.onSave,
    required this.onReload,
  });

  final BusinessProfileEditorProvider provider;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController addressController;
  final TextEditingController latController;
  final TextEditingController lonController;
  final VoidCallback onSave;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (provider.state) {
      case BusinessProfileEditorState.initial:
      case BusinessProfileEditorState.loading:
      case BusinessProfileEditorState.saving:
        return const Center(child: CircularProgressIndicator());
      case BusinessProfileEditorState.signInRequired:
        return _MessageState(
          icon: Icons.lock_outline,
          message: Ar.businessManageSignInRequired,
        );
      case BusinessProfileEditorState.unavailable:
        return _MessageState(
          icon: Icons.cloud_off_outlined,
          message: Ar.businessProfileCauseUnavailable,
        );
      case BusinessProfileEditorState.error:
        return _MessageState(
          icon: Icons.error_outline,
          message: BusinessProfileManagementMessages.messageForCause(
            provider.lastErrorCause ?? BusinessProfileManagementCause.unexpected,
          ),
          actionLabel: Ar.businessRefresh,
          onAction: () => provider.load(provider.entityId!),
        );
      case BusinessProfileEditorState.data:
      case BusinessProfileEditorState.saveSuccess:
        final draft = provider.draft;
        if (draft == null) {
          return _MessageState(
            icon: Icons.error_outline,
            message: Ar.businessProfileCauseUnexpected,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            if (!provider.isPubliclyVisible)
              _NoticeCard(
                icon: Icons.visibility_off_outlined,
                message: Ar.businessProfileNotPublicNotice,
              ),
            if (provider.verificationResetWarningVisible)
              _NoticeCard(
                icon: Icons.warning_amber_rounded,
                message: Ar.businessProfileVerificationWarning,
                color: AppColors.warning,
              ),
            if (provider.lastErrorCause ==
                BusinessProfileManagementCause.conflict)
              _ConflictBanner(
                onReload: onReload,
              ),
            if (provider.lastErrorCause != null &&
                provider.lastErrorCause !=
                    BusinessProfileManagementCause.conflict)
              _NoticeCard(
                icon: Icons.error_outline,
                message: BusinessProfileManagementMessages.messageForCause(
                  provider.lastErrorCause!,
                ),
                color: AppColors.error,
              ),
            if (provider.directoryRefreshFailed)
              _RefreshWarningBanner(
                onRetry: () => provider.retryDirectoryRefresh(),
              ),
            _SectionTitle(title: Ar.businessProfileNameLabel),
            TextField(
              key: const Key('businessProfileNameField'),
              controller: nameController,
              decoration: InputDecoration(
                hintText: Ar.businessNameHint,
                errorText: _firstIssueMessage(
                  provider,
                  BusinessProfileValidationField.name,
                ),
              ),
              maxLength: BusinessProfileBounds.nameMax,
            ),
            _SectionTitle(title: Ar.businessProfileDescriptionLabel),
            TextField(
              key: const Key('businessProfileDescriptionField'),
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: Ar.businessProfileDescriptionHint,
                errorText: _firstIssueMessage(
                  provider,
                  BusinessProfileValidationField.description,
                ),
              ),
              maxLines: 3,
              maxLength: BusinessProfileBounds.descriptionMax,
            ),
            _SectionTitle(title: Ar.businessProfileContactsLabel),
            _ContactsEditor(provider: provider),
            _SectionTitle(title: Ar.businessProfileCategoriesLabel),
            _CategoriesEditor(provider: provider),
            _SectionTitle(title: Ar.businessProfileLocationLabel),
            _LocationEditor(
              provider: provider,
              addressController: addressController,
              latController: latController,
              lonController: lonController,
              onCommitCoordinates: () {
                final lat = latController.text.isEmpty
                    ? null
                    : double.tryParse(latController.text);
                final lon = lonController.text.isEmpty
                    ? null
                    : double.tryParse(lonController.text);
                provider.setCoordinates(lat, lon);
              },
            ),
          ],
        );
    }
  }

  String? _firstIssueMessage(
    BusinessProfileEditorProvider provider,
    BusinessProfileValidationField field,
  ) {
    final issue = provider.lastValidation?.forField(field).firstOrNull;
    if (issue == null) return null;
    return BusinessProfileManagementMessages.messageForValidationIssue(issue);
  }
}

class _ContactsEditor extends StatelessWidget {
  const _ContactsEditor({required this.provider});

  final BusinessProfileEditorProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contacts = provider.draft?.contacts ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...contacts.asMap().entries.map((entry) {
          final index = entry.key;
          final contact = entry.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _iconFor(contact.type),
              color: theme.primaryColor,
            ),
            title: Text(contact.value),
            subtitle: Text(
              BusinessProfileManagementMessages.labelForContactType(contact.type),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => provider.setContactPrimary(
                    index,
                    !contact.isPrimary,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: contact.isPrimary
                        ? theme.primaryColor
                        : AppColors.textSecondary,
                  ),
                  child: Text(
                    contact.isPrimary
                        ? '★ ${Ar.businessProfilePrimary}'
                        : Ar.businessProfilePrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => provider.removeContact(index),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => _showAddContactSheet(context, provider),
          icon: const Icon(Icons.add),
          label: Text(Ar.businessProfileAddContact),
        ),
        if (provider.lastValidation
                ?.forField(BusinessProfileValidationField.contacts)
                .isNotEmpty ??
            false)
          Text(
            BusinessProfileManagementMessages.messageForValidationIssue(
              provider.lastValidation!
                  .forField(BusinessProfileValidationField.contacts)
                  .first,
            ),
            style: TextStyle(color: AppColors.error),
          ),
      ],
    );
  }

  IconData _iconFor(BusinessContactType type) {
    switch (type) {
      case BusinessContactType.phone:
        return Icons.phone_outlined;
      case BusinessContactType.whatsapp:
        return Icons.chat_outlined;
      case BusinessContactType.email:
        return Icons.email_outlined;
      case BusinessContactType.website:
        return Icons.language_outlined;
      case BusinessContactType.other:
        return Icons.notes_outlined;
      case BusinessContactType.unknown:
        return Icons.help_outline;
    }
  }

  Future<void> _showAddContactSheet(
    BuildContext context,
    BusinessProfileEditorProvider provider,
  ) async {
    BusinessContactType selectedType = BusinessContactType.phone;
    final valueController = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Ar.businessProfileAddContact,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BusinessContactType>(
                    value: selectedType,
                    items: [
                      for (final type in BusinessContactType.values)
                        if (type != BusinessContactType.unknown)
                          DropdownMenuItem(
                            value: type,
                            child: Text(
                              BusinessProfileManagementMessages.labelForContactType(
                                type,
                              ),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      hintText: Ar.businessProfileContactsLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(Ar.businessCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(Ar.businessProfileAddContact),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (ok == true && valueController.text.trim().isNotEmpty) {
      provider.addContact(
        type: selectedType,
        value: valueController.text.trim(),
      );
    }
    valueController.dispose();
  }
}

class _CategoriesEditor extends StatelessWidget {
  const _CategoriesEditor({required this.provider});

  final BusinessProfileEditorProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = provider.draft;
    final categories = draft?.categories ?? const [];
    final selectable = provider.selectableCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.isEmpty)
          Text(
            Ar.businessProfileNoCategories,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                InputChip(
                  label: Text(category.nameAr ?? category.code),
                  selected: category.isPrimary,
                  onSelected: (_) => provider.setCategoryPrimary(
                    category.categoryId,
                    !category.isPrimary,
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => provider.removeCategory(category.categoryId),
                ),
            ],
          ),
        const SizedBox(height: 8),
        if (selectable.isNotEmpty)
          DropdownButtonFormField<String?>(
            value: null,
            hint: Text(Ar.businessProfileAddCategory),
            items: [
              for (final option in selectable)
                if (!categories.any((c) => c.categoryId == option.id))
                  DropdownMenuItem(
                    value: option.id,
                    child: Text(option.displayName),
                  ),
            ],
            onChanged: (id) {
              if (id == null) return;
              final option = selectable.firstWhere((o) => o.id == id);
              provider.addCategory(option);
            },
          )
        else
          Text(
            provider.categoriesCatalogError
                ? Ar.businessProfileCauseNetwork
                : Ar.businessProfileNoCategories,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        if (provider.lastValidation
                ?.forField(BusinessProfileValidationField.categories)
                .isNotEmpty ??
            false)
          Text(
            BusinessProfileManagementMessages.messageForValidationIssue(
              provider.lastValidation!
                  .forField(BusinessProfileValidationField.categories)
                  .first,
            ),
            style: TextStyle(color: AppColors.error),
          ),
      ],
    );
  }
}

class _LocationEditor extends StatelessWidget {
  const _LocationEditor({
    required this.provider,
    required this.addressController,
    required this.latController,
    required this.lonController,
    required this.onCommitCoordinates,
  });

  final BusinessProfileEditorProvider provider;
  final TextEditingController addressController;
  final TextEditingController latController;
  final TextEditingController lonController;
  final VoidCallback onCommitCoordinates;

  @override
  Widget build(BuildContext context) {
    final draft = provider.draft;
    final regions = provider.selectableRegions;
    final selectedRegionId = draft?.primaryLocation?.regionId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('businessProfileAddressField'),
          controller: addressController,
          decoration: InputDecoration(
            labelText: Ar.businessProfileAddressLabel,
            hintText: Ar.businessProfileAddressHint,
            errorText: _firstIssueMessage(
              provider,
              BusinessProfileValidationField.address,
            ),
          ),
          maxLines: 2,
          onEditingComplete: () {
            final value = addressController.text;
            provider.setAddress(value.isEmpty ? null : value);
          },
        ),
        const SizedBox(height: 12),
        if (regions.isNotEmpty)
          DropdownButtonFormField<String?>(
            value: selectedRegionId,
            hint: Text(Ar.businessProfileRegionHint),
            items: [
              const DropdownMenuItem(value: null, child: Text('-')),
              for (final region in regions)
                DropdownMenuItem(
                  value: region.id,
                  child: Text(region.displayName),
                ),
            ],
            onChanged: (id) => provider.setRegion(id),
          )
        else
          Text(
            provider.regionsCatalogError
                ? Ar.businessProfileCauseNetwork
                : Ar.businessProfileNoCategories,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('businessProfileLatitudeField'),
                controller: latController,
                decoration: InputDecoration(
                  labelText: Ar.businessProfileLatitude,
                  errorText: _firstIssueMessage(
                    provider,
                    BusinessProfileValidationField.coordinates,
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onEditingComplete: onCommitCoordinates,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('businessProfileLongitudeField'),
                controller: lonController,
                decoration: InputDecoration(
                  labelText: Ar.businessProfileLongitude,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onEditingComplete: onCommitCoordinates,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            addressController.clear();
            latController.clear();
            lonController.clear();
            provider.setPrimaryLocation(null);
          },
          icon: const Icon(Icons.clear),
          label: Text(Ar.businessProfileDiscard),
        ),
      ],
    );
  }

  String? _firstIssueMessage(
    BusinessProfileEditorProvider provider,
    BusinessProfileValidationField field,
  ) {
    final issue = provider.lastValidation?.forField(field).firstOrNull;
    if (issue == null) return null;
    return BusinessProfileManagementMessages.messageForValidationIssue(issue);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.message,
    this.color,
  });

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: effectiveColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.onReload});

  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_outlined, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              Ar.businessProfileConflictMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          Flexible(
            child: TextButton(
              onPressed: onReload,
              child: Text(Ar.businessProfileConflictReload),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshWarningBanner extends StatelessWidget {
  const _RefreshWarningBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              Ar.businessProfileRefreshWarning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          Flexible(
            child: TextButton(
              onPressed: onRetry,
              child: Text(Ar.businessProfileRetryRefresh),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.enabled,
    required this.busy,
    required this.onSave,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: enabled && !busy ? onSave : null,
                child: Text(busy ? Ar.businessProfileSaving : Ar.businessProfileSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
