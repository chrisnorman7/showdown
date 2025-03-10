import 'package:flutter/material.dart';

/// An action which can be undone and redone.
class UndoableAction {
  /// Create an instance.
  const UndoableAction({
    required this.action,
    required this.undo,
    this.endPoint = true,
  });

  /// The action to perform.
  final VoidCallback action;

  /// The function to perform to undo [action].
  final VoidCallback undo;

  /// Whether or not this action should end a point.
  final bool endPoint;
}
