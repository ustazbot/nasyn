import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_cue_resolver.dart';
import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../kiosk/session_guard.dart';
import '../prayer/prayer_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/responsive.dart';
import 'prayer_session_screen.dart';
import '../settings/settings_providers.dart';
import 'settings_screen.dart';
import 'surah_selection_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AssistanceLevel _selectedLevel = AssistanceLevel.fullRecite;

  @override
  void initState() {
    super.initState();
    // Persist "set sekali": pulihkan level terakhir dari prefs
    // (repo tiada dalam widget test — best-effort).
    try {
      _selectedLevel = ref
          .read(settingsRepositoryProvider)
          .readAssistanceLevel();
    } catch (_) {}
  }

  void _selectLevel(AssistanceLevel level) {
    setState(() => _selectedLevel = level);
    try {
      ref.read(settingsRepositoryProvider).saveAssistanceLevel(level);
    } catch (_) {}
  }

  // Elak mis-tap pilih solat salah — confirm dulu sebelum mula sesi.
  Future<void> _confirmStart(
    PrayerType type,
    PrayerConfig config,
    AppLocale locale,
  ) async {
    final start = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceMuted,
        title: Text(
          '${AppStrings.of('solat', locale)} ${config.displayName} — '
          '${AppStrings.of('startSession', locale)}',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.of('batal', locale),
              style: AppTextStyles.label,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppStrings.of('ya', locale),
              style: AppTextStyles.label.copyWith(color: AppColors.accentGreen),
            ),
          ),
        ],
      ),
    );

    if (start == true && mounted) {
      // Pin + wakelock + immersive sepanjang sesi solat;
      // gagal pun sesi tetap jalan.
      await SessionGuard.acquire();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          // Full Recite sahaja: pilih surah rakaat 1 & 2 dulu.
          builder: (_) => _selectedLevel == AssistanceLevel.fullRecite
              ? SurahSelectionScreen(prayerType: type)
              : PrayerSessionScreen(prayerType: type, level: _selectedLevel),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const _HomeHeader(),
            _ModeToggleRow(locale: locale),
            const SizedBox(height: 16),
            _AssistanceSpectrum(
              locale: locale,
              selected: _selectedLevel,
              onChanged: _selectLevel,
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: PrayerType.values.map((type) {
                  final config = prayerConfigs[type]!;
                  return _SolatButton(
                    config: config,
                    locale: locale,
                    onTap: () => _confirmStart(type, config, locale),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Motif mihrab line-art halus di belakang wordmark
          Opacity(
            opacity: 0.5,
            child: CustomPaint(
              size: const Size(110, 80),
              painter: _MihrabPainter(),
            ),
          ),
          Text(
            'NASYN',
            style: AppTextStyles.display.copyWith(
              fontSize: 40 * Responsive.scale(context),
              letterSpacing: 6,
            ),
          ),
          // Settings — icon kecil bulat di corner (tap target 48dp)
          Positioned(
            right: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: AppColors.lightText,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MihrabPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final w = size.width;
    final h = size.height;

    // Gerbang mihrab luar
    final outer = Path()
      ..moveTo(w * 0.08, h)
      ..lineTo(w * 0.08, h * 0.45)
      ..quadraticBezierTo(w * 0.08, h * 0.10, w * 0.5, h * 0.02)
      ..quadraticBezierTo(w * 0.92, h * 0.10, w * 0.92, h * 0.45)
      ..lineTo(w * 0.92, h);
    canvas.drawPath(outer, paint);

    // Gerbang dalam
    final inner = Path()
      ..moveTo(w * 0.22, h)
      ..lineTo(w * 0.22, h * 0.52)
      ..quadraticBezierTo(w * 0.22, h * 0.24, w * 0.5, h * 0.16)
      ..quadraticBezierTo(w * 0.78, h * 0.24, w * 0.78, h * 0.52)
      ..lineTo(w * 0.78, h);
    canvas.drawPath(inner, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModeToggleRow extends StatelessWidget {
  final AppLocale locale;
  const _ModeToggleRow({required this.locale});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    AppStrings.of('guidedMode', locale),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 36 * s,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.of('visionMode', locale),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 36 * s,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.of('comingSoon', locale),
                        style: AppTextStyles.label.copyWith(
                          fontSize: 24 * s,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistanceSpectrum extends StatelessWidget {
  final AppLocale locale;
  final AssistanceLevel selected;
  final ValueChanged<AssistanceLevel> onChanged;

  const _AssistanceSpectrum({
    required this.locale,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Segmented control: satu pill container, segment terpilih sahaja berisi
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: AssistanceLevel.values.map((level) {
            final isSelected = level == selected;
            final label = switch (level) {
              AssistanceLevel.takbirOnly => AppStrings.of('takbirOnly', locale),
              AssistanceLevel.panduanPosisi => AppStrings.of(
                'panduanPosisi',
                locale,
              ),
              AssistanceLevel.fullRecite => AppStrings.of('fullRecite', locale),
            };
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(level),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentGold
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 24 * Responsive.scale(context),
                          color: isSelected
                              ? Colors.black
                              : AppColors.lightText.withValues(alpha: 0.6),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SolatButton extends StatelessWidget {
  final PrayerConfig config;
  final AppLocale locale;
  final VoidCallback onTap;

  const _SolatButton({
    required this.config,
    required this.locale,
    required this.onTap,
  });

  // Accent kiri ikut waktu; Sunat = dashed border (luar 5 waktu fardu)
  static Color? _accentFor(PrayerType type) => switch (type) {
    PrayerType.subuh => AppColors.accentGold,
    PrayerType.zuhur || PrayerType.asar => AppColors.accentGreen,
    PrayerType.maghrib || PrayerType.isyak => AppColors.accentBlue,
    PrayerType.sunat => null,
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(config.type);
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: AppColors.primaryTeal,
        child: Row(
          children: [
            if (accent != null) Container(width: 3, color: accent),
            Expanded(child: _cardContent(context)),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: accent == null
          ? CustomPaint(
              foregroundPainter: _DashedRRectPainter(
                color: AppColors.lightText.withValues(alpha: 0.6),
                radius: 16,
              ),
              child: card,
            )
          : card,
    );
  }

  Widget _cardContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              config.displayName.toUpperCase(),
              style: AppTextStyles.body.copyWith(
                fontSize: 36 * Responsive.scale(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '(${config.rakaatCount} ${AppStrings.of('rakaatLabel', locale)})',
              style: AppTextStyles.label.copyWith(
                fontSize: 24 * Responsive.scale(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedRRectPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    const dash = 8.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
