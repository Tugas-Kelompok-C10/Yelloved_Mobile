import 'package:flutter/material.dart';

/// Shared palette, matching the CSS tokens in the Yelloved website.
class AppColors {
  static const violet = Color(0xFF320C35);
  static const violetHover = Color(0xFF280A2A);
  static const success = Color(0xFF60CA6E);
  static const error = Color(0xFFE03232);
  static const lightPaper = Color(0xFFFEFDF9);
  static const paper = Color(0xFFFDFCF5);
  // Cream text for violet surfaces. Use violet for text on paper.
  static const text = Color(0xFFF2EEBF);
  static const textHover = Color(0xFFDAD6AC);
  static const border = Color(0xFFDAD6AC);
  static const violetLightHover = Color(0xFFE0DBE1);
  static const lightBlue = Color(0xFFE6F4F8);
  static const blue = Color(0xFFAEDAE7);
  static const blueHover = Color(0xFF8BAEB9);
  static const gray = Color(0xFF68838B);
  static const boardWood = Color(0xFFB68048);
  static const boardWoodDark = Color(0xFF8A5B32);
  static const boardCork = Color(0xFFD4AB77);
  static const boardCorkLight = Color(0xFFEDC897);
  static const boardGrain = Color(0xFFBB8E5C);

  static const gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [violet, Color(0xFF4F1353)],
  );
}
