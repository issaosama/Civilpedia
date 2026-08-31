import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/location/baghdad_area.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/civil_app_bar.dart';
import '../../../core/widgets/civil_surface_card.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../profile/domain/service_business_profile.dart';
import 'directory_category_presentation.dart';
import 'directory_verification_badge.dart';
import 'services/directory_contact_launcher.dart';

/// W5.4 — canonical reusable Directory provider detail surface.
///
/// Deliberately excludes saved/bookmark (W5.6) and any Monetization signals
/// (W7). Maps launch is deferred: the entity has address + BaghdadArea but no
/// coordinates, so W5.4 displays location text only. Verification is displayed
/// as a compact badge in the identity/header block (W5.5) — display only, never
/// filtering, ranking or contact-altering.
class DirectoryProviderDetailScreen extends StatefulWidget {
  /// The provider to display, passed directly from the listing.
  final ServiceBusinessProfile profile;

  /// Injected contact launcher. Production default uses [url_launcher]; tests
  /// inject a fake so widget tests never open a real external app.
  final DirectoryContactLauncher? contactLauncher;

  const DirectoryProviderDetailScreen({
    super.key,
    required this.profile,
    this.contactLauncher,
  });

  @override
  State<DirectoryProviderDetailScreen> createState() =>
      _DirectoryProviderDetailScreenState();
}

class _DirectoryProviderDetailScreenState
    extends State<DirectoryProviderDetailScreen> {
  late final DirectoryContactLauncher _launcher;

  @override
  void initState() {
    super.initState();
    _launcher =
        widget.contactLauncher ?? const UrlLauncherDirectoryContactLauncher();
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

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final theme = Theme.of(context);

    final description = profile.description?.trim();
    final address = profile.address?.trim();
    final services = _nonEmptyList([...profile.categories, ...profile.subCategories]);
    final phones = _nonEmptyPhones(profile.phones);
    final whatsappDigits = _whatsappDigits(profile.whatsapp);
    final hasActionableContact = phones.isNotEmpty || whatsappDigits.isNotEmpty;

    return Scaffold(
      appBar: CivilAppBar(title: Text(profile.name)),
      body: ListView(
        padding: AppSpacing.padLg,
        children: [
          _buildIdentity(profile, isArabic, theme),
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
            _buildContactActions(profile, phones, whatsappDigits, isArabic, theme)
          else
            _buildNoContact(theme),
        ],
      ),
    );
  }

  Widget _buildIdentity(
    ServiceBusinessProfile profile,
    bool isArabic,
    ThemeData theme,
  ) {
    final typeLabel = DirectoryCategoryPresentation.labelFor(
      profile.type,
      isArabic: isArabic,
    );
    final locationLabel =
        profile.baghdadArea == BaghdadArea.unknown
            ? (isArabic ? Ar.directoryNotSpecified : En.directoryNotSpecified)
            : (isArabic ? profile.baghdadArea.arName : profile.baghdadArea.enName);

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
                  DirectoryCategoryPresentation.iconFor(profile.type),
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
                      profile.name,
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
                    Text(
                      locationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DirectoryVerificationBadge(
                      status: profile.verificationStatus,
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
    ServiceBusinessProfile profile,
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

List<String> _nonEmptyPhones(List<String> phones) {
  final result = <String>[];
  for (final raw in phones) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) result.add(trimmed);
  }
  return result;
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
