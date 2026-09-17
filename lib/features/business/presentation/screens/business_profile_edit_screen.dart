import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/remote_data_notice.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/business_contact_type.dart';
import '../../domain/business_profile_management_gateway.dart';
import '../../domain/business_profile_validator.dart';
import '../../domain/business_remote_read.dart';
import '../../domain/managed_selectable_options.dart';
import '../business_profile_management_messages.dart';
import '../providers/business_profile_editor_provider.dart';
import '../widgets/business_remote_read_notice.dart';

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

  bool get _isArabic =>
      context.read<LanguageProvider?>()?.isArabic ?? true;
  String l(String ar, String en) => _isArabic ? ar : en;

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

    final saveLabel = l(Ar.businessProfileSave, En.businessProfileSave);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(saveLabel),
        content: Text(
          provider.verificationResetWarningVisible
              ? '${l(Ar.businessProfileVerificationWarning, En.businessProfileVerificationWarning)}\n\n$saveLabel'
              : saveLabel,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l(Ar.businessCancel, En.businessCancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(saveLabel),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await provider.save();
    if (mounted && ok) {
      provider.acknowledgeSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l(Ar.businessProfileSaved, En.businessProfileSaved))),
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
        title: Text(l(Ar.businessProfileUnsavedTitle, En.businessProfileUnsavedTitle)),
        content: Text(l(Ar.businessProfileUnsavedMessage, En.businessProfileUnsavedMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l(Ar.businessCancel, En.businessCancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l(Ar.businessProfileDiscard, En.businessProfileDiscard)),
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
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    final connectivityIsUnavailable =
        context.watch<ConnectivityProvider?>()?.isUnavailable ?? false;

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
            BusinessProfileManagementMessages.titleForEditor(isArabic: isArabic),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            if (provider.isPubliclyVisible)
              IconButton(
                icon: const Icon(Icons.open_in_browser_outlined),
                tooltip: l(Ar.businessProfilePreview, En.businessProfilePreview),
                onPressed: () => context.push(
                  AppRoutes.directoryEntityDetailFor(provider.entityId!),
                ),
              ),
          ],
        ),
        body: _Body(
          provider: provider,
          isArabic: isArabic,
          connectivityIsUnavailable: connectivityIsUnavailable,
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
                isArabic: isArabic,
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
    required this.isArabic,
    required this.connectivityIsUnavailable,
    required this.nameController,
    required this.descriptionController,
    required this.addressController,
    required this.latController,
    required this.lonController,
    required this.onSave,
    required this.onReload,
  });

  final BusinessProfileEditorProvider provider;
  final bool isArabic;
  final bool connectivityIsUnavailable;
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController addressController;
  final TextEditingController latController;
  final TextEditingController lonController;
  final VoidCallback onSave;
  final VoidCallback onReload;

  String l(String ar, String en) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileReadFailed = provider.profileReadPhase ==
            BusinessRemoteReadPhase.failed &&
        provider.profileReadFailure != null;
    final auxiliaryReadFailed = provider.auxiliaryReadPhase ==
            BusinessRemoteReadPhase.failed &&
        provider.auxiliaryReadFailure != null;

    switch (provider.state) {
      case BusinessProfileEditorState.initial:
      case BusinessProfileEditorState.loading:
      case BusinessProfileEditorState.saving:
        return const Center(child: CircularProgressIndicator());
      case BusinessProfileEditorState.signInRequired:
        return _MessageState(
          icon: Icons.lock_outline,
          message: l(Ar.businessManageSignInRequired, En.businessManageSignInRequired),
        );
      case BusinessProfileEditorState.unavailable:
        return BusinessRemoteReadNotice(
          failure: BusinessRemoteReadFailureKind.serviceUnavailable,
          connectivityIsUnavailable: connectivityIsUnavailable,
          mode: RemoteDataNoticeMode.noData,
          onRetry: () => provider.load(provider.entityId!),
        );
      case BusinessProfileEditorState.error:
        if (provider.profileReadPhase ==
            BusinessRemoteReadPhase.authoritativeNotFound) {
          // Authoritative absence (contract-proven P0NOT): a neutral controlled
          // unavailable-profile state. Not a failure; no retry/creation/redirect.
          return _MessageState(
            icon: Icons.business_outlined,
            message: l(
              Ar.businessProfileCauseNotFound,
              En.businessProfileCauseNotFound,
            ),
          );
        }
        return BusinessRemoteReadNotice(
          failure:
              provider.profileReadFailure ??
              BusinessRemoteReadFailureKind.unexpected,
          connectivityIsUnavailable: connectivityIsUnavailable,
          mode: RemoteDataNoticeMode.noData,
          onRetry: () => provider.load(provider.entityId!),
        );
      case BusinessProfileEditorState.data:
      case BusinessProfileEditorState.saveSuccess:
        final draft = provider.draft;
        if (draft == null) {
          return _MessageState(
            icon: Icons.error_outline,
            message: l(Ar.businessProfileCauseUnexpected, En.businessProfileCauseUnexpected),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            if (provider.profileReadPhase == BusinessRemoteReadPhase.refreshing)
              const _ThinProgressRow(),
            if (profileReadFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BusinessRemoteReadNotice(
                  failure: provider.profileReadFailure!,
                  connectivityIsUnavailable: connectivityIsUnavailable,
                  mode: RemoteDataNoticeMode.compact,
                  onRetry: () => provider.load(provider.entityId!),
                ),
              ),
            if (auxiliaryReadFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BusinessRemoteReadNotice(
                  failure: provider.auxiliaryReadFailure!,
                  connectivityIsUnavailable: connectivityIsUnavailable,
                  mode: RemoteDataNoticeMode.compact,
                  onRetry: () => provider.load(provider.entityId!),
                ),
              ),
            if (!provider.isPubliclyVisible)
              _NoticeCard(
                icon: Icons.visibility_off_outlined,
                message: l(
                  Ar.businessProfileNotPublicNotice,
                  En.businessProfileNotPublicNotice,
                ),
              ),
            if (provider.verificationResetWarningVisible)
              _NoticeCard(
                icon: Icons.warning_amber_rounded,
                message: l(
                  Ar.businessProfileVerificationWarning,
                  En.businessProfileVerificationWarning,
                ),
                color: AppColors.warning,
              ),
            if (provider.lastErrorCause ==
                BusinessProfileManagementCause.conflict)
              _ConflictBanner(
                isArabic: isArabic,
                onReload: onReload,
              ),
            if (provider.lastErrorCause != null &&
                provider.lastErrorCause !=
                    BusinessProfileManagementCause.conflict &&
                !profileReadFailed)
              _NoticeCard(
                icon: Icons.error_outline,
                message: BusinessProfileManagementMessages.messageForCause(
                  provider.lastErrorCause!,
                  isArabic: isArabic,
                ),
                color: AppColors.error,
              ),
            if (provider.directoryRefreshFailed)
              _RefreshWarningBanner(
                isArabic: isArabic,
                onRetry: () => provider.retryDirectoryRefresh(),
              ),
            _SectionTitle(
              title: l(Ar.businessProfileNameLabel, En.businessProfileNameLabel),
            ),
            TextField(
              key: const Key('businessProfileNameField'),
              controller: nameController,
              decoration: InputDecoration(
                hintText: l(Ar.businessNameHint, En.businessNameHint),
                errorText: _firstIssueMessage(
                  context,
                  provider,
                  BusinessProfileValidationField.name,
                ),
              ),
              maxLength: BusinessProfileBounds.nameMax,
            ),
            _SectionTitle(
              title: l(
                Ar.businessProfileDescriptionLabel,
                En.businessProfileDescriptionLabel,
              ),
            ),
            TextField(
              key: const Key('businessProfileDescriptionField'),
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: l(
                  Ar.businessProfileDescriptionHint,
                  En.businessProfileDescriptionHint,
                ),
                errorText: _firstIssueMessage(
                  context,
                  provider,
                  BusinessProfileValidationField.description,
                ),
              ),
              maxLines: 3,
              maxLength: BusinessProfileBounds.descriptionMax,
            ),
            _SectionTitle(
              title: l(
                Ar.businessProfileContactsLabel,
                En.businessProfileContactsLabel,
              ),
            ),
            _ContactsEditor(provider: provider),
            _SectionTitle(
              title: l(
                Ar.businessProfileCategoriesLabel,
                En.businessProfileCategoriesLabel,
              ),
            ),
            _CategoriesEditor(provider: provider),
            _SectionTitle(
              title: l(
                Ar.businessProfileLocationLabel,
                En.businessProfileLocationLabel,
              ),
            ),
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
    BuildContext context,
    BusinessProfileEditorProvider provider,
    BusinessProfileValidationField field,
  ) {
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    final issues = provider.lastValidation?.forField(field);
    if (issues == null || issues.isEmpty) return null;
    return BusinessProfileManagementMessages.messageForValidationIssue(
      issues.first,
      isArabic: isArabic,
    );
  }
}

