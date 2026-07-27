import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../core/database/database_provider.dart';

class ThemePicker extends ConsumerWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    final themes = [
      (AppTheme.rose, 'Warm Rose', WarmRosePalette.primary, WarmRosePalette.darkBg),
      (AppTheme.sage, 'Sage Garden', SagePalette.primary, SagePalette.darkBg),
      (AppTheme.ocean, 'Ocean Calm', OceanPalette.primary, OceanPalette.darkBg),
      (AppTheme.terracotta, 'Terracotta', TerracottaPalette.primary, TerracottaPalette.darkBg),
      (AppTheme.lavender, 'Lavender Night', LavenderPalette.primary, LavenderPalette.darkBg),
    ];

    void setTheme(AppTheme appTheme) {
      ref.read(themeModeProvider.notifier).state = appTheme;
      final idx = AppTheme.values.indexOf(appTheme);
      ref.read(settingsDaoProvider).set('theme_index', '$idx');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: themes.map((t) {
              final (appTheme, label, color, darkBg) = t;
              final selected = currentTheme == appTheme;
              return GestureDetector(
                onTap: () => setTheme(appTheme),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color, darkBg],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: selected
                            ? Border.all(
                                color: theme.colorScheme.primary, width: 2.5)
                            : Border.all(
                                color: Colors.white.withAlpha(26), width: 1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
