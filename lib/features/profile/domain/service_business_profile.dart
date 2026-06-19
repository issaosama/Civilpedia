import '../../../core/location/baghdad_area.dart';

enum BusinessType {
  supplier,
  technician,
  equipmentOwner,
  engineeringOffice,
  constructionCompany,
  buildingOffice,
  testingLab,
  surveyor,
  contractor,
  materialShop,
  consultantOffice,
  other;

  String get key {
    switch (this) {
      case supplier:
        return 'supplier';
      case technician:
        return 'technician';
      case equipmentOwner:
        return 'equipment_owner';
      case engineeringOffice:
        return 'engineering_office';
      case constructionCompany:
        return 'construction_company';
      case buildingOffice:
        return 'building_office';
      case testingLab:
        return 'testing_lab';
      case surveyor:
        return 'surveyor';
      case contractor:
        return 'contractor';
      case materialShop:
        return 'material_shop';
      case consultantOffice:
        return 'consultant_office';
      case other:
        return 'other';
    }
  }

  static BusinessType fromKey(String value) {
    return BusinessType.values.firstWhere(
      (e) => e.key == value,
      orElse: () => BusinessType.other,
    );
  }
}

enum VerificationStatus { unverified, pending, verified, rejected }

class ServiceBusinessProfile {
  final String id;
  final String name;
  final BusinessType type;
  final List<String> categories;
  final List<String> subCategories;
  final BaghdadArea baghdadArea;
  final String? address;
  final List<String> phones;
  final String? whatsapp;
  final String? description;
  final VerificationStatus verificationStatus;
  final bool featured;
  final bool foundingPartner;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? futureOwnerUserId;
  final String? planType;
  final int schemaVersion;

  ServiceBusinessProfile({
    required this.id,
    required this.name,
    required this.type,
    this.categories = const [],
    this.subCategories = const [],
    this.baghdadArea = BaghdadArea.unknown,
    this.address,
    this.phones = const [],
    this.whatsapp,
    this.description,
    this.verificationStatus = VerificationStatus.unverified,
    this.featured = false,
    this.foundingPartner = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.futureOwnerUserId,
    this.planType,
    this.schemaVersion = 1,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ServiceBusinessProfile copyWith({
    String? id,
    String? name,
    BusinessType? type,
    List<String>? categories,
    List<String>? subCategories,
    BaghdadArea? baghdadArea,
    String? address,
    List<String>? phones,
    String? whatsapp,
    String? description,
    VerificationStatus? verificationStatus,
    bool? featured,
    bool? foundingPartner,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? futureOwnerUserId,
    String? planType,
    int? schemaVersion,
  }) {
    return ServiceBusinessProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      categories: categories ?? this.categories,
      subCategories: subCategories ?? this.subCategories,
      baghdadArea: baghdadArea ?? this.baghdadArea,
      address: address ?? this.address,
      phones: phones ?? this.phones,
      whatsapp: whatsapp ?? this.whatsapp,
      description: description ?? this.description,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      featured: featured ?? this.featured,
      foundingPartner: foundingPartner ?? this.foundingPartner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      futureOwnerUserId: futureOwnerUserId ?? this.futureOwnerUserId,
      planType: planType ?? this.planType,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.key,
        'categories': categories,
        'subCategories': subCategories,
        'baghdadArea': baghdadArea.name,
        'address': address,
        'phones': phones,
        'whatsapp': whatsapp,
        'description': description,
        'verificationStatus': verificationStatus.name,
        'featured': featured,
        'foundingPartner': foundingPartner,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'futureOwnerUserId': futureOwnerUserId,
        'planType': planType,
        'schemaVersion': schemaVersion,
      };

  factory ServiceBusinessProfile.fromJson(Map<String, dynamic> json) {
    return ServiceBusinessProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: BusinessType.fromKey(json['type'] as String? ?? 'other'),
      categories: (json['categories'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      subCategories: (json['subCategories'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      baghdadArea: BaghdadArea.values.firstWhere(
        (e) => e.name == json['baghdadArea'],
        orElse: () => BaghdadArea.unknown,
      ),
      address: json['address'] as String?,
      phones:
          (json['phones'] as List<dynamic>?)?.cast<String>() ?? [],
      whatsapp: json['whatsapp'] as String?,
      description: json['description'] as String?,
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
        orElse: () => VerificationStatus.unverified,
      ),
      featured: json['featured'] as bool? ?? false,
      foundingPartner: json['foundingPartner'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      futureOwnerUserId: json['futureOwnerUserId'] as String?,
      planType: json['planType'] as String?,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }
}
