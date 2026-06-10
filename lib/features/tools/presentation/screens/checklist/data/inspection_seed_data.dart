import 'package:flutter/material.dart';
import '../models/inspection_category.dart';
import '../models/inspection_item.dart';

const List<InspectionCategory> kCategories = [
  InspectionCategory(
    id: 'concrete',
    titleKey: 'catConcrete',
    icon: Icons.architecture,
    accentColor: Color(0xFF1565C0),
    order: 1,
  ),
  InspectionCategory(
    id: 'reinforcement',
    titleKey: 'catReinforcement',
    icon: Icons.build,
    accentColor: Color(0xFFE53935),
    order: 2,
  ),
  InspectionCategory(
    id: 'masonry',
    titleKey: 'catMasonry',
    icon: Icons.grid_view,
    accentColor: Color(0xFF8D6E63),
    order: 3,
  ),
  InspectionCategory(
    id: 'plastering',
    titleKey: 'catPlastering',
    icon: Icons.format_paint,
    accentColor: Color(0xFFFF8F00),
    order: 4,
  ),
  InspectionCategory(
    id: 'tiles',
    titleKey: 'catTiles',
    icon: Icons.grid_on,
    accentColor: Color(0xFF43A047),
    order: 5,
  ),
  InspectionCategory(
    id: 'waterproofing',
    titleKey: 'catWaterproofing',
    icon: Icons.water_drop,
    accentColor: Color(0xFF00838F),
    order: 6,
  ),
  InspectionCategory(
    id: 'painting',
    titleKey: 'catPainting',
    icon: Icons.brush,
    accentColor: Color(0xFF6A1B9A),
    order: 7,
  ),
  InspectionCategory(
    id: 'excavation',
    titleKey: 'catExcavation',
    icon: Icons.terrain,
    accentColor: Color(0xFF4E342E),
    order: 8,
  ),
  InspectionCategory(
    id: 'asphalt',
    titleKey: 'catAsphalt',
    icon: Icons.route,
    accentColor: Color(0xFF37474F),
    order: 9,
  ),
  InspectionCategory(
    id: 'mep',
    titleKey: 'catMep',
    icon: Icons.electrical_services,
    accentColor: Color(0xFFF57C00),
    order: 10,
  ),
  InspectionCategory(
    id: 'safety',
    titleKey: 'catSafety',
    icon: Icons.shield,
    accentColor: Color(0xFF2E7D32),
    order: 11,
  ),
];

List<InspectionItem> kItemsForCategory(String categoryId) {
  return switch (categoryId) {
    'concrete' => [..._concreteItems],
    'reinforcement' => [..._reinforcementItems],
    'masonry' => [..._masonryItems],
    'plastering' => [..._plasteringItems],
    'tiles' => [..._tileItems],
    'waterproofing' => [..._waterproofingItems],
    'painting' => [..._paintingItems],
    'excavation' => [..._excavationItems],
    'asphalt' => [..._asphaltItems],
    'mep' => [..._mepItems],
    'safety' => [..._safetyItems],
    _ => [],
  };
}

