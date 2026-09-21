import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/preferences_service.dart';
import 'viewmodels/game_night_viewmodel.dart';
import 'viewmodels/groups_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/auth/auth_view.dart';
import 'views/common/duwa_loading_screen.dart';
import 'views/main_shell_view.dart';
import 'views/splash/duwa_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService().init();
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
  final bool skipSplash;

  const DuwaApp({
    super.key,
    this.home,
    this.skipAuth = false,
    this.skipSplash = false,
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
  StreamSubscription<User?>? _authSubscription;
  String? _lastAuthUid;
  late bool _splashComplete;

  @override
  void initState() {
    super.initState();
    _splashComplete = widget.skipSplash || widget.skipAuth || widget.home != null;
    _themeVm = ThemeViewModel();
    _gameNightVm = GameNightViewModel();
    _groupsVm = GroupsViewModel();
    _notificationsVm = NotificationsViewModel();
    _profileVm = ProfileViewModel();

    // Push profile changes to the data ViewModels immediately, regardless of
    // whether MainShellView is mounted. This ensures syncCurrentUser() is always
    // called promptly after sign-in, closing the race window where subscriptions
    // might fire before the user identity is known.
    _profileVm.addListener(_onProfileChanged);

    _authSubscription = FirebaseService().authStateChanges.listen((user) {
      final currentUid = user?.uid;
      if (_lastAuthUid != null && _lastAuthUid != currentUid) {
        // Account switched or signed out:
        // 1. Clear transient data FIRST so no stale data is visible.
        _notificationsVm.clearNotifications();
        _gameNightVm.reset();
        _groupsVm.reset();
        _profileVm.reset();
      }
      _lastAuthUid = currentUid;
      if (user != null) {
        // Profile sync is async. When it completes and calls notifyListeners(),
        // _onProfileChanged() fires and pushes the identity to all data VMs.
        _profileVm.syncWithFirebaseUser(user);
      }
    });
  }

  /// Called whenever the profile ViewModel notifies listeners.
  /// Propagates the current user identity to all data ViewModels so their
  /// Firestore subscriptions are correctly scoped to the authenticated user.
  void _onProfileChanged() {
    _gameNightVm.syncCurrentUser(_profileVm.profile);
    _groupsVm.syncCurrentUser(_profileVm.profile);
  }

  @override
  void dispose() {
    _profileVm.removeListener(_onProfileChanged);
    _authSubscription?.cancel();
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
          title: 'DUWA',
          debugShowCheckedModeBanner: false,
          theme: _themeVm.materialTheme,
          home: widget.home ??
              (!_splashComplete
                  ? DuwaSplashScreen(
                      duwaTheme: _themeVm.themeData,
                      onComplete: () {
                        if (mounted) {
                          setState(() {
                            _splashComplete = true;
                          });
                        }
                      },
                    )
                  : (widget.skipAuth
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
                        ))),
        );
      },
    );
  }
}
