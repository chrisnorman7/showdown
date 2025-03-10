import 'package:flutter/material.dart';

/// The warning button.
class WarningButton extends StatelessWidget {
  /// Create an instance.
  const WarningButton({
    required this.addWarning,
    required this.firstWarning,
    super.key,
  });

  /// The function to call to add the warning.
  final VoidCallback addWarning;

  /// Whether the player is on their first warning or not.
  final bool firstWarning;

  /// Build the widget.
  @override
  Widget build(final BuildContext context) => Semantics(
    checked: firstWarning,
    child: IconButton(
      onPressed: addWarning,
      icon: Icon(
        Icons.warning,
        semanticLabel: 'Issue warning',
        color: firstWarning ? Colors.yellow : Colors.grey,
      ),
    ),
  );
}
