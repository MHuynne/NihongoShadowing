import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelect;

  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          onPressed: () => onSelect(suggestion),
          backgroundColor: AppColors.lightPinkBackground,
          side: BorderSide(color: AppColors.toriiRed.withValues(alpha: 0.16)),
          labelStyle: const TextStyle(
            color: AppColors.toriiRed,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}
