import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/location/baghdad_area.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../domain/user_profile.dart';
import '../providers/user_profile_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  int _step = 1;
  CivilUserType? _selectedType;
  BaghdadArea? _selectedArea;

  String tr(String ar, String en) =>
      context.watch<LanguageProvider>().isArabic ? ar : en;

  String _userTypeName(CivilUserType type) {
    switch (type) {
      case CivilUserType.siteEngineer:
        return tr(Ar.siteEngineer, En.siteEngineer);
      case CivilUserType.consultantEngineer:
        return tr(Ar.consultantEngineer, En.consultantEngineer);
      case CivilUserType.structuralEngineer:
        return tr(Ar.structuralEngineer, En.structuralEngineer);
      case CivilUserType.contractor:
        return tr(Ar.contractorName, En.contractorName);
      case CivilUserType.engineeringStudent:
        return tr(Ar.engineeringStudent, En.engineeringStudent);
      case CivilUserType.technicianSupervisor:
        return tr(Ar.technicianSupervisor, En.technicianSupervisor);
      case CivilUserType.supplierShopOwner:
        return tr(Ar.supplierShopOwner, En.supplierShopOwner);
      case CivilUserType.engineeringOffice:
        return tr(Ar.engineeringOffice, En.engineeringOffice);
      case CivilUserType.constructionCompany:
        return tr(Ar.constructionCompany, En.constructionCompany);
      case CivilUserType.buildingOffice:
        return tr(Ar.buildingOffice, En.buildingOffice);
      case CivilUserType.generalUser:
        return tr(Ar.generalUser, En.generalUser);
    }
  }

  IconData _userTypeIcon(CivilUserType type) {
    switch (type) {
      case CivilUserType.siteEngineer:
        return Icons.engineering;
      case CivilUserType.consultantEngineer:
        return Icons.assignment;
      case CivilUserType.structuralEngineer:
        return Icons.house;
      case CivilUserType.contractor:
        return Icons.build;
      case CivilUserType.engineeringStudent:
        return Icons.school;
      case CivilUserType.technicianSupervisor:
        return Icons.handyman;
      case CivilUserType.supplierShopOwner:
        return Icons.store;
      case CivilUserType.engineeringOffice:
        return Icons.business;
      case CivilUserType.constructionCompany:
        return Icons.domain;
      case CivilUserType.buildingOffice:
        return Icons.account_balance;
      case CivilUserType.generalUser:
        return Icons.person;
    }
  }

  Future<void> _complete() async {
    final profile = LocalUserProfile(
      anonymousInstallId: _generateId(),
      userType: _selectedType ?? CivilUserType.generalUser,
      baghdadArea: _selectedArea ?? BaghdadArea.unknown,
    );
    if (!mounted) return;
    await context.read<UserProfileProvider>().saveProfile(profile);
    if (!mounted) return;
    context.go('/home');
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = Random().nextInt(99999);
    return 'user_${timestamp}_$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step == 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step = 1),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xxl),
          child: _step == 1 ? _buildStep1(isArabic, isDark) : _buildStep2(isArabic, isDark),
        ),
      ),
    );
  }

  Widget _buildStep1(bool isArabic, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(Ar.profileStep1Of2, En.profileStep1Of2),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          tr(Ar.profileSetupTitle, En.profileSetupTitle),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        AppSpacing.gapXs,
        Text(
          tr(Ar.profileSetupSubtitle, En.profileSetupSubtitle),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          tr(Ar.profileStep1Title, En.profileStep1Title),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: ListView.separated(
            itemCount: CivilUserType.values.length - 1,
            separatorBuilder: (_, __) => AppSpacing.gapSm,
            itemBuilder: (context, index) {
              final type = CivilUserType.values[index];
              final isSelected = _selectedType == type;
              return _buildOptionCard(
                icon: _userTypeIcon(type),
                title: _userTypeName(type),
                isSelected: isSelected,
                onTap: () => setState(() => _selectedType = type),
                isDark: isDark,
              );
            },
          ),
        ),
        AppSpacing.gapLg,
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedType != null
                ? () => setState(() => _step = 2)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              elevation: 0,
            ),
            child: Text(
              tr(Ar.profileContinue, En.profileContinue),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(bool isArabic, bool isDark) {
    final areas = BaghdadArea.values.where((a) => a != BaghdadArea.unknown).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(Ar.profileStep2Of2, En.profileStep2Of2),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          tr(Ar.profileStep2Title, En.profileStep2Title),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        AppSpacing.gapXs,
        Text(
          tr(Ar.profileStep2Subtitle, En.profileStep2Subtitle),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
        ),
        AppSpacing.gapXs,
        Text(
          tr(Ar.profileSetupSubtitle, En.profileSetupSubtitle),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(
          child: ListView.separated(
            itemCount: areas.length,
            separatorBuilder: (_, __) => AppSpacing.gapSm,
            itemBuilder: (context, index) {
              final area = areas[index];
              final isSelected = _selectedArea == area;
              return _buildOptionCard(
                icon: Icons.location_on_outlined,
                title: isArabic ? area.arName : area.enName,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedArea = area),
                isDark: isDark,
              );
            },
          ),
        ),
        AppSpacing.gapLg,
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedArea != null ? _complete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              elevation: 0,
            ),
            child: Text(
              tr(Ar.profileComplete, En.profileComplete),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.curveFast,
          padding: AppSpacing.padLg,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : isDark
                    ? AppColors.darkCard
                    : Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
