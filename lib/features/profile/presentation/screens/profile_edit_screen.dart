import 'package:flutter/material.dart';
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

class ProfileEditScreen extends StatefulWidget {
  final LocalUserProfile profile;
  const ProfileEditScreen({super.key, required this.profile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late CivilUserType _selectedType;
  late BaghdadArea _selectedArea;
  bool _hasChanges = false;

  String tr(String ar, String en) =>
      context.watch<LanguageProvider>().isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.profile.userType;
    _selectedArea = widget.profile.baghdadArea;
  }

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

  void _pickUserType() {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final types = CivilUserType.values;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr(Ar.profileChangeRole, En.profileChangeRole)),
        children: types.map((type) {
          final isSelected = _selectedType == type;
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _selectedType = type;
                _hasChanges = true;
              });
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isArabic
                        ? _civilUserTypeAr(type)
                        : _civilUserTypeEn(type),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: AppColors.primary, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _pickBaghdadArea() {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final areas =
        BaghdadArea.values.where((a) => a != BaghdadArea.unknown).toList();

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr(Ar.profileChangeWorkArea, En.profileChangeWorkArea)),
        children: areas.map((area) {
          final isSelected = _selectedArea == area;
          return SimpleDialogOption(
            onPressed: () {
              setState(() {
                _selectedArea = area;
                _hasChanges = true;
              });
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isArabic ? area.arName : area.enName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: AppColors.primary, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _civilUserTypeEn(CivilUserType type) {
    switch (type) {
      case CivilUserType.siteEngineer:
        return En.siteEngineer;
      case CivilUserType.consultantEngineer:
        return En.consultantEngineer;
      case CivilUserType.structuralEngineer:
        return En.structuralEngineer;
      case CivilUserType.contractor:
        return En.contractorName;
      case CivilUserType.engineeringStudent:
        return En.engineeringStudent;
      case CivilUserType.technicianSupervisor:
        return En.technicianSupervisor;
      case CivilUserType.supplierShopOwner:
        return En.supplierShopOwner;
      case CivilUserType.engineeringOffice:
        return En.engineeringOffice;
      case CivilUserType.constructionCompany:
        return En.constructionCompany;
      case CivilUserType.buildingOffice:
        return En.buildingOffice;
      case CivilUserType.generalUser:
        return En.generalUser;
    }
  }

  String _civilUserTypeAr(CivilUserType type) {
    switch (type) {
      case CivilUserType.siteEngineer:
        return Ar.siteEngineer;
      case CivilUserType.consultantEngineer:
        return Ar.consultantEngineer;
      case CivilUserType.structuralEngineer:
        return Ar.structuralEngineer;
      case CivilUserType.contractor:
        return Ar.contractorName;
      case CivilUserType.engineeringStudent:
        return Ar.engineeringStudent;
      case CivilUserType.technicianSupervisor:
        return Ar.technicianSupervisor;
      case CivilUserType.supplierShopOwner:
        return Ar.supplierShopOwner;
      case CivilUserType.engineeringOffice:
        return Ar.engineeringOffice;
      case CivilUserType.constructionCompany:
        return Ar.constructionCompany;
      case CivilUserType.buildingOffice:
        return Ar.buildingOffice;
      case CivilUserType.generalUser:
        return Ar.generalUser;
    }
  }

  Future<void> _save() async {
    final updatedProfile = widget.profile.copyWith(
      userType: _selectedType,
      baghdadArea: _selectedArea,
      updatedAt: DateTime.now(),
    );
    await context.read<UserProfileProvider>().saveProfile(updatedProfile);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(Ar.profileUpdated, En.profileUpdated)),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(tr(Ar.profileMyCivilpediaProfile, En.profileMyCivilpediaProfile)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildSection(
            icon: Icons.badge_outlined,
            label: tr(Ar.profileRole, En.profileRole),
            value: _userTypeName(_selectedType),
            subtitleColor: subtitleColor,
            textColor: textColor,
            isDark: isDark,
            onTap: _pickUserType,
          ),
          AppSpacing.gapMd,
          _buildSection(
            icon: Icons.location_on_outlined,
            label: tr(Ar.profileMainWorkArea, En.profileMainWorkArea),
            value: isArabic ? _selectedArea.arName : _selectedArea.enName,
            subtitleColor: subtitleColor,
            textColor: textColor,
            isDark: isDark,
            onTap: _pickBaghdadArea,
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _hasChanges ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                elevation: 0,
              ),
              child: Text(
                tr(Ar.profileSaveChanges, En.profileSaveChanges),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String label,
    required String value,
    required Color subtitleColor,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(value, style: TextStyle(color: subtitleColor)),
        trailing: Text(
          tr(Ar.profileEditPreferences, En.profileEditPreferences),
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

}