// ── Concrete Works (14 items) ──
final List<InspectionItem> _concreteItems = [
  InspectionItem(id: 'CONC-01', categoryId: 'concrete', titleKey: 'itemConc01', descriptionKey: 'itemConc01D', isRequired: true, isCritical: true, codeRef: 'ASTM C143'),
  InspectionItem(id: 'CONC-02', categoryId: 'concrete', titleKey: 'itemConc02', descriptionKey: 'itemConc02D', isRequired: true, isCritical: true, codeRef: 'ASTM C39'),
  InspectionItem(id: 'CONC-03', categoryId: 'concrete', titleKey: 'itemConc03', descriptionKey: 'itemConc03D', isRequired: true, isCritical: true, codeRef: 'ACI 309R'),
  InspectionItem(id: 'CONC-04', categoryId: 'concrete', titleKey: 'itemConc04', isRequired: true, isCritical: false),
  InspectionItem(id: 'CONC-05', categoryId: 'concrete', titleKey: 'itemConc05', descriptionKey: 'itemConc05D', isRequired: true, isCritical: true, codeRef: 'ACI 318 §20.6'),
  InspectionItem(id: 'CONC-06', categoryId: 'concrete', titleKey: 'itemConc06', isRequired: true, isCritical: false),
  InspectionItem(id: 'CONC-07', categoryId: 'concrete', titleKey: 'itemConc07', descriptionKey: 'itemConc07D', isRequired: true, isCritical: true, codeRef: 'ACI 304R'),
  InspectionItem(id: 'CONC-08', categoryId: 'concrete', titleKey: 'itemConc08', isRequired: false, isCritical: false),
  InspectionItem(id: 'CONC-09', categoryId: 'concrete', titleKey: 'itemConc09', descriptionKey: 'itemConc09D', isRequired: false, isCritical: true, codeRef: 'ACI 305R'),
  InspectionItem(id: 'CONC-10', categoryId: 'concrete', titleKey: 'itemConc10', isRequired: true, isCritical: false),
  InspectionItem(id: 'CONC-11', categoryId: 'concrete', titleKey: 'itemConc11', isRequired: true, isCritical: false),
  InspectionItem(id: 'CONC-12', categoryId: 'concrete', titleKey: 'itemConc12', isRequired: false, isCritical: false),
  InspectionItem(id: 'CONC-13', categoryId: 'concrete', titleKey: 'itemConc13', descriptionKey: 'itemConc13D', isRequired: false, isCritical: true, codeRef: 'ACI 304R'),
  InspectionItem(id: 'CONC-14', categoryId: 'concrete', titleKey: 'itemConc14', isRequired: false, isCritical: false),
];

// ── Reinforcement Works (12 items) ──
final List<InspectionItem> _reinforcementItems = [
  InspectionItem(id: 'REINF-01', categoryId: 'reinforcement', titleKey: 'itemReinf01', isRequired: true, isCritical: false, codeRef: 'ASTM A615'),
  InspectionItem(id: 'REINF-02', categoryId: 'reinforcement', titleKey: 'itemReinf02', descriptionKey: 'itemReinf02D', isRequired: true, isCritical: true, codeRef: 'ASTM A615 §6'),
  InspectionItem(id: 'REINF-03', categoryId: 'reinforcement', titleKey: 'itemReinf03', descriptionKey: 'itemReinf03D', isRequired: true, isCritical: true, codeRef: 'ACI 318 §25.2'),
  InspectionItem(id: 'REINF-04', categoryId: 'reinforcement', titleKey: 'itemReinf04', descriptionKey: 'itemReinf04D', isRequired: true, isCritical: true, codeRef: 'ACI 318 §25.5'),
  InspectionItem(id: 'REINF-05', categoryId: 'reinforcement', titleKey: 'itemReinf05', descriptionKey: 'itemReinf05D', isRequired: true, isCritical: true, codeRef: 'ACI 318 §25.3'),
  InspectionItem(id: 'REINF-06', categoryId: 'reinforcement', titleKey: 'itemReinf06', descriptionKey: 'itemReinf06D', isRequired: true, isCritical: true, codeRef: 'ACI 318 §20.6'),
  InspectionItem(id: 'REINF-07', categoryId: 'reinforcement', titleKey: 'itemReinf07', isRequired: true, isCritical: false),
  InspectionItem(id: 'REINF-08', categoryId: 'reinforcement', titleKey: 'itemReinf08', descriptionKey: 'itemReinf08D', isRequired: true, isCritical: true, codeRef: 'ACI 318 §9.6'),
  InspectionItem(id: 'REINF-09', categoryId: 'reinforcement', titleKey: 'itemReinf09', descriptionKey: 'itemReinf09D', isRequired: true, isCritical: true, codeRef: 'ACI 318 §25.7'),
  InspectionItem(id: 'REINF-10', categoryId: 'reinforcement', titleKey: 'itemReinf10', isRequired: true, isCritical: false),
  InspectionItem(id: 'REINF-11', categoryId: 'reinforcement', titleKey: 'itemReinf11', isRequired: false, isCritical: false),
  InspectionItem(id: 'REINF-12', categoryId: 'reinforcement', titleKey: 'itemReinf12', isRequired: false, isCritical: false),
];

