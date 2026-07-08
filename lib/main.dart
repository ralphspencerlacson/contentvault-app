import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

part 'common/mini_video_player.dart';
part 'common/settings_drawer.dart';
part 'common/upload_status_card.dart';
part 'common/video_list_tile.dart';
part 'common/video_player_controls.dart';
part 'models/uploaded_video.dart';
part 'pages/creator_page.dart';
part 'pages/fullscreen_video_page.dart';
part 'pages/login_page.dart';
part 'pages/subscriber_page.dart';
part 'pages/watch_video_page.dart';
part 'requests/mux_client.dart';
part 'utils/upload_formatters.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appSession.value = await loadSavedSession();
  runApp(const MuxDemoApp());
}

final uploadedVideos = <UploadedVideo>[];
final appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);
final appSession = ValueNotifier<String?>(null);
final appMiniPlayer = ValueNotifier<AppMiniPlayer?>(null);

const muxTokenId = String.fromEnvironment('MUX_TOKEN_ID');
const muxTokenSecret = String.fromEnvironment('MUX_TOKEN_SECRET');

Future<String?> loadSavedSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('demo_username');
  } on PlatformException {
    return null;
  }
}

Future<void> saveSession(String username) async {
  appSession.value = username;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('demo_username', username);
  } on PlatformException {
    // Plugin can be unavailable after hot restart until the app is rebuilt.
  }
}

Future<void> clearSession() async {
  appSession.value = null;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('demo_username');
  } on PlatformException {
    // Plugin can be unavailable after hot restart until the app is rebuilt.
  }
}

class MuxDemoApp extends StatelessWidget {
  const MuxDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: appSession,
          builder: (context, username, _) {
            return MaterialApp(
              key: ValueKey(username ?? 'logged-out'),
              title: 'Content Vault',
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: _buildAppTheme(Brightness.light),
              darkTheme: _buildAppTheme(Brightness.dark),
              home: _homeForSession(username),
              builder: (context, child) {
                return ValueListenableBuilder<AppMiniPlayer?>(
                  valueListenable: appMiniPlayer,
                  builder: (context, miniPlayer, _) {
                    return Stack(
                      children: [
                        ?child,
                        if (miniPlayer != null)
                          Positioned(
                            right: 16,
                            bottom: 16 + MediaQuery.paddingOf(context).bottom,
                            child: MiniVideoPlayer(
                              video: miniPlayer.video,
                              controller: miniPlayer.controller,
                              onExpand: miniPlayer.onExpand,
                              onClose: miniPlayer.onClose,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _homeForSession(String? username) {
    if (username == null) return const LoginScreen();
    if (username == 'creator1' || username == 'creator2') {
      return CreatorScreen(username: username);
    }
    if (username == 'subscriber1') return SubscriberScreen(username: username);
    return const LoginScreen();
  }

  ThemeData _buildAppTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6D5DF6),
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF080A12)
          : const Color(0xFFF6F4FF),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF121625) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}

class AppMiniPlayer {
  const AppMiniPlayer({
    required this.video,
    required this.controller,
    required this.onExpand,
    required this.onClose,
  });

  final UploadedVideo video;
  final VideoPlayerController controller;
  final VoidCallback onExpand;
  final VoidCallback onClose;
}
