import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/duwa_colors.dart';
import '../../core/theme/duwa_theme.dart';
import '../../services/firebase_service.dart';
import '../../viewmodels/game_night_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../common/bouncy_tap.dart';
import '../common/duwa_buttons.dart';
import '../common/duwa_logo.dart';

enum AuthMode { signIn, signUp }

class AuthView extends StatefulWidget {
  final ThemeViewModel themeVm;
  final ProfileViewModel? profileVm;
  final GameNightViewModel? gameNightVm;
  final VoidCallback onAuthenticated;

  const AuthView({
    super.key,
    required this.themeVm,
    this.profileVm,
    this.gameNightVm,
    required this.onAuthenticated,
  });

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  AuthMode _mode = AuthMode.signIn;
  bool _isLoading = false;

  // Sign In controllers
  final TextEditingController _signInEmailController = TextEditingController();
  final TextEditingController _signInPasswordController =
      TextEditingController();
  bool _obscureSignInPassword = true;

  // Sign Up controllers
  final TextEditingController _signUpNameController = TextEditingController();
  final TextEditingController _signUpEmailController = TextEditingController();
  final TextEditingController _signUpPasswordController =
      TextEditingController();
  final TextEditingController _signUpConfirmPasswordController =
      TextEditingController();
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirmPassword = true;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DuwaColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleEmailSignIn() async {
    final email = _signInEmailController.text.trim();
    final password = _signInPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseService().signInWithEmail(email, password);
      final user = cred.user;
      final rawName = user?.displayName ?? email.split('@').first;
      if (widget.profileVm != null) {
        widget.profileVm!.setProfile(
          name: rawName,
          uid: user?.uid,
          email: email,
        );
      }
      if (widget.gameNightVm != null && widget.profileVm != null) {
        widget.gameNightVm!.syncCurrentUser(widget.profileVm!.profile);
      }
      if (mounted) widget.onAuthenticated();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        _showError('Email sign-in is not enabled in Firebase Console.');
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _showError(
          'Incorrect email or password. Please verify your credentials.',
        );
      } else {
        _showError(
          e.message ?? 'Sign-in failed. Please check your credentials.',
        );
      }
    } catch (e) {
      _showError('Sign-in failed. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailSignUp() async {
    final name = _signUpNameController.text.trim();
    final email = _signUpEmailController.text.trim();
    final password = _signUpPasswordController.text;
    final confirmPassword = _signUpConfirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match. Please verify.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      const defaultEmoji = '🎮';
      final cred = await FirebaseService().registerWithEmail(
        email: email,
        password: password,
        displayName: name,
        avatarEmoji: defaultEmoji,
      );
      if (widget.profileVm != null) {
        widget.profileVm!.setProfile(
          name: name,
          emoji: defaultEmoji,
          uid: cred.user?.uid,
          email: email,
        );
      }
      if (widget.gameNightVm != null && widget.profileVm != null) {
        widget.gameNightVm!.syncCurrentUser(widget.profileVm!.profile);
      }
      if (mounted) widget.onAuthenticated();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        _showError('Email registration is disabled in Firebase Console.');
      } else if (e.code == 'email-already-in-use') {
        _showError('This email is already registered. Please sign in instead!');
      } else {
        _showError(e.message ?? 'Registration failed. Check your details.');
      }
    } catch (e) {
      _showError('Registration failed. Email might already be in use.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _signInEmailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email first, then tap Forgot password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseService().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        _showError('We could not find an account for that email.');
      } else {
        _showError(e.message ?? 'Could not send the reset email. Try again.');
      }
    } catch (_) {
      _showError('Could not send the reset email. Check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseService().signInWithGoogle();
      if (cred != null) {
        final user = cred.user;
        final name =
            user?.displayName ?? (user?.email?.split('@').first ?? 'Player');
        if (widget.profileVm != null) {
          widget.profileVm!.setProfile(
            name: name,
            email: user?.email,
            uid: user?.uid,
          );
        }
        if (widget.gameNightVm != null && widget.profileVm != null) {
          widget.gameNightVm!.syncCurrentUser(widget.profileVm!.profile);
        }
        if (mounted) widget.onAuthenticated();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        _showError('Google sign-in is not enabled in Firebase Console.');
      } else if (e.code == 'popup-closed-by-user') {
        // User closed popup; do not display error
      } else {
        _showError(e.message ?? 'Google sign-in failed.');
      }
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('popup_closed') &&
          !msg.contains('canceled') &&
          !msg.contains('cancelled')) {
        _showError('Google sign-in could not be completed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _googleSignInButton(DuwaThemeData t) {
    return BouncyTap(
      onTap: _isLoading ? null : _handleGoogleSignIn,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: t.surfaceHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.cardBorder, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 3),
                ],
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFFEA4335),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orDivider(DuwaThemeData t, {String label = 'OR'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: t.cardBorder, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                color: t.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Divider(color: t.cardBorder, height: 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.themeVm.themeData;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Switch Aesthetic',
                        icon: Icon(
                          t.isMystic
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: t.textSecondary,
                        ),
                        onPressed: widget.themeVm.toggleVibe,
                      ),
                    ],
                  ),

                  // Brand Hero Logo
                  const DuwaLogo(
                    size: DuwaLogoSize.large,
                    showWordmark: false,
                    withGlow: true,
                  ).animate().scale(
                    curve: Curves.easeOutBack,
                    duration: 500.ms,
                  ).fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),

                  // Brand Title
                  Text(
                    'DUWA',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.15, curve: Curves.easeOut),
                  const SizedBox(height: 6),
                  Text(
                    'Gaming sessions made simple',
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                  const SizedBox(height: 24),

                  // Active Card with smooth animated transition
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildCurrentCard(t),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCard(DuwaThemeData t) {
    switch (_mode) {
      case AuthMode.signIn:
        return _buildSignInCard(t);
      case AuthMode.signUp:
        return _buildSignUpCard(t);
    }
  }

  // ─────────────────────────────────────────────────────────
  // SIGN IN CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildSignInCard(DuwaThemeData t) {
    return Container(
      key: const ValueKey('sign_in_card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: t.primaryAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.login_rounded,
                  color: t.primaryAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Sign In',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to access your saved squads and game history.',
            style: TextStyle(color: t.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          _googleSignInButton(t),
          _orDivider(t, label: 'OR EMAIL SIGN IN'),

          // Email
          TextField(
            controller: _signInEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: t.surfaceHighest,
              hintText: 'Email Address',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: t.primaryAccent,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Password
          TextField(
            controller: _signInPasswordController,
            obscureText: _obscureSignInPassword,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: t.surfaceHighest,
              hintText: 'Password',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: t.primaryAccent,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignInPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: t.textMuted,
                  size: 20,
                ),
                onPressed:
                    () => setState(
                      () => _obscureSignInPassword = !_obscureSignInPassword,
                    ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          DuwaButton(
            label: 'Sign In',
            icon: Icons.login_rounded,
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _handleEmailSignIn,
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _isLoading ? null : _handlePasswordReset,
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: t.primaryAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(color: t.textSecondary, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => setState(() => _mode = AuthMode.signUp),
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      color: t.primaryAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SIGN UP CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildSignUpCard(DuwaThemeData t) {
    return Container(
      key: const ValueKey('sign_up_card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, size: 20),
                color: t.textMuted,
                onPressed: () => setState(() => _mode = AuthMode.signIn),
              ),
              const SizedBox(width: 6),
              Text(
                'Create Account',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Save your squads across all devices permanently.',
            style: TextStyle(color: t.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          _googleSignInButton(t),
          _orDivider(t, label: 'OR REGISTER WITH EMAIL'),

          // Name
          TextField(
            controller: _signUpNameController,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: t.surfaceHighest,
              hintText: 'Gamer Tag / Display Name',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon: Icon(
                Icons.person_outline,
                color: t.primaryAccent,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Email
          TextField(
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: t.surfaceHighest,
              hintText: 'Email Address',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: t.primaryAccent,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Password
          TextField(
            controller: _signUpPasswordController,
            obscureText: _obscureSignUpPassword,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: t.surfaceHighest,
              hintText: 'Password (min. 6 chars)',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: t.primaryAccent,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: t.textMuted,
                  size: 20,
                ),
                onPressed:
                    () => setState(
                      () => _obscureSignUpPassword = !_obscureSignUpPassword,
                    ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Confirm Password (Fixes the password validation bug!)
          TextField(
            controller: _signUpConfirmPasswordController,
            obscureText: _obscureSignUpConfirmPassword,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: t.surfaceHighest,
              hintText: 'Confirm Password',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon: Icon(
                Icons.lock_reset_outlined,
                color: t.primaryAccent,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: t.textMuted,
                  size: 20,
                ),
                onPressed:
                    () => setState(
                      () =>
                          _obscureSignUpConfirmPassword =
                              !_obscureSignUpConfirmPassword,
                    ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          DuwaButton(
            label: 'Create Account',
            icon: Icons.check_circle_outline_rounded,
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _handleEmailSignUp,
          ),

          const SizedBox(height: 20),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(color: t.textSecondary, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => setState(() => _mode = AuthMode.signIn),
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: t.primaryAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
