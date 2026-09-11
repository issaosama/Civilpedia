import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../saved/domain/saved_item_reference.dart';
import '../../saved/domain/saved_reference_store.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/cloud_directory_repository.dart';
import 'canonical_entity_type_presentation.dart';
import 'directory_verification_badge.dart';
import 'services/directory_contact_launcher.dart';

/// V1-R05 — Canonical reusable Directory provider detail surface.
///
/// Displays canonical public data for [CanonicalDirectoryEntity]:
/// name, canonical type label, verification state, claim state, description,
/// categories, location/address, public contacts (phone/WhatsApp/email/website).
/// Do NOT expose owner IDs, membership, applicant metadata, or internal audit
/// data. Media is optional and handled only when safely available.
///
/// V1-R05 routing: detail is reached by canonical `directory_entities.id`.
/// The Save/Unsave bookmark always uses the canonical entity UUID. Legacy local
/// provider ids are never canonical Directory references.
class DirectoryProviderDetailScreen extends StatefulWidget {
  final CanonicalDirectoryEntity entity;

  /// Injected contact launcher. Production default uses [url_launcher]; tests
  /// inject a fake so widget tests never open a real external app.
  final DirectoryContactLauncher? contactLauncher;

  /// Canonical User-owned Saved store. Production default is
  /// [AppDependencies.savedReferenceStore]; tests inject a fake in-memory store.
  final SavedReferenceStore? savedReferenceStore;

  const DirectoryProviderDetailScreen({
    super.key,
    required this.entity,
    this.contactLauncher,
    this.savedReferenceStore,
  });

  @override
  State<DirectoryProviderDetailScreen> createState() =>
      _DirectoryProviderDetailScreenState();
}