// ── Masonry (8 items) ──
final List<InspectionItem> _masonryItems = [
  InspectionItem(id: 'MAS-01', categoryId: 'masonry', titleKey: 'itemMas01', isRequired: true, isCritical: true),
  InspectionItem(id: 'MAS-02', categoryId: 'masonry', titleKey: 'itemMas02', isRequired: true, isCritical: true),
  InspectionItem(id: 'MAS-03', categoryId: 'masonry', titleKey: 'itemMas03', descriptionKey: 'itemMas03D', isRequired: true, isCritical: true, codeRef: 'Iraqi Code §9'),
  InspectionItem(id: 'MAS-04', categoryId: 'masonry', titleKey: 'itemMas04', isRequired: true, isCritical: false),
  InspectionItem(id: 'MAS-05', categoryId: 'masonry', titleKey: 'itemMas05', isRequired: true, isCritical: false),
  InspectionItem(id: 'MAS-06', categoryId: 'masonry', titleKey: 'itemMas06', isRequired: false, isCritical: false),
  InspectionItem(id: 'MAS-07', categoryId: 'masonry', titleKey: 'itemMas07', isRequired: false, isCritical: false),
  InspectionItem(id: 'MAS-08', categoryId: 'masonry', titleKey: 'itemMas08', isRequired: false, isCritical: false),
];

// ── Plastering (8 items) ──
final List<InspectionItem> _plasteringItems = [
  InspectionItem(id: 'PLAS-01', categoryId: 'plastering', titleKey: 'itemPlas01', descriptionKey: 'itemPlas01D', isRequired: true, isCritical: true, codeRef: 'BS 5262'),
  InspectionItem(id: 'PLAS-02', categoryId: 'plastering', titleKey: 'itemPlas02', isRequired: true, isCritical: true),
  InspectionItem(id: 'PLAS-03', categoryId: 'plastering', titleKey: 'itemPlas03', isRequired: true, isCritical: false),
  InspectionItem(id: 'PLAS-04', categoryId: 'plastering', titleKey: 'itemPlas04', isRequired: true, isCritical: false),
  InspectionItem(id: 'PLAS-05', categoryId: 'plastering', titleKey: 'itemPlas05', isRequired: false, isCritical: false),
  InspectionItem(id: 'PLAS-06', categoryId: 'plastering', titleKey: 'itemPlas06', isRequired: false, isCritical: false),
  InspectionItem(id: 'PLAS-07', categoryId: 'plastering', titleKey: 'itemPlas07', isRequired: false, isCritical: false),
  InspectionItem(id: 'PLAS-08', categoryId: 'plastering', titleKey: 'itemPlas08', isRequired: false, isCritical: false),
];

// ── Tiles (8 items) ──
final List<InspectionItem> _tileItems = [
  InspectionItem(id: 'TILE-01', categoryId: 'tiles', titleKey: 'itemTile01', isRequired: true, isCritical: true),
  InspectionItem(id: 'TILE-02', categoryId: 'tiles', titleKey: 'itemTile02', isRequired: true, isCritical: true),
  InspectionItem(id: 'TILE-03', categoryId: 'tiles', titleKey: 'itemTile03', isRequired: true, isCritical: false),
  InspectionItem(id: 'TILE-04', categoryId: 'tiles', titleKey: 'itemTile04', isRequired: true, isCritical: false),
  InspectionItem(id: 'TILE-05', categoryId: 'tiles', titleKey: 'itemTile05', isRequired: true, isCritical: false),
  InspectionItem(id: 'TILE-06', categoryId: 'tiles', titleKey: 'itemTile06', isRequired: false, isCritical: false),
  InspectionItem(id: 'TILE-07', categoryId: 'tiles', titleKey: 'itemTile07', isRequired: false, isCritical: false),
  InspectionItem(id: 'TILE-08', categoryId: 'tiles', titleKey: 'itemTile08', isRequired: false, isCritical: false),
];

