import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../localization/ar.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final List<_ChecklistItem> _items = [
    _ChecklistItem('فحص المخططات والرسومات'),
    _ChecklistItem('فحص أعمال الحفر والردم'),
    _ChecklistItem('فحص صب الخرسانة'),
    _ChecklistItem('فحص أعمال التسليح'),
    _ChecklistItem('فحص أعمال العزل'),
    _ChecklistItem('فحص أعمال اللياسة'),
    _ChecklistItem('فحص أعمال السباكة'),
    _ChecklistItem('فحص أعمال الكهرباء'),
    _ChecklistItem('فحص أعمال الدهان'),
    _ChecklistItem('فحص أعمال البلاط'),
  ];

  @override
  Widget build(BuildContext context) {
    final done = _items.where((i) => i.isDone).length;
    return Scaffold(
      appBar: AppBar(title: Text(Ar.siteChecklist)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          CustomCard(
            child: Column(
              children: [
                Text(
                  '$done/${_items.length}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Ar.siteChecklist,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _items.isEmpty ? 0 : done / _items.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._items.map((item) => _buildItem(item)),
        ],
      ),
    );
  }

  Widget _buildItem(_ChecklistItem item) {
    return CheckboxListTile(
      title: Text(item.title),
      value: item.isDone,
      onChanged: (value) {
        setState(() => item.isDone = value ?? false);
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _ChecklistItem {
  final String title;
  bool isDone;

  _ChecklistItem(this.title, {bool? isDone}) : isDone = isDone ?? false;
}
