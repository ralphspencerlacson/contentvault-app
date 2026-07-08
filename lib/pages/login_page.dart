part of '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if ((username == 'creator1' || username == 'creator2') &&
        password == '1234') {
      await _saveSession(username);
      return;
    }

    if (username == 'subscriber1' && password == '1234') {
      await _saveSession(username);
      return;
    }

    setState(
      () => _error = 'Use creator1, creator2, or subscriber1 with 1234.',
    );
  }

  Future<void> _saveSession(String username) async {
    await saveSession(username);
  }

  void _fillDemoUser(String username) {
    _usernameController.text = username;
    _passwordController.text = '1234';
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const SettingsDrawer(username: 'guest'),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF11162A),
                    Color(0xFF080A12),
                    Color(0xFF20103A),
                  ]
                : const [
                    Color(0xFFF7F4FF),
                    Color(0xFFFFFFFF),
                    Color(0xFFEDE7FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              return Stack(
                children: [
                  Positioned(
                    left: 12,
                    top: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Open settings',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.28),
                                    colorScheme.secondary.withValues(
                                      alpha: 0.12,
                                    ),
                                  ],
                                ),
                                border: Border.all(
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.16,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.video_collection, size: 44),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Content Vault',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Upload, preview, and watch creator videos powered by Mux.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Choose a demo role',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Password: 1234'),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final user in [
                                        'creator1',
                                        'creator2',
                                        'subscriber1',
                                      ])
                                        ActionChip(
                                          avatar: Icon(
                                            user.startsWith('creator')
                                                ? Icons.upload
                                                : Icons.play_circle,
                                            size: 18,
                                          ),
                                          label: Text(user),
                                          onPressed: () => _fillDemoUser(user),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  TextField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person),
                                    ),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _passwordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock),
                                    ),
                                    obscureText: true,
                                    onSubmitted: (_) => _login(),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _error!,
                                      style: TextStyle(
                                        color: colorScheme.error,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 22),
                                  FilledButton.icon(
                                    onPressed: _login,
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Enter vault'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
