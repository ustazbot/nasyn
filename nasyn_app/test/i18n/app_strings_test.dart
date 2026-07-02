import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/i18n/app_locale.dart';
import 'package:nasyn_app/i18n/app_strings.dart';

void main() {
  test('returns the BM string for a known key', () {
    expect(AppStrings.of('mula', AppLocale.bm), 'MULA');
  });

  test('returns the EN string for the same key', () {
    expect(AppStrings.of('mula', AppLocale.en), 'START');
  });

  test('falls back to the key itself for an unknown key', () {
    expect(AppStrings.of('nonexistentKey', AppLocale.bm), 'nonexistentKey');
  });
}
