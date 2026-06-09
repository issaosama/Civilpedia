import 'package:flutter/material.dart';
import '../../localization/ar.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({super.key, this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: Ar.search,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}
