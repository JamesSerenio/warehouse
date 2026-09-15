import 'package:flutter/material.dart';

abstract final class AppAnimationDurations {
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 200);
  static const modal = Duration(milliseconds: 250);
  static const press = Duration(milliseconds: 100);
}

abstract final class AppAnimationCurves {
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubic;
  static const modal = Curves.easeOutCubic;
}
