import 'package:flutter/material.dart';

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
          backgroundColor: Colors.blue[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}
