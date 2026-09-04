// اختبار وحدة لحفظ/قراءة إعدادَي طريقة عرض المصحف من SharedPreferences —
// نفس نهج `widget_test.dart` (SharedPreferences.setMockInitialValues +
// override لـ`sharedPreferencesProvider` بـProviderContainer بدل تشغيل
// ودجت كاملة، أخفّ وأنسب لاختبار Notifier وحده).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:humam_app/core/data/user/user_prefs.dart';
import 'package:humam_app/features/mushaf/mushaf_settings.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  group('MushafDisplayModeNotifier', () {
    test('الافتراضي نص حي بلا أي حفظ سابق', () {
      expect(container.read(mushafDisplayModeProvider), MushafDisplayMode.liveText);
    });

    test('set يحفظ ويُقرأ صحيحاً من حاوية جديدة (يحاكي إعادة تشغيل التطبيق)', () {
      container.read(mushafDisplayModeProvider.notifier).set(MushafDisplayMode.rasterImage);
      expect(container.read(mushafDisplayModeProvider), MushafDisplayMode.rasterImage);

      final freshContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider))],
      );
      addTearDown(freshContainer.dispose);
      expect(container.read(mushafDisplayModeProvider), MushafDisplayMode.rasterImage);
      expect(freshContainer.read(mushafDisplayModeProvider), MushafDisplayMode.rasterImage);
    });
  });

  group('RasterMushafEditionNotifier', () {
    test('الافتراضي normal بلا أي حفظ سابق', () {
      expect(container.read(rasterMushafEditionProvider), RasterMushafEdition.normal);
    });

    test('set يحفظ id النسخة ويُقرأ صحيحاً لاحقاً', () {
      container.read(rasterMushafEditionProvider.notifier).set(RasterMushafEdition.premium);
      expect(container.read(rasterMushafEditionProvider), RasterMushafEdition.premium);

      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString('raster_mushaf_edition'), 'premium');
    });

    test('قيمة محفوظة غير معروفة (بيانات تالفة) تسقط للافتراضي normal بلا كراش', () async {
      SharedPreferences.setMockInitialValues({'raster_mushaf_edition': 'not_a_real_edition'});
      final prefs = await SharedPreferences.getInstance();
      final corrupted = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(corrupted.dispose);

      expect(corrupted.read(rasterMushafEditionProvider), RasterMushafEdition.normal);
    });
  });
}
