import 'package:flutter/material.dart';

import '../../../localization/ar.dart';
import '../../../localization/en.dart';

/// V1-R05 — Presentation-only metadata for the 9 canonical cloud
/// `directory_entities.entity_type` values.
///
/// Maps the canonical DB string codes to localized display labels and
/// presentation icons. This is the canonical Directory type vocabulary;
/// legacy [DirectoryCategoryPresentation] using [BusinessType] remains
/// only for legacy/compat presentation outside the production Directory path.
abstract final class CanonicalEntityTypePresentation {
  /// Canonical entity-type display order for the Landing grid.
  static const List<String> orderedTypes = [
    'company',
    'engineering_office',
    'contractor',
    'supplier',
    'store',
    'technician',
    'laboratory',
    'equipment_provider',
    'service_provider',
  ];

  /// Arabic display label for a canonical entity_type.
  static String arLabel(String entityType) {
    switch (entityType) {
      case 'company':
        return Ar.directoryTypeConstructionCompany;
      case 'engineering_office':
        return Ar.directoryTypeEngineeringOffice;
      case 'contractor':
        return Ar.directoryTypeContractor;
      case 'supplier':
        return Ar.directoryTypeSupplier;
      case 'store':
        return Ar.directoryTypeMaterialShop;
      case 'technician':
        return Ar.directoryTypeTechnician;
      case 'laboratory':
        return Ar.directoryTypeTestingLab;
      case 'equipment_provider':
        return Ar.directoryTypeEquipmentOwner;
      case 'service_provider':
        return Ar.directoryTypeConsultantOffice;
      default:
        return Ar.directoryTypeOther;
    }
  }

  /// English display label for a canonical entity_type.
  static String enLabel(String entityType) {
    switch (entityType) {
      case 'company':
        return En.directoryTypeConstructionCompany;
      case 'engineering_office':
        return En.directoryTypeEngineeringOffice;
      case 'contractor':
        return En.directoryTypeContractor;
      case 'supplier':
        return En.directoryTypeSupplier;
      case 'store':
        return En.directoryTypeMaterialShop;
      case 'technician':
        return En.directoryTypeTechnician;
      case 'laboratory':
        return En.directoryTypeTestingLab;
      case 'equipment_provider':
        return En.directoryTypeEquipmentOwner;
      case 'service_provider':
        return En.directoryTypeConsultantOffice;
      default:
        return En.directoryTypeOther;
    }
  }

  /// Display label resolved by the current UI language.
  static String labelFor(String entityType, {required bool isArabic}) =>
      isArabic ? arLabel(entityType) : enLabel(entityType);

  /// Presentation icon for a canonical entity_type.
  static IconData iconFor(String entityType) {
    switch (entityType) {
      case 'company':
        return Icons.apartment;
      case 'engineering_office':
        return Icons.design_services;
      case 'contractor':
        return Icons.engineering;
      case 'supplier':
        return Icons.local_shipping;
      case 'store':
        return Icons.storefront;
      case 'technician':
        return Icons.handyman;
      case 'laboratory':
        return Icons.science;
      case 'equipment_provider':
        return Icons.precision_manufacturing;
      case 'service_provider':
        return Icons.support_agent;
      default:
        return Icons.more_horiz;
    }
  }
}
