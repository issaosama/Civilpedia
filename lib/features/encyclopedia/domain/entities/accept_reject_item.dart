class AcceptRejectItem {
  final String criteriaAr;
  final String? criteriaEn;
  final String? acceptanceLimitAr;
  final String? acceptanceLimitEn;
  final String? methodAr;
  final String? methodEn;
  final bool isCritical;

  const AcceptRejectItem({
    required this.criteriaAr,
    this.criteriaEn,
    this.acceptanceLimitAr,
    this.acceptanceLimitEn,
    this.methodAr,
    this.methodEn,
    this.isCritical = false,
  });

  Map<String, dynamic> toJson() => {
        'criteriaAr': criteriaAr,
        'criteriaEn': criteriaEn,
        'acceptanceLimitAr': acceptanceLimitAr,
        'acceptanceLimitEn': acceptanceLimitEn,
        'methodAr': methodAr,
        'methodEn': methodEn,
        'isCritical': isCritical,
      };

  factory AcceptRejectItem.fromJson(Map<String, dynamic> json) =>
      AcceptRejectItem(
        criteriaAr: json['criteriaAr'] as String,
        criteriaEn: json['criteriaEn'] as String?,
        acceptanceLimitAr: json['acceptanceLimitAr'] as String?,
        acceptanceLimitEn: json['acceptanceLimitEn'] as String?,
        methodAr: json['methodAr'] as String?,
        methodEn: json['methodEn'] as String?,
        isCritical: json['isCritical'] as bool? ?? false,
      );
}
