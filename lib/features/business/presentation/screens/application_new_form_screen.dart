import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../localization/ar.dart';
import '../../domain/business_application_gateway.dart';
import '../../domain/business_application_metadata.dart';
import '../../domain/directory_entity_types.dart';
import '../providers/business_application_provider.dart';
import '../widgets/business_sign_in_required_view.dart';
import '../widgets/directory_entity_type_labels.dart';

/// V1-R04 — NEW business application form at `/business/applications/new`.
///
/// Collects exactly `name` and `entity_type` using the canonical
/// [BusinessApplicationMetadata] keys and the [DirectoryEntityType] canonical
/// values. Does NOT auto-submit after draft creation.
class ApplicationNewFormScreen extends StatefulWidget {
  const ApplicationNewFormScreen({super.key});

  @override
  State<ApplicationNewFormScreen> createState() =>
      _ApplicationNewFormScreenState();
}

class _ApplicationNewFormScreenState extends State<ApplicationNewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedEntityType;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _selectedEntityType == null) return;
    setState(() => _submitting = true);
    try {
      final provider = context.read<BusinessApplicationProvider>();
      final metadata = <String, dynamic>{
        BusinessApplicationMetadata.name: _nameController.text.trim(),
        BusinessApplicationMetadata.entityType: _selectedEntityType!,
      };
      final result = await provider.createNewDraft(metadata: metadata);
      if (!mounted) return;
      if (result is BusinessApplicationCreated) {
        // Navigate back to the list (draft created, not auto-submitted).
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
      if (result is BusinessApplicationCreateDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              BusinessApplicationCauseMessages.messageFor(result.cause),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = true;
    final provider = context.watch<BusinessApplicationProvider>();

    if (!provider.isAuthenticated) {
      return Scaffold(
        appBar: CivilAppBar(
          title: const Text(Ar.businessNewApplicationTitle),
          showBackButton: true,
        ),
        body: const BusinessSignInRequiredView(),
      );
    }

    return Scaffold(
      appBar: CivilAppBar(
        title: const Text(Ar.businessNewApplicationTitle),
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            CivilSurfaceCard(
              hasBorder: true,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Ar.businessNewApplicationSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: Ar.businessNameLabel,
                      hintText: Ar.businessNameHint,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return Ar.businessNameLabel;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Entity type selector
                  Text(
                    Ar.businessEntityTypeLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _EntityTypeDropdown(
                    selected: _selectedEntityType,
                    isArabic: isArabic,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _selectedEntityType = v),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _onSubmit,
                      child: Text(_submitting ? Ar.businessCreating : Ar.businessCreateDraft),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Static metadata notice
            Text(
              Ar.businessCorrectionInfo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntityTypeDropdown extends StatelessWidget {
  final String? selected;
  final bool isArabic;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _EntityTypeDropdown({
    required this.selected,
    required this.isArabic,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      hint: Text(Ar.businessEntityTypeHint),
      items: DirectoryEntityType.all
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Text(DirectoryEntityTypeLabels.labelFor(type, isArabic: isArabic)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (!DirectoryEntityType.isKnown(value)) {
          return Ar.businessEntityTypeHint;
        }
        return null;
      },
    );
  }
}