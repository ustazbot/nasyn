import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/i18n/app_locale.dart';

void main() {
  test('defaults to AppLocale.bm', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(appLocaleProvider), AppLocale.bm);
  });

  test('can be toggled to en', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appLocaleProvider.notifier).state = AppLocale.en;
    expect(container.read(appLocaleProvider), AppLocale.en);
  });
}
