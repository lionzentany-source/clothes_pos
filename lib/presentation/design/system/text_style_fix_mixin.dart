import 'package:flutter/cupertino.dart';

/// Ensures any externally provided TextStyle has inherit:true before animations.
TextStyle ensureInherit(TextStyle style) {
  if (style.inherit == true) return style;
  return style.copyWith(inherit: true);
}
