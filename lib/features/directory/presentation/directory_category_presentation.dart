import 'package:flutter/material.dart';

import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../profile/domain/service_business_profile.dart';

/// Presentation-only metadata for the Directory category browse grid.
///
/// W5.2 — maps the stable [BusinessType] identity to a localized display label
/// and a presentation icon. This is PURELY cosmetic: it owns no identity, no
/// persistence, no filtering, no counts, no routes, and no business rules.
/// [BusinessType] stable keys remain the identity; labels and icons are
/// display-only and never enter persisted data, routes, or repository queries.
abstract final class DirectoryCategoryPresentation {
  /// Fixed PRESENTATION order for the Landing grid (presentation-only).
  ///
  /// NOT alphabetical, NOT count-based, NOT verification/ sponsorship based,
  /// NOT derived from `sb_profiles`.
  static const List<BusinessType> orderedTypes = [
    BusinessType.supplier,
    BusinessType.technician,
    BusinessType.equipmentOwner,
    BusinessType.engineeringOffice,
    BusinessType.constructionCompany,
    BusinessType.buildingOffice,
    BusinessType.testingLab,
    BusinessType.surveyor,
    BusinessType.contractor,
    BusinessType.materialShop,
    BusinessType.consultantOffice,
    BusinessType.other,
  ];

  /// Arabic display label (presentation-only).
  static String arLabel(BusinessType type) {
    switch (type) {
      case BusinessType.supplier:
        return Ar.directoryTypeSupplier;
      case BusinessType.technician:
        return Ar.directoryTypeTechnician;
      case BusinessType.equipmentOwner:
        return Ar.directoryTypeEquipmentOwner;
      case BusinessType.engineeringOffice:
        return Ar.directoryTypeEngineeringOffice;
      case BusinessType.constructionCompany:
        return Ar.directoryTypeConstructionCompany;
      case BusinessType.buildingOffice:
        return Ar.directoryTypeBuildingOffice;
      case BusinessType.testingLab:
        return Ar.directoryTypeTestingLab;
      case BusinessType.surveyor:
        return Ar.directoryTypeSurveyor;
      case BusinessType.contractor:
        return Ar.directoryTypeContractor;
      case BusinessType.materialShop:
        return Ar.directoryTypeMaterialShop;
      case BusinessType.consultantOffice:
        return Ar.directoryTypeConsultantOffice;
      case BusinessType.other:
        return Ar.directoryTypeOther;
    }
  }

  /// English display label (presentation-only).
  static String enLabel(BusinessType type) {
    switch (type) {
      case BusinessType.supplier:
        return En.directoryTypeSupplier;
      case BusinessType.technician:
        return En.directoryTypeTechnician;
      case BusinessType.equipmentOwner:
        return En.directoryTypeEquipmentOwner;
      case BusinessType.engineeringOffice:
        return En.directoryTypeEngineeringOffice;
      case BusinessType.constructionCompany:
        return En.directoryTypeConstructionCompany;
      case BusinessType.buildingOffice:
        return En.directoryTypeBuildingOffice;
      case BusinessType.testingLab:
        return En.directoryTypeTestingLab;
      case BusinessType.surveyor:
        return En.directoryTypeSurveyor;
      case BusinessType.contractor:
        return En.directoryTypeContractor;
      case BusinessType.materialShop:
        return En.directoryTypeMaterialShop;
      case BusinessType.consultantOffice:
        return En.directoryTypeConsultantOffice;
      case BusinessType.other:
        return En.directoryTypeOther;
    }
  }

  /// Display label resolved by the current UI language.
  static String labelFor(BusinessType type, {required bool isArabic}) =>
      isArabic ? arLabel(type) : enLabel(type);

  /// Presentation icon (display-only; never identity/routes/queries).
  static IconData iconFor(BusinessType type) {
    switch (type) {
      case BusinessType.supplier:
        return Icons.local_shipping;
      case BusinessType.technician:
        return Icons.handyman;
      case BusinessType.equipmentOwner:
        return Icons.precision_manufacturing;
      case BusinessType.engineeringOffice:
        return Icons.design_services;
      case BusinessType.constructionCompany:
        return Icons.apartment;
      case BusinessType.buildingOffice:
        return Icons.home_work;
      case BusinessType.testingLab:
        return Icons.science;
      case BusinessType.surveyor:
        return Icons.straighten;
      case BusinessType.contractor:
        return Icons.engineering;
      case BusinessType.materialShop:
        return Icons.storefront;
      case BusinessType.consultantOffice:
        return Icons.support_agent;
      case BusinessType.other:
        return Icons.more_horiz;
    }
  }
}
