import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'viewmodels/game_night_viewmodel.dart';
import 'viewmodels/groups_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/auth/auth_view.dart';
import 'views/common/duwa_loading_screen.dart';
import 'views/main_shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init note (running offline or test mode): $e');
  }
  runApp(const DuwaApp());
}

class DuwaApp extends StatefulWidget {
  final Widget? home;
  final bool skipAuth;

  const DuwaApp({
    super.key,
    this.home,
    this.skipAuth = false,
  });

  @override
  State<DuwaApp> createState() => _DuwaAppState();
}

class _DuwaAppState extends State<DuwaApp> {
  late final ThemeViewModel _themeVm;
  late final GameNightViewModel _gameNightVm;
  late final GroupsViewModel _groupsVm;
  late final NotificationsViewModel _notificationsVm;
  late final ProfileViewModel _profileVm;

  @override
  void initState() {
    super.initState();
    _themeVm = ThemeViewModel();
    _gameNightVm = GameNightViewModel();
    _groupsVm = GroupsViewModel();
    _notificationsVm = NotificationsViewModel();
    _profileVm = ProfileViewModel();
  }

  @override
  void dispose() {
    _themeVm.dispose();
    _gameNightVm.dispose();
    _groupsVm.dispose();
    _notificationsVm.dispose();
    _profileVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeVm,
      builder: (context, _) {
        return MaterialApp(
          title: 'DUWA — Squad Gaming Hub',
          debugShowCheckedModeBanner: false,
          theme: _themeVm.materialTheme,
          home: widget.home ??
              (widget.skipAuth
                  ? MainShellView(
                      themeVm: _themeVm,
                      gameNightVm: _gameNightVm,
                      groupsVm: _groupsVm,
                      notificationsVm: _notificationsVm,
                      profileVm: _profileVm,
                    )
                  : StreamBuilder<User?>(
                      stream: FirebaseService().authStateChanges,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return DuwaLoadingScreen(duwaTheme: _themeVm.themeData);
                        }
                        final user = snapshot.data;
                        if (user == null) {
                          return AuthView(
                            themeVm: _themeVm,
                            profileVm: _profileVm,
                            gameNightVm: _gameNightVm,
                            onAuthenticated: () {
                              setState(() {});
                            },
                          );
                        }

                        return MainShellView(
                          themeVm: _themeVm,
                          gameNightVm: _gameNightVm,
                          groupsVm: _groupsVm,
                          notificationsVm: _notificationsVm,
                          profileVm: _profileVm,
                        );
                      },
                    )),
        );
      },
    );
  }
}
