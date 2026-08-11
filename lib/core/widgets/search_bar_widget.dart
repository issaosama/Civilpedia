import 'package:flutter/material.dart';
import '../../localization/ar.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: Ar.search,
        hintStyle: TextStyle(color: const Color(0xFFF0ECE2).withValues(alpha: 0.6)),
        prefixIcon: Icon(Icons.search, color: const Color(0xFFF0ECE2).withValues(alpha: 0.7)),
        filled: true,
        fillColor: const Color(0xFFF0ECE2).withValues(alpha: 0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      style: const TextStyle(color: Color(0xFFF0ECE2)),
    );
  }
}
