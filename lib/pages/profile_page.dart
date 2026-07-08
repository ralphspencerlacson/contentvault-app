part of '../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ProfileHeader(username: username),
            const SizedBox(height: 16),
            _ProfileCard(
              title: 'Profile details',
              children: [
                TextFormField(
                  initialValue: username,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: 'John Doe',
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue:
                      'Creator-first video vault for premium content.',
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: null, child: Text('Save')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileCard(
              title: 'Change password',
              children: const [
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Current password'),
                ),
                SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'New password'),
                ),
                SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Confirm password'),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: null, child: Text('Update')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.22),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.person, color: colorScheme.onPrimary, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text('@$username'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
