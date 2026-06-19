enum BaghdadArea {
  unknown,
  adhamiya,
  amiriya,
  baya,
  dewanija,
  dora,
  ghazaliya,
  hurriya,
  jadriya,
  jamiya,
  kadhimiya,
  karrada,
  karkh,
  mahmudiya,
  mansour,
  qanat,
  rashid,
  rusafa,
  sadrCity,
  saydiya,
  shaab,
  shuala,
  yarmouk,
  zaFraniya,
  abuGhraib,
  taji,
  other;

  String get enName {
    switch (this) {
      case unknown:
        return '--';
      case adhamiya:
        return 'Adhamiya';
      case amiriya:
        return 'Amiriya';
      case baya:
        return 'Baya\'';
      case dewanija:
        return 'Dewanija';
      case dora:
        return 'Dora';
      case ghazaliya:
        return 'Ghazaliya';
      case hurriya:
        return 'Hurriya';
      case jadriya:
        return 'Jadriya';
      case jamiya:
        return 'Jami\'a';
      case kadhimiya:
        return 'Kadhimiya';
      case karrada:
        return 'Karrada';
      case karkh:
        return 'Karkh';
      case mahmudiya:
        return 'Mahmudiya';
      case mansour:
        return 'Mansour';
      case qanat:
        return 'Qanat';
      case rashid:
        return 'Rashid';
      case rusafa:
        return 'Rusafa';
      case sadrCity:
        return 'Sadr City';
      case saydiya:
        return 'Saydiya';
      case shaab:
        return 'Sha\'ab';
      case shuala:
        return 'Shu\'ala';
      case yarmouk:
        return 'Yarmouk';
      case zaFraniya:
        return 'Za\'franiya';
      case abuGhraib:
        return 'Abu Ghraib';
      case taji:
        return 'Taji';
      case other:
        return 'Other';
    }
  }

  String get arName {
    switch (this) {
      case unknown:
        return '--';
      case adhamiya:
        return 'الأعظمية';
      case amiriya:
        return 'عامرية';
      case baya:
        return 'بياع';
      case dewanija:
        return 'دوانيج';
      case dora:
        return 'دورة';
      case ghazaliya:
        return 'غزالية';
      case hurriya:
        return 'حرة';
      case jadriya:
        return 'جادرية';
      case jamiya:
        return 'جامعة';
      case kadhimiya:
        return 'كاظمية';
      case karrada:
        return 'كرادة';
      case karkh:
        return 'كرخ';
      case mahmudiya:
        return 'محمودية';
      case mansour:
        return 'منصور';
      case qanat:
        return 'قناة';
      case rashid:
        return 'رشيد';
      case rusafa:
        return 'رصافة';
      case sadrCity:
        return 'مدينة الصدر';
      case saydiya:
        return 'سيدية';
      case shaab:
        return 'شعب';
      case shuala:
        return 'شعلة';
      case yarmouk:
        return 'يرموك';
      case zaFraniya:
        return 'زعفرانية';
      case abuGhraib:
        return 'أبو غريب';
      case taji:
        return 'تاجي';
      case other:
        return 'أخرى';
    }
  }
}
