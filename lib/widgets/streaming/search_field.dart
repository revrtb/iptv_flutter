import 'package:flutter/material.dart';

/// Styled search field for list/category screens.
class StreamingSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  const StreamingSearchField({
    super.key,
    required this.controller,
    this.label = 'Search',
    this.hint = 'Filter...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
          isDense: true,
        ),
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}