// ── Waterproofing (9 items) ──
final List<InspectionItem> _waterproofingItems = [
  InspectionItem(id: 'WPR-01', categoryId: 'waterproofing', titleKey: 'itemWpr01', descriptionKey: 'itemWpr01D', isRequired: true, isCritical: true, codeRef: 'ACI 515.1R'),
  InspectionItem(id: 'WPR-02', categoryId: 'waterproofing', titleKey: 'itemWpr02', isRequired: true, isCritical: true),
  InspectionItem(id: 'WPR-03', categoryId: 'waterproofing', titleKey: 'itemWpr03', isRequired: true, isCritical: true),
  InspectionItem(id: 'WPR-04', categoryId: 'waterproofing', titleKey: 'itemWpr04', isRequired: true, isCritical: true),
  InspectionItem(id: 'WPR-05', categoryId: 'waterproofing', titleKey: 'itemWpr05', isRequired: true, isCritical: true),
  InspectionItem(id: 'WPR-06', categoryId: 'waterproofing', titleKey: 'itemWpr06', isRequired: true, isCritical: false),
  InspectionItem(id: 'WPR-07', categoryId: 'waterproofing', titleKey: 'itemWpr07', isRequired: false, isCritical: false),
  InspectionItem(id: 'WPR-08', categoryId: 'waterproofing', titleKey: 'itemWpr08', isRequired: false, isCritical: false),
  InspectionItem(id: 'WPR-09', categoryId: 'waterproofing', titleKey: 'itemWpr09', isRequired: true, isCritical: false),
];

// ── Painting (6 items) ──
final List<InspectionItem> _paintingItems = [
  InspectionItem(id: 'PAINT-01', categoryId: 'painting', titleKey: 'itemPaint01', descriptionKey: 'itemPaint01D', isRequired: true, isCritical: true, codeRef: 'BS 6150'),
  InspectionItem(id: 'PAINT-02', categoryId: 'painting', titleKey: 'itemPaint02', isRequired: true, isCritical: false),
  InspectionItem(id: 'PAINT-03', categoryId: 'painting', titleKey: 'itemPaint03', isRequired: false, isCritical: false),
  InspectionItem(id: 'PAINT-04', categoryId: 'painting', titleKey: 'itemPaint04', isRequired: true, isCritical: false),
  InspectionItem(id: 'PAINT-05', categoryId: 'painting', titleKey: 'itemPaint05', isRequired: false, isCritical: false),
  InspectionItem(id: 'PAINT-06', categoryId: 'painting', titleKey: 'itemPaint06', isRequired: false, isCritical: false),
];

// ── Excavation & Soil (10 items) ──
final List<InspectionItem> _excavationItems = [
  InspectionItem(id: 'EXC-01', categoryId: 'excavation', titleKey: 'itemExc01', descriptionKey: 'itemExc01D', isRequired: true, isCritical: true, codeRef: 'ACI 336'),
  InspectionItem(id: 'EXC-02', categoryId: 'excavation', titleKey: 'itemExc02', isRequired: true, isCritical: true),
  InspectionItem(id: 'EXC-03', categoryId: 'excavation', titleKey: 'itemExc03', isRequired: true, isCritical: true),
  InspectionItem(id: 'EXC-04', categoryId: 'excavation', titleKey: 'itemExc04', isRequired: true, isCritical: true),
  InspectionItem(id: 'EXC-05', categoryId: 'excavation', titleKey: 'itemExc05', isRequired: true, isCritical: false),
  InspectionItem(id: 'EXC-06', categoryId: 'excavation', titleKey: 'itemExc06', isRequired: true, isCritical: false),
  InspectionItem(id: 'EXC-07', categoryId: 'excavation', titleKey: 'itemExc07', isRequired: false, isCritical: false),
  InspectionItem(id: 'EXC-08', categoryId: 'excavation', titleKey: 'itemExc08', isRequired: true, isCritical: false),
  InspectionItem(id: 'EXC-09', categoryId: 'excavation', titleKey: 'itemExc09', isRequired: true, isCritical: true),
  InspectionItem(id: 'EXC-10', categoryId: 'excavation', titleKey: 'itemExc10', isRequired: true, isCritical: false),
];

