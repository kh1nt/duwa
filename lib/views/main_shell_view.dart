import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../viewmodels/game_night_viewmodel.dart';
import '../viewmodels/groups_viewmodel.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'create/create_game_night_sheet.dart';
import 'details/game_night_details_view.dart';
import 'groups/groups_view.dart';
import 'home/home_view.dart';
import 'navigation/duwa_bottom_nav.dart';
import 'navigation/duwa_nav_rail.dart';
import 'profile/profile_view.dart';
import 'sessions/sessions_view.dart';

class MainShellView extends StatefulWidget {
  final ThemeViewModel themeVm;
  final GameNightViewModel gameNightVm;
  final GroupsViewModel groupsVm;
  final NotificationsViewModel notificationsVm;
  final ProfileViewModel profileVm;

  const MainShellView({
    super.key,
    required this.themeVm,
    required this.gameNightVm,
    required this.groupsVm,
    required this.notificationsVm,
    required this.profileVm,
  });

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  int _currentTabIndex = 0;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    widget.profileVm.addListener(_onProfileChanged);
    widget.gameNightVm.addListener(_onSessionsChanged);
    try {
      final user = FirebaseService().currentUser;
      if (user != null) {
        widget.profileVm.syncWithFirebaseUser(user);
      }
      _authSubscription = FirebaseService().authStateChanges.listen((u) {
        if (mounted && u != null) {
          widget.profileVm.syncWithFirebaseUser(u);
        }
      });
    } catch (e) {
      debugPrint('MainShell init auth sync note: $e');
    }
    // Initial sync of notifications and notification permissions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService().requestPermissions();
        _onSessionsChanged();
      }
    });
  }

  void _onProfileChanged() {
    if (!mounted) return;
    widget.gameNightVm.syncCurrentUser(widget.profileVm.profile);
    widget.groupsVm.syncCurrentUser(widget.profileVm.profile);
    _onSessionsChanged();
  }

  void _onSessionsChanged() {
    if (!mounted) return;
    widget.notificationsVm.syncWithSessions(
      sessions: widget.gameNightVm.upcomingSessions,
      currentUserId: widget.profileVm.profile.id,
      currentUserName: widget.profileVm.profile.displayName,
    );
    NotificationService().syncAllSessionReminders(
      sessions: widget.gameNightVm.upcomingSessions,
      currentUserId: widget.profileVm.profile.id,
      currentUserName: widget.profileVm.profile.displayName,
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    widget.profileVm.removeListener(_onProfileChanged);
    widget.gameNightVm.removeListener(_onSessionsChanged);
    super.dispose();
  }

  void _openCreateSheet({GameModel? initialGame}) {
    CreateGameNightSheet.show(
      context,
      gameNightVm: widget.gameNightVm,
      groupsVm: widget.groupsVm,
      duwaTheme: widget.themeVm.themeData,
      initialGame: initialGame,
      onGameNightConfirmed: () {
        setState(() {
          _currentTabIndex = 0; // Go to Home
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => GameNightDetailsView(
                  gameNight:
                      widget.gameNightVm.lastCreatedSession ??
                      widget.gameNightVm.upcomingGameNight,
                  gameNightVm: widget.gameNightVm,
                  duwaTheme: widget.themeVm.themeData,
                ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pages are defined here (outside any ListenableBuilder) so that IndexedStack
    // always receives the SAME widget instances across rebuilds. Each page
    // receives the VM directly and calls its own ListenableBuilder internally.
    final pages = [
      HomeView(
        gameNightVm: widget.gameNightVm,
        groupsVm: widget.groupsVm,
        themeVm: widget.themeVm,
        profileVm: widget.profileVm,
        notificationsVm: widget.notificationsVm,
        unreadNotificationsCount: widget.notificationsVm.unreadCount,
        onOpenSessions: () => setState(() => _currentTabIndex = 1),
        onCreateGameNight: () => _openCreateSheet(),
        onPlanWithGame: (GameModel? game) => _openCreateSheet(initialGame: game),
        onOpenGameNight: (gameNight) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => GameNightDetailsView(
                    gameNight: gameNight,
                    gameNightVm: widget.gameNightVm,
                    duwaTheme: widget.themeVm.themeData,
                  ),
            ),
          );
        },
        onOpenGroup: (group) {
          widget.groupsVm.selectGroup(group);
          setState(() {
            _currentTabIndex = 2; // Switch to Squads tab
          });
        },
      ),
      SessionsView(
        gameNightVm: widget.gameNightVm,
        duwaTheme: widget.themeVm.themeData,
        onOpenSession: (gameNight) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => GameNightDetailsView(
                    gameNight: gameNight,
                    gameNightVm: widget.gameNightVm,
                    duwaTheme: widget.themeVm.themeData,
                  ),
            ),
          );
        },
        onCreateSession: _openCreateSheet,
      ),
      GroupsView(
        groupsVm: widget.groupsVm,
        gameNightVm: widget.gameNightVm,
        duwaTheme: widget.themeVm.themeData,
        onPlanGameNightForGroup: (group) {
          widget.groupsVm.selectGroup(group);
          _openCreateSheet();
        },
        onPlanGameNightForGame: (game) {
          _openCreateSheet(initialGame: game);
        },
      ),
      ProfileView(
        profileVm: widget.profileVm,
        themeVm: widget.themeVm,
        gameNightVm: widget.gameNightVm,
        groupsVm: widget.groupsVm,
        onPlanWithGame: (GameModel? game) => _openCreateSheet(initialGame: game),
      ),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge([widget.themeVm, widget.notificationsVm]),
      builder: (context, _) {
        final duwaTheme = widget.themeVm.themeData;
        final isWide = MediaQuery.of(context).size.width >= 720;

        if (isWide) {
          return Scaffold(
            backgroundColor: duwaTheme.background,
            body: Row(
              children: [
                DuwaNavRail(
                  currentIndex: _currentTabIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                  onCreatePressed: () => _openCreateSheet(),
                  unreadNotificationsCount: widget.notificationsVm.unreadCount,
                  duwaTheme: duwaTheme,
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: IndexedStack(
                        index: _currentTabIndex,
                        children: pages,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: duwaTheme.background,
          body: SizedBox.expand(
            child: IndexedStack(index: _currentTabIndex, children: pages),
          ),
          bottomNavigationBar: DuwaBottomNavBar(
            currentIndex: _currentTabIndex,
            onTabSelected: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
            onCreatePressed: () => _openCreateSheet(),
            unreadNotificationsCount: widget.notificationsVm.unreadCount,
            duwaTheme: duwaTheme,
          ),
        );
      },
    );
  }
}
