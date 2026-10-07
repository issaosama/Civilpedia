import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/app_dependencies.dart';
import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../../core/widgets/remote_data_notice.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../routes/app_routes.dart';
import '../../saved/domain/saved_item_reference.dart';
import '../../saved/domain/saved_reference_store.dart';
import '../application/directory_detail_controller.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/cloud_directory_repository.dart';
import 'canonical_entity_type_presentation.dart';
import 'directory_verification_badge.dart';
import 'services/directory_contact_launcher.dart';

/// Public canonical Directory detail. Saved is a local preference; the generic
/// management entry refers to the viewer's existing managed list.
class DirectoryProviderDetailScreen extends StatefulWidget {
  final CanonicalDirectoryEntity entity;
  final DirectoryContactLauncher? contactLauncher;
  final SavedReferenceStore? savedReferenceStore;
  final RemoteDataCause? noticeCause;
  final VoidCallback? onRetryCause;

  /// Presentation of an existing provisional read, never a refresh policy.
  final bool isUpdating;

  const DirectoryProviderDetailScreen({
    super.key,
    required this.entity,
    this.contactLauncher,
    this.savedReferenceStore,
    this.noticeCause,
    this.onRetryCause,
    this.isUpdating = false,
  });

  @override
  State<DirectoryProviderDetailScreen> createState() =>
      _DirectoryProviderDetailScreenState();
}