// ── Asphalt (8 items) ──
final List<InspectionItem> _asphaltItems = [
  InspectionItem(id: 'ASPH-01', categoryId: 'asphalt', titleKey: 'itemAsph01', descriptionKey: 'itemAsph01D', isRequired: true, isCritical: true, codeRef: 'AASHTO T245'),
  InspectionItem(id: 'ASPH-02', categoryId: 'asphalt', titleKey: 'itemAsph02', descriptionKey: 'itemAsph02D', isRequired: true, isCritical: true, codeRef: 'ASTM D6927'),
  InspectionItem(id: 'ASPH-03', categoryId: 'asphalt', titleKey: 'itemAsph03', isRequired: true, isCritical: true),
  InspectionItem(id: 'ASPH-04', categoryId: 'asphalt', titleKey: 'itemAsph04', isRequired: true, isCritical: false),
  InspectionItem(id: 'ASPH-05', categoryId: 'asphalt', titleKey: 'itemAsph05', isRequired: true, isCritical: false),
  InspectionItem(id: 'ASPH-06', categoryId: 'asphalt', titleKey: 'itemAsph06', isRequired: true, isCritical: false),
  InspectionItem(id: 'ASPH-07', categoryId: 'asphalt', titleKey: 'itemAsph07', isRequired: false, isCritical: false),
  InspectionItem(id: 'ASPH-08', categoryId: 'asphalt', titleKey: 'itemAsph08', isRequired: false, isCritical: false),
];

// ── MEP (10 items) ──
final List<InspectionItem> _mepItems = [
  InspectionItem(id: 'MEP-01', categoryId: 'mep', titleKey: 'itemMep01', isRequired: true, isCritical: true),
  InspectionItem(id: 'MEP-02', categoryId: 'mep', titleKey: 'itemMep02', isRequired: true, isCritical: true),
  InspectionItem(id: 'MEP-03', categoryId: 'mep', titleKey: 'itemMep03', isRequired: true, isCritical: false),
  InspectionItem(id: 'MEP-04', categoryId: 'mep', titleKey: 'itemMep04', isRequired: true, isCritical: false),
  InspectionItem(id: 'MEP-05', categoryId: 'mep', titleKey: 'itemMep05', isRequired: true, isCritical: true),
  InspectionItem(id: 'MEP-06', categoryId: 'mep', titleKey: 'itemMep06', isRequired: true, isCritical: false),
  InspectionItem(id: 'MEP-07', categoryId: 'mep', titleKey: 'itemMep07', isRequired: false, isCritical: false),
  InspectionItem(id: 'MEP-08', categoryId: 'mep', titleKey: 'itemMep08', isRequired: false, isCritical: false),
  InspectionItem(id: 'MEP-09', categoryId: 'mep', titleKey: 'itemMep09', isRequired: true, isCritical: true),
  InspectionItem(id: 'MEP-10', categoryId: 'mep', titleKey: 'itemMep10', isRequired: false, isCritical: false),
];

// ── Safety (10 items) ──
final List<InspectionItem> _safetyItems = [
  InspectionItem(id: 'SAFE-01', categoryId: 'safety', titleKey: 'itemSafe01', isRequired: true, isCritical: true, codeRef: 'OSHA'),
  InspectionItem(id: 'SAFE-02', categoryId: 'safety', titleKey: 'itemSafe02', isRequired: true, isCritical: true),
  InspectionItem(id: 'SAFE-03', categoryId: 'safety', titleKey: 'itemSafe03', isRequired: true, isCritical: true),
  InspectionItem(id: 'SAFE-04', categoryId: 'safety', titleKey: 'itemSafe04', isRequired: true, isCritical: true),
  InspectionItem(id: 'SAFE-05', categoryId: 'safety', titleKey: 'itemSafe05', isRequired: true, isCritical: false),
  InspectionItem(id: 'SAFE-06', categoryId: 'safety', titleKey: 'itemSafe06', isRequired: true, isCritical: false),
  InspectionItem(id: 'SAFE-07', categoryId: 'safety', titleKey: 'itemSafe07', isRequired: true, isCritical: false),
  InspectionItem(id: 'SAFE-08', categoryId: 'safety', titleKey: 'itemSafe08', isRequired: true, isCritical: true),
  InspectionItem(id: 'SAFE-09', categoryId: 'safety', titleKey: 'itemSafe09', isRequired: false, isCritical: false),
  InspectionItem(id: 'SAFE-10', categoryId: 'safety', titleKey: 'itemSafe10', isRequired: false, isCritical: false),
];
