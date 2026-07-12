import 'package:flutter/material.dart';

/// Tighter layout for the operator app shell (role is typically "Operator").
bool isOperatorLayoutRole(String? role) {
  final r = role?.toLowerCase().trim() ?? '';
  return r.contains('operator');
}

/// Extra scroll extent so content clears [RootShell]’s BottomAppBar + center FAB.
double rootShellTabScrollBottomInset(BuildContext context,
    {required bool compact}) {
  final safe = MediaQuery.paddingOf(context).bottom;
  final core = compact ? 72.0 : 96.0;
  return core + safe;
}
