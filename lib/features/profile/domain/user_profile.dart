import '../../../core/location/baghdad_area.dart';
import '../../../core/schema/schema_constants.dart';

enum CivilUserType {
  siteEngineer,
  consultantEngineer,
  structuralEngineer,
  contractor,
  engineeringStudent,
  technicianSupervisor,
  supplierShopOwner,
  engineeringOffice,
  constructionCompany,
  buildingOffice,
  generalUser;
}

class LocalUserProfile {
  final String anonymousInstallId;
  final CivilUserType userType;
  final BaghdadArea baghdadArea;
  final String? name;
  final String? title;
  final String? company;
  final String? phone;
  final String? email;
  final String? logoPath;
  final String? futureCloudUserId;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalUserProfile({
    required this.anonymousInstallId,
    this.userType = CivilUserType.generalUser,
    this.baghdadArea = BaghdadArea.unknown,
    this.name,
    this.title,
    this.company,
    this.phone,
    this.email,
    this.logoPath,
    this.futureCloudUserId,
    this.schemaVersion = SchemaConstants.currentDataSchemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  LocalUserProfile copyWith({
    String? anonymousInstallId,
    CivilUserType? userType,
    BaghdadArea? baghdadArea,
    String? name,
    String? title,
    String? company,
    String? phone,
    String? email,
    String? logoPath,
    String? futureCloudUserId,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalUserProfile(
      anonymousInstallId: anonymousInstallId ?? this.anonymousInstallId,
      userType: userType ?? this.userType,
      baghdadArea: baghdadArea ?? this.baghdadArea,
      name: name ?? this.name,
      title: title ?? this.title,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoPath: logoPath ?? this.logoPath,
      futureCloudUserId: futureCloudUserId ?? this.futureCloudUserId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'anonymousInstallId': anonymousInstallId,
        'userType': userType.name,
        'baghdadArea': baghdadArea.name,
        'name': name,
        'title': title,
        'company': company,
        'phone': phone,
        'email': email,
        'logoPath': logoPath,
        'futureCloudUserId': futureCloudUserId,
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LocalUserProfile.fromJson(Map<String, dynamic> json) {
    return LocalUserProfile(
      anonymousInstallId: json['anonymousInstallId'] as String? ?? '',
      userType: CivilUserType.values.firstWhere(
        (e) => e.name == json['userType'],
        orElse: () => CivilUserType.generalUser,
      ),
      baghdadArea: BaghdadArea.values.firstWhere(
        (e) => e.name == json['baghdadArea'],
        orElse: () => BaghdadArea.unknown,
      ),
      name: json['name'] as String?,
      title: json['title'] as String?,
      company: json['company'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logoPath: json['logoPath'] as String?,
      futureCloudUserId: json['futureCloudUserId'] as String?,
      schemaVersion: json['schemaVersion'] as int? ??
          SchemaConstants.currentDataSchemaVersion,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
