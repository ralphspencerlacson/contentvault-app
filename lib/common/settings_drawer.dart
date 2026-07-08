part of '../main.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeMode,
          builder: (context, themeMode, _) {
            final darkMode = themeMode == ThemeMode.dark;

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.24),
                        colorScheme.secondary.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tune, size: 34),
                      SizedBox(height: 12),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text('Customize your vault experience.'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  value: darkMode,
                  secondary: Icon(
                    darkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('Dark mode'),
                  subtitle: Text(
                    darkMode ? 'Cinema dark theme' : 'Light workspace theme',
                  ),
                  onChanged: (enabled) {
                    appThemeMode.value = enabled
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
