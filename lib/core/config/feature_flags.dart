/// A class to hold feature flags for the application.
///
/// This implementation prefers a runtime-checkable flag instead of a compile-time
/// `const` so tests and deployment scripts can toggle behavior without a
/// full rebuild. The value is resolved in this order:
///  1. Test/runtime override via `setForTests(bool)`.
///  2. Environment variable `USE_DYNAMIC_ATTRIBUTES` (true/1/yes -> true).
///  3. Default `false`.
library;

import 'dart:io';

class FeatureFlags {
  static bool? _overrideValue;

  /// Returns whether to use the dynamic attributes system.
  static bool get useDynamicAttributes {
    if (_overrideValue != null) return _overrideValue!;
    final env = Platform.environment['USE_DYNAMIC_ATTRIBUTES'];
    if (env != null) {
      final v = env.toLowerCase();
      if (v == '1' || v == 'true' || v == 'yes') return true;
      return false;
    }
    return true; // تم تفعيل إدارة خصائص المنتج افتراضياً
  }

  /// Backwards-compatible setter used in tests and existing code that assigns
  /// `FeatureFlags.useDynamicAttributes = true;`.
  static set useDynamicAttributes(bool value) {
    _overrideValue = value;
  }

  /// Set the flag for tests or runtime toggles. Call `clearOverride()` to
  /// revert to environment/default behavior.
  static void setForTests(bool value) => _overrideValue = value;
  static void clearOverride() => _overrideValue = null;
}