class _DirectoryProviderDetailScreenState
    extends State<DirectoryProviderDetailScreen> {
  late final DirectoryContactLauncher _launcher;
  late final SavedReferenceStore? _savedStoreOverride;
  late final String _providerRefId;
  bool? _isSaved;

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
        SnackBar(content: Text(isArabic ? Ar.errorOccurred : En.errorOccurred)),
      );
    }
  }

  Future<void> _launchPhone(String trimmedPhone) async {
    try {
      final ok = await _launcher.launchPhone(trimmedPhone);
      if (!ok) _showLaunchFailure();
    } catch (_) {
      _showLaunchFailure();
    }
  }

  Future<void> _launchWhatsApp(String digits) async {
    try {
      final ok = await _launcher.launchWhatsApp(digits);
      if (!ok) _showLaunchFailure();
    } catch (_) {
      _showLaunchFailure();
    }
  }

  void _showLaunchFailure() {
    if (!mounted) return;
    final isArabic = context.read<LanguageProvider>().isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isArabic ? Ar.cui1ContactFailure : En.cui1ContactFailure),
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
      key: const ValueKey('cui1-detail-save'),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: _quickActionContent(
        unsaved ? Icons.bookmark_border : Icons.bookmark,
        unsaved
            ? (isArabic ? Ar.cui1SaveAction : En.cui1SaveAction)
            : (isArabic ? Ar.cui1SavedAction : En.cui1SavedAction),
        style: Theme.of(context).textTheme.labelLarge,
      ),
      tooltip: tooltip,
      onPressed: _toggleSaved,
    );
  }

  /// Retains the accepted contact projection, including all phone values and
  /// the last nonempty WhatsApp value before ASCII digit extraction.
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
    return (phones, extractWhatsAppDigits(whatsapp));
  }

  @override
  Widget build(BuildContext context) {
    final entity = widget.entity;
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final theme = Theme.of(context);
    final categories = _nonEmptyList(
      entity.categories.map((category) => _categoryLabel(category, isArabic)),
    );
    final locations = entity.locations.where(_hasUsefulLocation).toList();
    final (phones, whatsappDigits) = _contactProjection(entity);
    final textContacts = entity.contacts.where((contact) {
      final type = contact.contactType.toLowerCase();
      return contact.value.trim().isNotEmpty &&
          (type == 'email' || type == 'website' || type == 'other');
    }).toList();
    final covers = _mediaUrls(entity, 'cover');
    final logos = _mediaUrls(entity, 'logo');
    final gallery = _mediaUrls(entity, 'gallery');
    // A role is selected only when its supplied URL is unambiguous. Never infer
    // cover/logo roles from an untyped or first arbitrary media row.
    final cover = covers.length == 1 ? covers.single : null;
    final logo = logos.length == 1 ? logos.single : null;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final gutter = viewportWidth < 600
              ? AppSpacing.lg
              : viewportWidth < 840
              ? AppSpacing.xxl
              : 2 * AppSpacing.lg;
          final availableWidth = math.min(
            math.max(0.0, viewportWidth - 2 * gutter),
            1120.0,
          );
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          final useColumns =
              viewportWidth >= 840 && availableWidth >= 760 && scale < 1.3;
          final contentWidth = useColumns
              ? availableWidth
              : math.min(availableWidth, 760.0);
          final primary = _detailCardTheme(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDescription(entity, isArabic, theme),
                if (gallery.isNotEmpty)
                  _DirectoryGallery(
                    key: ValueKey(entity.id),
                    urls: gallery,
                    builder: (usable, onFailure) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildGallery(usable, isArabic, onFailure),
                    ),
                  ),
                const SizedBox(height: 12),
                _sectionCard(
                  isArabic ? Ar.cui1Specialties : En.cui1Specialties,
                  categories.isEmpty
                      ? Text(
                          isArabic ? Ar.cui1NoCategories : En.cui1NoCategories,
                        )
                      : _CategoriesWrap(values: categories),
                  icon: Icons.workspaces_outline,
                  key: const ValueKey('cui1-detail-specialties'),
                ),
                const SizedBox(height: 12),
                _buildLocations(locations, isArabic, theme),
              ],
            ),
          );
          final contacts = _detailCardTheme(
            _buildContacts(
              phones,
              whatsappDigits,
              textContacts,
              isArabic,
              theme,
            ),
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: math.min(viewportWidth, 1120),
                    height: viewportWidth < 600 ? 156.0 : 224.0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _DirectoryMediaImage(
                            key: const ValueKey('cui1-detail-hero'),
                            url: cover,
                            fallback: Container(
                              key: const ValueKey('cui1-detail-hero-fallback'),
                              color: theme.colorScheme.secondaryContainer,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.architecture_outlined,
                                size: 72,
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.28,
                                ),
                              ),
                            ),
                          ),
                          if (Navigator.of(context).canPop())
                            PositionedDirectional(
                              top: MediaQuery.paddingOf(context).top + 8,
                              start: 8,
                              child: SizedBox.square(
                                dimension: 48,
                                child: Material(
                                  shape: const CircleBorder(),
                                  color: theme.colorScheme.surface.withValues(
                                    alpha: 0.88,
                                  ),
                                  child: const BackButton(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    key: const ValueKey('cui1-detail-content'),
                    width: contentWidth,
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: shellSafeBottomPadding(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildIdentity(entity, logo, isArabic, theme),
                          _buildQuickActions(phones, whatsappDigits, isArabic),
                          const SizedBox(height: 6),
                          Text(
                            isArabic
                                ? Ar.cui1VerificationContext
                                : En.cui1VerificationContext,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              height: 1.5,
                              color: theme.brightness == Brightness.dark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.noticeCause != null) ...[
                            _buildStaleNotice(isArabic, theme),
                            const SizedBox(height: 12),
                          ] else if (widget.isUpdating) ...[
                            _buildUpdatingNotice(isArabic, theme),
                            const SizedBox(height: 12),
                          ],
                          if (useColumns)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: primary),
                                const SizedBox(width: 20),
                                SizedBox(width: 300, child: contacts),
                              ],
                            )
                          else ...[
                            primary,
                            const SizedBox(height: 12),
                            contacts,
                          ],
                          const SizedBox(height: 12),
                          _detailCardTheme(
                            _ResponsiveCards(
                              minimumWidth: 160,
                              stackOnCompact: true,
                              children: [
                                _buildManagement(isArabic),
                                _buildCommercialInformation(isArabic, theme),
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
          );
        },
      ),
    );
  }

  Widget _detailCardTheme(Widget child) {
    final theme = Theme.of(context);
    if (theme.brightness != Brightness.dark) return child;
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          outlineVariant: theme.colorScheme.outlineVariant.withValues(
            alpha: 0.65,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildIdentity(
    CanonicalDirectoryEntity entity,
    String? logo,
    bool isArabic,
    ThemeData theme,
  ) {
    final region = _locationSummary(entity, isArabic);
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          entity.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: MediaQuery.sizeOf(context).width < 600 ? 16 : 22,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DirectoryVerificationBadge(status: entity.verificationStatus),
            Text(
              CanonicalEntityTypePresentation.labelFor(
                entity.entityType,
                isArabic: isArabic,
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (region != null) Text(region, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
    final avatar = Transform.translate(
      offset: const Offset(0, -34),
      child: CivilSurfaceCard(
        key: const ValueKey('cui1-detail-avatar'),
        elevation: 1,
        radius: 20,
        hasBorder: true,
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 84,
          height: 84,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _DirectoryMediaImage(
              url: logo,
              fit: BoxFit.contain,
              fallback: Icon(
                CanonicalEntityTypePresentation.iconFor(entity.entityType),
                size: 40,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ),
      ),
    );
    return Padding(
      key: const ValueKey('cui1-detail-identity'),
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
          if (constraints.maxWidth < 320 || scale > 1.4) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: AlignmentDirectional.centerEnd, child: avatar),
                identity,
              ],
            );
          }
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 12),
                  avatar,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(
    List<String> phones,
    String whatsapp,
    bool isArabic,
  ) {
    final theme = Theme.of(context);
    final green = theme.brightness == Brightness.dark
        ? AppColors.darkSuccess
        : AppColors.success;
    return _ResponsiveCards(
      key: const ValueKey('cui1-detail-quick-actions'),
      minimumWidth: 95,
      children: [
        if (phones.isNotEmpty)
          FilledButton(
            key: const ValueKey('cui1-quick-call'),
            onPressed: () => _launchPhone(phones.first),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _quickActionContent(
              Icons.call_outlined,
              isArabic ? Ar.directoryCall : En.directoryCall,
            ),
          ),
        if (whatsapp.isNotEmpty)
          OutlinedButton(
            key: const ValueKey('cui1-quick-whatsapp'),
            onPressed: () => _launchWhatsApp(whatsapp),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: green,
              backgroundColor: green.withValues(alpha: 0.08),
              side: BorderSide(color: green.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _quickActionContent(
              Icons.chat_bubble_outline,
              isArabic ? Ar.directoryWhatsApp : En.directoryWhatsApp,
            ),
          ),
        if (_isSaved != null) _buildSaveAction(isArabic),
      ],
    );
  }

  Widget _quickActionContent(IconData icon, String label, {TextStyle? style}) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final text = Text(label, textAlign: TextAlign.center, style: style);
    if (MediaQuery.sizeOf(context).width < 600 && scale > 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 20), const SizedBox(height: 4), text],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 6),
        Flexible(child: text),
      ],
    );
  }

  Widget _sectionCard(String heading, Widget body, {Key? key, IconData? icon}) {
    final theme = Theme.of(context);
    return CivilSurfaceCard(
      key: key,
      elevation: 0,
      hasBorder: true,
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    heading,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }

  Widget _buildDescription(
    CanonicalDirectoryEntity entity,
    bool isArabic,
    ThemeData theme,
  ) {
    final description = entity.description?.trim();
    return _sectionCard(
      isArabic ? Ar.cui1About : En.cui1About,
      Text(
        description != null && description.isNotEmpty
            ? description
            : (isArabic ? Ar.cui1NoDescription : En.cui1NoDescription),
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.55,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      icon: Icons.description_outlined,
      key: const ValueKey('cui1-detail-about'),
    );
  }

  Widget _buildGallery(
    List<String> urls,
    bool isArabic,
    void Function(String) onFailure,
  ) {
    return _sectionCard(
      isArabic ? Ar.cui1Gallery : En.cui1Gallery,
      Row(
        children: [
          for (var i = 0; i < math.min(3, urls.length); i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _DirectoryMediaImage(
                        url: urls[i],
                        fallback: const SizedBox.shrink(),
                        onFailure: () => onFailure(urls[i]),
                      ),
                      if (i == 2 && urls.length > 3)
                        Align(
                          alignment: AlignmentDirectional.bottomEnd,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '+${urls.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      icon: Icons.photo_library_outlined,
      key: const ValueKey('cui1-detail-gallery'),
    );
  }

  Widget _buildLocations(
    List<CanonicalDirectoryLocation> locations,
    bool isArabic,
    ThemeData theme,
  ) {
    return _sectionCard(
      isArabic ? Ar.cui1Locations : En.cui1Locations,
      locations.isEmpty
          ? Text(isArabic ? Ar.cui1NoLocations : En.cui1NoLocations)
          : _ResponsiveCards(
              minimumWidth: 145,
              stackOnCompact: true,
              children: [
                for (final location in locations)
                  CivilSurfaceCard(
                    elevation: 0,
                    hasBorder: true,
                    radius: 12,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 6),
                            if (_hasRegion(location))
                              Expanded(
                                child: Text(
                                  _regionLabel(location, isArabic),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (location.isPrimary) ...[
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? Ar.cui1PrimaryLocation
                                : En.cui1PrimaryLocation,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                        if (_trimmed(location.address).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            location.address!.trim(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
      icon: Icons.location_on_outlined,
      key: const ValueKey('cui1-detail-locations'),
    );
  }

  Widget _buildContacts(
    List<String> phones,
    String whatsapp,
    List<CanonicalDirectoryContact> textContacts,
    bool isArabic,
    ThemeData theme,
  ) {
    final primary = <Widget>[
      for (final phone in phones)
        _ContactButton(
          icon: Icons.phone,
          label: isArabic ? Ar.cui1Phone : En.cui1Phone,
          value: phone,
          onPressed: () => _launchPhone(phone),
        ),
      if (whatsapp.isNotEmpty)
        _ContactButton(
          icon: Icons.chat,
          label: isArabic ? Ar.cui1WhatsAppNumber : En.cui1WhatsAppNumber,
          value: whatsapp,
          onPressed: () => _launchWhatsApp(whatsapp),
          whatsapp: true,
        ),
    ];
    final secondary = <Widget>[
      for (final type in ['email', 'website', 'other'])
        for (final contact in textContacts.where(
          (contact) => contact.contactType.toLowerCase() == type,
        ))
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  contact.contactType.toLowerCase() == 'email'
                      ? Icons.email_outlined
                      : contact.contactType.toLowerCase() == 'website'
                      ? Icons.language
                      : Icons.contact_mail_outlined,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SelectableText(
                          contact.value.trim(),
                          textAlign: TextAlign.start,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _textContactLabel(contact, isArabic),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    ];
    Widget group(List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          rows[i],
        ],
      ],
    );
    return _sectionCard(
      isArabic ? Ar.directoryContact : En.directoryContact,
      primary.isEmpty && secondary.isEmpty
          ? Text(isArabic ? Ar.cui1NoContacts : En.cui1NoContacts)
          : _ResponsiveCards(
              minimumWidth: 145,
              stackOnCompact: true,
              children: [
                if (primary.isNotEmpty) group(primary),
                if (secondary.isNotEmpty) group(secondary),
              ],
            ),
      icon: Icons.contact_phone_outlined,
      key: const ValueKey('cui1-detail-contacts'),
    );
  }

  Widget _buildManagement(bool isArabic) {
    final theme = Theme.of(context);
    return TextButton(
      key: const ValueKey('cui1-detail-management'),
      onPressed: () => context.push(AppRoutes.businessManage),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(12),
        alignment: AlignmentDirectional.topStart,
        backgroundColor: theme.colorScheme.secondaryContainer,
        foregroundColor: theme.colorScheme.onSecondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.secondary.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.business_center_outlined, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic ? Ar.cui1ManageBusinesses : En.cui1ManageBusinesses,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? Ar.cui1ManageInformation : En.cui1ManageInformation,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialInformation(bool isArabic, ThemeData theme) {
    return CivilSurfaceCard(
      key: const ValueKey('cui1-detail-commercial-info'),
      elevation: 0,
      warm: true,
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isArabic
                      ? Ar.cui1CommercialHeading
                      : En.cui1CommercialHeading,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? Ar.cui1CommercialInformation
                : En.cui1CommercialInformation,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatingNotice(bool isArabic, ThemeData theme) => Semantics(
    liveRegion: true,
    child: CivilSurfaceCard(
      key: const ValueKey('cui1-directory-updating'),
      elevation: 0,
      hasBorder: true,
      child: Row(
        children: [
          Icon(Icons.sync, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isArabic ? Ar.cui1Updating : En.cui1Updating,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildStaleNotice(bool isArabic, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RemoteDataNotice(
        cause: widget.noticeCause!,
        mode: RemoteDataNoticeMode.compact,
        onRetry: null,
      ),
      AppSpacing.gapSm,
      Text(
        isArabic ? Ar.cui1Snapshot : En.cui1Snapshot,
        style: theme.textTheme.bodySmall,
      ),
      if (widget.onRetryCause != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: widget.onRetryCause,
            icon: const Icon(Icons.refresh),
            label: Text(isArabic ? Ar.retry : En.retry),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ),
    ],
  );
}

/// Feature-local layout only. Long content/large text gets fewer columns.
class _ResponsiveCards extends StatelessWidget {
  const _ResponsiveCards({
    super.key,
    required this.children,
    required this.minimumWidth,
    this.stackOnCompact = false,
  });
  final List<Widget> children;
  final double minimumWidth;
  final bool stackOnCompact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final maxColumns = minimumWidth == 95 ? children.length : 2;
      if (minimumWidth == 95 && constraints.maxWidth >= 300 && scale <= 1.3) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: children[i]),
              ],
            ],
          ),
        );
      }
      final columns = stackOnCompact && MediaQuery.sizeOf(context).width < 600
          ? 1
          : math.max(
              1,
              math.min(
                maxColumns,
                ((constraints.maxWidth + 10) / (minimumWidth * scale + 10))
                    .floor(),
              ),
            );
      final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _CategoriesWrap extends StatelessWidget {
  const _CategoriesWrap({required this.values});
  final List<String> values;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPressed,
    this.whatsapp = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onPressed;
  final bool whatsapp;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = whatsapp
        ? (theme.brightness == Brightness.dark
              ? AppColors.darkSuccess
              : AppColors.success)
        : theme.colorScheme.secondary;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: accent,
        side: BorderSide(color: accent.withValues(alpha: 0.18)),
        padding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: theme.textTheme.labelSmall)),
            ],
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodySmall?.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

// Resolve each unique supplied gallery URL through Flutter's normal image
// pipeline. Only decoded images enter the gallery/count; no HTTP probe, retry,
// or substituted media. Successful first frames are retained by the image
// cache, while this widget releases its listeners and ImageInfo references.
class _DirectoryGallery extends StatefulWidget {
  const _DirectoryGallery({
    super.key,
    required this.urls,
    required this.builder,
  });
  final List<String> urls;
  final Widget Function(List<String>, void Function(String)) builder;

  @override
  State<_DirectoryGallery> createState() => _DirectoryGalleryState();
}

class _DirectoryGalleryState extends State<_DirectoryGallery> {
  final _results = <String, bool?>{};
  final _streams = <String, (ImageStream, ImageStreamListener)>{};
  bool _rebuildScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncImages();
  }

  @override
  void didUpdateWidget(_DirectoryGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncImages();
  }

  void _release(String url) {
    final subscription = _streams.remove(url);
    if (subscription != null) subscription.$1.removeListener(subscription.$2);
  }

  void _syncImages() {
    final supplied = widget.urls.toSet();
    for (final url in _results.keys.toList()) {
      if (!supplied.contains(url)) {
        _release(url);
        _results.remove(url);
      }
    }
    for (final url in supplied) {
      if (_results.containsKey(url)) continue;
      _results[url] = null;
      final stream = NetworkImage(
        url,
      ).resolve(createLocalImageConfiguration(context));
      late final ImageStreamListener listener;
      void finish(bool loaded) {
        if (!mounted || !identical(_streams[url]?.$2, listener)) return;
        _release(url);
        _results[url] = loaded;
        _scheduleRebuild();
      }

      listener = ImageStreamListener((info, synchronousCall) {
        info.dispose();
        finish(true);
      }, onError: (Object error, StackTrace? stack) => finish(false));
      _streams[url] = (stream, listener);
      stream.addListener(listener);
    }
  }

  void _onFailure(String url) {
    if (!mounted || _results[url] != true) return;
    _results[url] = false;
    _scheduleRebuild();
  }

  void _scheduleRebuild() {
    if (_rebuildScheduled) return;
    _rebuildScheduled = true;
    // Cached frames and Image.errorBuilder can report during a build. Batch
    // terminal transitions after that frame, guarding disposal and avoiding a
    // repeated failure mutation on subsequent builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    for (final url in _streams.keys.toList()) {
      _release(url);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usable = widget.urls.where((url) => _results[url] == true).toList();
    return usable.isEmpty
        ? const SizedBox.shrink()
        : widget.builder(usable, _onFailure);
  }
}

/// Public supplied HTTPS image only. No credentials, storage inference, media
/// fetch for untyped entries, new interaction, or raw failure text is exposed.
class _DirectoryMediaImage extends StatelessWidget {
  const _DirectoryMediaImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallback,
    this.onFailure,
  });
  final String? url;
  final BoxFit fit;
  final Widget? fallback;
  final VoidCallback? onFailure;
  @override
  Widget build(BuildContext context) {
    final empty =
        fallback ??
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Icon(
            Icons.image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
    if (url == null) return ExcludeSemantics(child: empty);
    return ExcludeSemantics(
      child: Image.network(
        url!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stack) {
          onFailure?.call();
          return empty;
        },
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : empty,
      ),
    );
  }
}

List<String> _mediaUrls(CanonicalDirectoryEntity entity, String role) {
  final urls = <String>[];
  for (final media in entity.media) {
    if (media.mediaType != role) continue;
    final raw = media.url.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      continue;
    }
    if (!urls.contains(raw)) urls.add(raw);
  }
  return urls;
}

String _trimmed(String? value) => value?.trim() ?? '';

String _firstLabel(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = _trimmed(value);
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String _categoryLabel(CanonicalDirectoryCategory category, bool isArabic) {
  return _firstLabel([
    isArabic ? category.nameAr : category.nameEn,
    isArabic ? category.nameEn : category.nameAr,
    category.name,
    category.code,
  ]);
}

bool _hasRegion(CanonicalDirectoryLocation location) {
  return _firstLabel([
    location.regionNameAr,
    location.regionNameEn,
    location.regionName,
    location.regionCode,
  ]).isNotEmpty;
}

bool _hasUsefulLocation(CanonicalDirectoryLocation location) =>
    _hasRegion(location) || _trimmed(location.address).isNotEmpty;

String _regionLabel(CanonicalDirectoryLocation location, bool isArabic) {
  final label = _firstLabel([
    isArabic ? location.regionNameAr : location.regionNameEn,
    isArabic ? location.regionNameEn : location.regionNameAr,
    location.regionName,
    location.regionCode,
  ]);
  return label.isNotEmpty
      ? label
      : (isArabic ? Ar.directoryNotSpecified : En.directoryNotSpecified);
}

String? _locationSummary(CanonicalDirectoryEntity entity, bool isArabic) {
  for (final location in entity.locations) {
    if (_hasRegion(location)) return _regionLabel(location, isArabic);
  }
  return null;
}

List<String> _nonEmptyList(Iterable<String> values) {
  final result = <String>[];
  for (final raw in values) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) result.add(trimmed);
  }
  return result;
}

String _textContactLabel(CanonicalDirectoryContact contact, bool isArabic) {
  return switch (contact.contactType.toLowerCase()) {
    'email' => isArabic ? Ar.cui1Email : En.cui1Email,
    'website' => isArabic ? Ar.cui1Website : En.cui1Website,
    _ => isArabic ? Ar.cui1OtherContact : En.cui1OtherContact,
  };
}

/// Canonical UUID resolver. Matching seeds remain provisional until the
/// existing controller settles the authoritative read.
class DirectoryProviderDetailResolver extends StatefulWidget {
  const DirectoryProviderDetailResolver({
    super.key,
    required this.entityId,
    required this.repository,
    this.connectivityProvider,
    this.seedEntity,
    this.savedReferenceStore,
  });

  final String entityId;
  final CloudDirectoryRepository repository;
  final ConnectivityProvider? connectivityProvider;
  final CanonicalDirectoryEntity? seedEntity;
  final SavedReferenceStore? savedReferenceStore;

  @override
  State<DirectoryProviderDetailResolver> createState() =>
      _DirectoryProviderDetailResolverState();
}

class _DirectoryProviderDetailResolverState
    extends State<DirectoryProviderDetailResolver> {
  DirectoryDetailController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = DirectoryDetailController(
      repository: widget.repository,
      entityId: widget.entityId,
      connectivity: widget.connectivityProvider,
      seedEntity: widget.seedEntity,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final controller = _controller;

    if (controller == null) {
      return Scaffold(
        appBar: CivilAppBar(
          title: Text(isArabic ? Ar.directory : En.directory),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final entity = controller.entity;
        final state = controller.state;

        if (entity != null) {
          return DirectoryProviderDetailScreen(
            entity: entity,
            savedReferenceStore: widget.savedReferenceStore,
            noticeCause: state == DirectoryDetailState.stale
                ? controller.cause
                : null,
            onRetryCause: controller.retry,
            isUpdating:
                state == DirectoryDetailState.stale &&
                controller.isLoading &&
                controller.cause == null,
          );
        }

        if (state == DirectoryDetailState.invalidId) {
          return _buildMessageState(
            isArabic
                ? Ar.directoryInvalidEntityId
                : En.directoryInvalidEntityId,
          );
        }

        if (state == DirectoryDetailState.notFound) {
          return _buildMessageState(
            isArabic ? Ar.directoryEntityNotFound : En.directoryEntityNotFound,
            explanation: isArabic ? Ar.cui1Unavailable : En.cui1Unavailable,
          );
        }

        if (state == DirectoryDetailState.unresolved && !controller.isLoading) {
          final cause = controller.cause ?? RemoteDataCause.unexpected;
          return Scaffold(
            appBar: CivilAppBar(title: const Text('')),
            body: Center(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  shellSafeBottomPadding(context),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RemoteDataNotice(
                        cause: cause,
                        mode: RemoteDataNoticeMode.noData,
                        onRetry: null,
                      ),
                      AppSpacing.gapLg,
                      OutlinedButton.icon(
                        onPressed: controller.retry,
                        icon: const Icon(Icons.refresh),
                        label: Text(isArabic ? Ar.retry : En.retry),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: CivilAppBar(
            title: Text(isArabic ? Ar.directory : En.directory),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildMessageState(String message, {String? explanation}) {
    return Scaffold(
      appBar: CivilAppBar(title: const Text('')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            shellSafeBottomPadding(context),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (explanation != null) ...[
                  AppSpacing.gapMd,
                  Text(
                    explanation,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
