import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../domain/directory_entity_types.dart';

/// V1-R04 — Arabic-first display label for a canonical Directory Entity type.
///
/// The canonical `entity_type` storage value (migration 00005) is NEVER
/// displayed raw; it is resolved to the localized label here. Unknown values
/// fail safe to a neutral label — identity remains the canonical string.
abstract final class DirectoryEntityTypeLabels {
  static String labelFor(String? entityType, {required bool isArabic}) {
    switch (entityType) {
      case DirectoryEntityType.company:
        return isArabic
            ? Ar.businessEntityTypeCompany
            : En.businessEntityTypeCompany;
      case DirectoryEntityType.engineeringOffice:
        return isArabic
            ? Ar.businessEntityTypeEngineeringOffice
            : En.businessEntityTypeEngineeringOffice;
      case DirectoryEntityType.contractor:
        return isArabic
            ? Ar.businessEntityTypeContractor
            : En.businessEntityTypeContractor;
      case DirectoryEntityType.supplier:
        return isArabic ? Ar.businessEntityTypeSupplier : En.businessEntityTypeSupplier;
      case DirectoryEntityType.store:
        return isArabic ? Ar.businessEntityTypeStore : En.businessEntityTypeStore;
      case DirectoryEntityType.technician:
        return isArabic
            ? Ar.businessEntityTypeTechnician
            : En.businessEntityTypeTechnician;
      case DirectoryEntityType.laboratory:
        return isArabic
            ? Ar.businessEntityTypeLaboratory
            : En.businessEntityTypeLaboratory;
      case DirectoryEntityType.equipmentProvider:
        return isArabic
            ? Ar.businessEntityTypeEquipmentProvider
            : En.businessEntityTypeEquipmentProvider;
      case DirectoryEntityType.serviceProvider:
        return isArabic
            ? Ar.businessEntityTypeServiceProvider
            : En.businessEntityTypeServiceProvider;
      default:
        return isArabic ? Ar.businessStatusUnknown : En.businessStatusUnknown;
    }
  }
}