class _ThinProgressRow extends StatelessWidget {
  const _ThinProgressRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: LinearProgressIndicator(minHeight: 2),
    );
  }
}

class _ContactsEditor extends StatelessWidget {
  const _ContactsEditor({required this.provider});

  final BusinessProfileEditorProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    String l(String ar, String en) => isArabic ? ar : en;
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
              BusinessProfileManagementMessages.labelForContactType(
                contact.type,
                isArabic: isArabic,
              ),
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
                        ? '★ ${l(Ar.businessProfilePrimary, En.businessProfilePrimary)}'
                        : l(Ar.businessProfilePrimary, En.businessProfilePrimary),
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
          label: Text(l(
            Ar.businessProfileAddContact,
            En.businessProfileAddContact,
          )),
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
              isArabic: isArabic,
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
        final sheetArabic =
            context.read<LanguageProvider?>()?.isArabic ?? true;
        String sheetL(String ar, String en) => sheetArabic ? ar : en;
        final addContactLabel = sheetL(
          Ar.businessProfileAddContact,
          En.businessProfileAddContact,
        );
        final contactsLabel = sheetL(
          Ar.businessProfileContactsLabel,
          En.businessProfileContactsLabel,
        );
        final cancelLabel = sheetL(Ar.businessCancel, En.businessCancel);
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
                    addContactLabel,
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
                                isArabic: sheetArabic,
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
                      hintText: contactsLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(addContactLabel),
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
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    String l(String ar, String en) => isArabic ? ar : en;
    final draft = provider.draft;
    final categories = draft?.categories ?? const [];
    final selectable = provider.selectableCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.isEmpty)
          Text(
            l(Ar.businessProfileNoCategories, En.businessProfileNoCategories),
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
            hint: Text(l(
              Ar.businessProfileAddCategory,
              En.businessProfileAddCategory,
            )),
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
            provider.auxiliaryReadPhase == BusinessRemoteReadPhase.failed
                ? l(
                    Ar.businessProfileNoCategories,
                    En.businessProfileNoCategories,
                  )
                : provider.categoriesCatalogError
                    ? l(
                        Ar.businessProfileCauseNetwork,
                        En.businessProfileCauseNetwork,
                      )
                    : l(
                        Ar.businessProfileNoCategories,
                        En.businessProfileNoCategories,
                      ),
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
              isArabic: isArabic,
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
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    String l(String ar, String en) => isArabic ? ar : en;
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
            labelText: l(Ar.businessProfileAddressLabel, En.businessProfileAddressLabel),
            hintText: l(Ar.businessProfileAddressHint, En.businessProfileAddressHint),
            errorText: _firstIssueMessage(
              context,
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
            hint: Text(l(Ar.businessProfileRegionHint, En.businessProfileRegionHint)),
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
            provider.auxiliaryReadPhase == BusinessRemoteReadPhase.failed
                ? l(
                    Ar.businessProfileNoCategories,
                    En.businessProfileNoCategories,
                  )
                : provider.regionsCatalogError
                    ? l(
                        Ar.businessProfileCauseNetwork,
                        En.businessProfileCauseNetwork,
                      )
                    : l(
                        Ar.businessProfileNoCategories,
                        En.businessProfileNoCategories,
                      ),
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
                  labelText: l(Ar.businessProfileLatitude, En.businessProfileLatitude),
                  errorText: _firstIssueMessage(
                    context,
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
                  labelText: l(Ar.businessProfileLongitude, En.businessProfileLongitude),
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
          label: Text(l(Ar.businessProfileDiscard, En.businessProfileDiscard)),
        ),
      ],
    );
  }

  String? _firstIssueMessage(
    BuildContext context,
    BusinessProfileEditorProvider provider,
    BusinessProfileValidationField field,
  ) {
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    final issues = provider.lastValidation?.forField(field);
    if (issues == null || issues.isEmpty) return null;
    return BusinessProfileManagementMessages.messageForValidationIssue(
      issues.first,
      isArabic: isArabic,
    );
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
  const _ConflictBanner({required this.isArabic, required this.onReload});

  final bool isArabic;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String l(String ar, String en) => isArabic ? ar : en;
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
              l(Ar.businessProfileConflictMessage, En.businessProfileConflictMessage),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          Flexible(
            child: TextButton(
              onPressed: onReload,
              child: Text(
                l(
                  Ar.businessProfileConflictReload,
                  En.businessProfileConflictReload,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshWarningBanner extends StatelessWidget {
  const _RefreshWarningBanner({required this.isArabic, required this.onRetry});

  final bool isArabic;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String l(String ar, String en) => isArabic ? ar : en;
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
              l(
                Ar.businessProfileRefreshWarning,
                En.businessProfileRefreshWarning,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
          Flexible(
            child: TextButton(
              onPressed: onRetry,
              child: Text(
                l(
                  Ar.businessProfileRetryRefresh,
                  En.businessProfileRetryRefresh,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.isArabic,
    required this.enabled,
    required this.busy,
    required this.onSave,
  });

  final bool isArabic;
  final bool enabled;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String l(String ar, String en) => isArabic ? ar : en;

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
                child: Text(
                  busy
                      ? l(Ar.businessProfileSaving, En.businessProfileSaving)
                      : l(Ar.businessProfileSave, En.businessProfileSave),
                ),
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