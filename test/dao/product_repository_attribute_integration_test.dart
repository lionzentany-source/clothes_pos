import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize sqflite_common_ffi so DatabaseHelper's global openDatabase works
    // in the test environment when using sqflite_common_ffi.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await setupLocator(registerAggregatedReports: false);
  });

  test(
    'ProductRepository exposes attribute repository when injected',
    () async {
      // Ensure feature flag is on for this integration sanity check
      FeatureFlags.useDynamicAttributes = true;
      final repo = sl<ProductRepository>();
      final attrs = await repo.getAllAttributes();
      // no DB seeded here; expect empty list but no crash
      expect(attrs, isA<List>());
    },
  );
}
