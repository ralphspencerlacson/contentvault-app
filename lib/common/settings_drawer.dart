part of '../main.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({
    super.key,
    this.username,
    this.role,
    this.onVideosTap,
    this.onCreatorsTap,
    this.onMyVideosTap,
    this.onLogout,
  });

  final String? username;
  final String? role;
  final VoidCallback? onVideosTap;
  final VoidCallback? onCreatorsTap;
  final VoidCallback? onMyVideosTap;
  final VoidCallback? onLogout;

  bool get _isCreator => role == 'creator';
  bool get _isLoggedIn => role == 'creator' || role == 'subscriber';

  @override
  Widget build(BuildContext context) {
    final currentUsername = username ?? 'guest';

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _DrawerUserCard(username: currentUsername),
            const SizedBox(height: 18),
            if (_isLoggedIn) ...[
              const _DrawerSectionTitle('Navigation'),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Homepage'),
                onTap: onVideosTap ?? () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Creators'),
                onTap: onCreatorsTap,
              ),
              const SizedBox(height: 10),
            ],
            const _DrawerSectionTitle('Account'),
            if (_isCreator)
              ListTile(
                leading: const Icon(Icons.video_collection_outlined),
                title: const Text('My Videos'),
                onTap: onMyVideosTap ?? () => Navigator.of(context).pop(),
              ),
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('History'),
              enabled: false,
            ),
            const ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Favorites'),
              enabled: false,
            ),
            const ListTile(
              leading: Icon(Icons.schedule_outlined),
              title: Text('Watch later'),
              enabled: false,
            ),
            const ListTile(
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('Billing'),
              enabled: false,
            ),
            if (_isCreator) ...[
              const ListTile(
                leading: Icon(Icons.insights_outlined),
                title: Text('Analytics'),
                enabled: false,
              ),
              const ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('Earnings'),
                enabled: false,
              ),
            ],
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileScreen(username: currentUsername),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 28),
            if (_isLoggedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.of(context).pop();
                  onLogout?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerUserCard extends StatelessWidget {
  const _DrawerUserCard({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.22),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.person, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text('@$username'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  const _DrawerSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.62),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