class _DirectoryProviderDetailScreenState
    extends State<DirectoryProviderDetailScreen> {
  late final DirectoryContactLauncher _launcher;
  late final SavedReferenceStore? _savedStoreOverride;

  bool? _isSaved;

  /// Canonical Directory/provider ref id from `directory_entities.id`.
  late final String _providerRefId;

  SavedReferenceStore get _store =>
      _savedStoreOverride ?? AppDependencies.savedReferenceStore;

  @override
  void initState() {
    super.initState();
    _launcher =
        widget.contactLauncher ?? const UrlLauncherDirectoryContactLauncher();
    _savedStoreOverride = widget.savedReferenceStore;
    _providerRefId = SavedItemReference(
      ownerDomain: SavedReferenceOwners.directory,
      entityType: SavedReferenceEntityTypes.provider,
      entityId: widget.entity.id,
    ).id;
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    bool saved;
    try {
      saved = await _store.contains(_providerRefId);
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() => _isSaved = saved);
  }

  Future<void> _toggleSaved() async {
    final isSaved = _isSaved;
    if (isSaved == null) return;
    try {
      if (isSaved) {
        await _store.remove(_providerRefId);
      } else {
        await _store.save(
          SavedItemReference(
            ownerDomain: SavedReferenceOwners.directory,
            entityType: SavedReferenceEntityTypes.provider,
            entityId: widget.entity.id,
            savedAt: DateTime.now().toUtc(),
          ),
        );
      }
      if (!mounted) return;
      setState(() => _isSaved = !isSaved);
    } catch (_) {
      if (!mounted) return;
      final isArabic = context.read<LanguageProvider>().isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? Ar.errorOccurred : En.errorOccurred,
          ),
        ),
      );
    }
  }

  Future<void> _launchPhone(String trimmedPhone) async {
    final ok = await _launcher.launchPhone(trimmedPhone);
    if (!ok) _showLaunchFailure();
  }

  Future<void> _launchWhatsApp(String digits) async {
    final ok = await _launcher.launchWhatsApp(digits);
    if (!ok) _showLaunchFailure();
  }

  void _showLaunchFailure() {
    if (!mounted) return;
    final isArabic = context.read<LanguageProvider>().isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? Ar.directoryUnableToOpenApp : En.directoryUnableToOpenApp,
        ),
      ),
    );
  }

  Widget _buildSaveAction(bool isArabic) {
    final isSaved = _isSaved;
    if (isSaved == null) return const SizedBox.shrink();
    final unsaved = isSaved == false;
    final tooltip = unsaved
        ? (isArabic ? Ar.savedSaveProvider : En.savedSaveProvider)
        : (isArabic ? Ar.savedRemoveFromSaved : En.savedRemoveFromSaved);
    return IconButton(
      icon: Icon(unsaved ? Icons.bookmark_border : Icons.bookmark),
      tooltip: tooltip,
      onPressed: _toggleSaved,
    );
  }

  /// Maps canonical `entity_contacts.contact_type` values to phones and
  /// WhatsApp digits. Unknown/malformed types fail safe (never crash).
  (List<String>, String) _contactProjection(CanonicalDirectoryEntity entity) {
    final phones = <String>[];
    var whatsapp = '';
    for (final contact in entity.contacts) {
      final value = contact.value.trim();
      if (value.isEmpty) continue;
      switch (contact.contactType.toLowerCase()) {
        case 'phone':
        case 'telephone':
        case 'mobile':
        case 'phone_number':
          phones.add(value);
        case 'whatsapp':
          whatsapp = value;
      }
    }
    return (phones, _whatsappDigits(whatsapp));
  }

  @override
  Widget build(BuildContext context) {
    final entity = widget.entity;
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final theme = Theme.of(context);
    final description = entity.description?.trim();
    final address = _primaryAddress(entity);
    final services = _nonEmptyList(
      entity.categories.map((c) => c.name).toList(),
    );
    final (phones, whatsappDigits) = _contactProjection(entity);
    final hasActionableContact = phones.isNotEmpty || whatsappDigits.isNotEmpty;

    return Scaffold(
      appBar: CivilAppBar(
        title: Text(entity.name),
        actions: [_buildSaveAction(isArabic)],
      ),
      body: ListView(
        padding: AppSpacing.padLg,
        children: [
          _buildIdentity(entity, isArabic, theme),
          if (description != null && description.isNotEmpty) ...[
            AppSpacing.gapLg,
            _sectionLabel(isArabic ? Ar.directoryDescription : En.directoryDescription),
            AppSpacing.gapSm,
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
          if (address != null && address.isNotEmpty) ...[
            AppSpacing.gapLg,
            _sectionLabel(isArabic ? Ar.directoryAddress : En.directoryAddress),
            AppSpacing.gapSm,
            Text(
              address,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (services.isNotEmpty) ...[
            AppSpacing.gapLg,
            _sectionLabel(isArabic ? Ar.directoryServices : En.directoryServices),
            AppSpacing.gapSm,
            _ServicesWrap(values: services),
          ],
          AppSpacing.gapLg,
          _sectionLabel(isArabic ? Ar.directoryContact : En.directoryContact),
          AppSpacing.gapSm,
          if (hasActionableContact)
            _buildContactActions(entity, phones, whatsappDigits, isArabic, theme)
          else
            _buildNoContact(theme),
        ],
      ),
    );
  }

  Widget _buildIdentity(
    CanonicalDirectoryEntity entity,
    bool isArabic,
    ThemeData theme,
  ) {
    final typeLabel = CanonicalEntityTypePresentation.labelFor(
      entity.entityType,
      isArabic: isArabic,
    );
    final locationLabel = _locationLabel(entity, isArabic);

    return CivilSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
                ),
                child: Icon(
                  CanonicalEntityTypePresentation.iconFor(entity.entityType),
                  color: AppColors.primaryDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entity.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      typeLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (locationLabel != null) ...[
                      Text(
                        locationLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    DirectoryVerificationBadge(
                      status: entity.verificationStatus,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildContactActions(
    CanonicalDirectoryEntity entity,
    List<String> phones,
    String whatsappDigits,
    bool isArabic,
    ThemeData theme,
  ) {
    final callLabel = isArabic ? Ar.directoryCall : En.directoryCall;
    final whatsAppLabel = isArabic ? Ar.directoryWhatsApp : En.directoryWhatsApp;

    return CivilSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final phone in phones) ...[
            _ContactButton(
              icon: Icons.phone,
              label: '$callLabel — $phone',
              color: AppColors.primaryDark,
              onPressed: () => _launchPhone(phone),
            ),
            if (phone != phones.last) AppSpacing.gapSm,
          ],
          if (whatsappDigits.isNotEmpty) ...[
            if (phones.isNotEmpty) AppSpacing.gapSm,
            _ContactButton(
              icon: Icons.chat,
              label: '$whatsAppLabel — $whatsappDigits',
              color: const Color(0xFF25D366),
              onPressed: () => _launchWhatsApp(whatsappDigits),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoContact(ThemeData theme) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    return CivilSurfaceCard(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isArabic
                  ? Ar.directoryNoContactInformation
                  : En.directoryNoContactInformation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesWrap extends StatelessWidget {
  final List<String> values;

  const _ServicesWrap({required this.values});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final value in values)
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
        ),
      ),
    );
  }
}

/// Resolves the primary region for presentation.
String? _locationLabel(CanonicalDirectoryEntity entity, bool isArabic) {
  if (entity.locations.isEmpty) return null;
  final first = entity.locations.first;
  final regionName = first.regionName;
  if (regionName != null && regionName.isNotEmpty) return regionName;
  return first.regionCode.isNotEmpty
      ? (isArabic ? Ar.directoryNotSpecified : En.directoryNotSpecified)
      : null;
}

String? _primaryAddress(CanonicalDirectoryEntity entity) {
  for (final loc in entity.locations) {
    final address = loc.address?.trim();
    if (address != null && address.isNotEmpty) return address;
  }
  return null;
}

List<String> _nonEmptyList(List<String> values) {
  final result = <String>[];
  for (final raw in values) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) result.add(trimmed);
  }
  return result;
}

String _whatsappDigits(String? whatsapp) {
  if (whatsapp == null) return '';
  return extractWhatsAppDigits(whatsapp);
}

/// V1-R05 — canonical detail destination resolver for the
/// `/directory/entity/:id` route.
///
/// The canonical `directory_entities.id` is the ONLY authoritative detail
/// state: [entityId] is always resolved through [repository]/cache before the
/// detail surface is shown. A whole-entity [seedEntity] is used ONLY as a
/// non-authoritative first-frame presentation optimization (fast paint while
/// the authoritative resolution is in flight) and is always replaced by the
/// resolved entity. Unknown/unresolvable ids render the unavailable state
/// instead of inventing an entity.
class DirectoryProviderDetailResolver extends StatefulWidget {
  const DirectoryProviderDetailResolver({
    super.key,
    required this.entityId,
    required this.repository,
    this.seedEntity,
    this.savedReferenceStore,
  });

  /// Canonical `directory_entities.id` (UUID) resolved by the route.
  final String entityId;

  /// Production repository/cache used for the authoritative resolution.
  final CloudDirectoryRepository repository;

  /// Non-authoritative first-frame hint; never the authoritative detail state.
  final CanonicalDirectoryEntity? seedEntity;

  /// Forwarded Saved store override for test/DI consistency.
  final SavedReferenceStore? savedReferenceStore;

  @override
  State<DirectoryProviderDetailResolver> createState() =>
      _DirectoryProviderDetailResolverState();
}

class _DirectoryProviderDetailResolverState
    extends State<DirectoryProviderDetailResolver> {
  CanonicalDirectoryEntity? _entity;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.seedEntity;
    _entity = (seed != null && seed.id == widget.entityId) ? seed : null;
    _resolve();
  }

  Future<void> _resolve() async {
    CanonicalDirectoryEntity? resolved;
    try {
      resolved = await widget.repository.loadByCanonicalId(widget.entityId);
    } catch (_) {
      resolved = null;
    }
    if (!mounted) return;
    setState(() {
      // Authoritative replacement — even a null (unknown) result replaces
      // the seed frame so a stale hint can never remain authoritative.
      _entity = resolved;
      _resolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entity = _entity;
    if (entity == null) {
      if (_resolved) {
        return Scaffold(
          appBar: CivilAppBar(title: const Text('')),
          body: const Center(child: Text('Entity not found')),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return DirectoryProviderDetailScreen(
      entity: entity,
      savedReferenceStore: widget.savedReferenceStore,
    );
  }
}