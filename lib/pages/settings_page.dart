part of '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeMode,
          builder: (context, themeMode, _) {
            final darkMode = themeMode == ThemeMode.dark;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Appearance',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: darkMode,
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            darkMode ? Icons.dark_mode : Icons.light_mode,
                          ),
                          title: const Text('Dark mode'),
                          subtitle: Text(
                            darkMode
                                ? 'Cinema dark theme'
                                : 'Light workspace theme',
                          ),
                          onChanged: (enabled) {
                            appThemeMode.value = enabled
                                ? ThemeMode.dark
                                : ThemeMode.light;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
