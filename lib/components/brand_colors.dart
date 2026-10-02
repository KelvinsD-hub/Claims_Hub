import 'package:flutter/material.dart';

/// Brand colours that have to stay readable on both themes. The navy the app
/// was designed with is close to invisible on the dark background, so text
/// and icons use these instead of the raw colour.

/// The brand blue, lightened on the dark theme.
Color brandBlue(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF7DB4F0)
        : const Color(0xFF0C519B);

/// Red for something late or missing, readable on either theme.
Color overdueRed(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF8A80)
        : const Color(0xFFC62828);
