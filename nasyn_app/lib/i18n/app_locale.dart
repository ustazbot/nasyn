import 'package:flutter_riverpod/legacy.dart';

enum AppLocale { bm, en }

final appLocaleProvider = StateProvider<AppLocale>((ref) => AppLocale.bm);
