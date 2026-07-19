import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/name_utils.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/entities/app_user_profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialogs/omonimo_dialog.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_controller.dart';
import 'widgets/step_reveal.dart';

/// Combined login/registration screen: a single progressively-revealed form
/// that switches between "create account" and "sign in" modes, mirroring
/// the original web app 1:1 (same fields, same validation, same duplicate
/// -name handling) with Material 3 styling.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _nomeCtrl = TextEditingController();
  final _cognomeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confermaCtrl = TextEditingController();

  final _nomeFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _modalitaLogin = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nomeCtrl, _cognomeCtrl, _passwordCtrl, _confermaCtrl]) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [_nomeCtrl, _cognomeCtrl, _passwordCtrl, _confermaCtrl]) {
      c.dispose();
    }
    _nomeFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  bool get _nomeOk => _nomeCtrl.text.trim().isNotEmpty;
  bool get _cognomeOk => _cognomeCtrl.text.trim().isNotEmpty;
  bool get _passOk => _passwordCtrl.text.length >= 6;
  bool get _confOk => _confermaCtrl.text.length >= 6;

  bool get _showCognome => _nomeOk;
  bool get _showPassword => _nomeOk && _cognomeOk;
  bool get _showConferma => !_modalitaLogin && _nomeOk && _cognomeOk && _passOk;
  bool get _showSubmit => _modalitaLogin
      ? (_nomeOk && _cognomeOk && _passOk)
      : (_nomeOk && _cognomeOk && _passOk && _confOk);

  void _toggleMode() {
    setState(() => _modalitaLogin = !_modalitaLogin);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final nome = normalizeName(_nomeCtrl.text);
    final cognome = normalizeName(_cognomeCtrl.text);
    final password = _passwordCtrl.text;

    if (RegExp(r'\s').hasMatch(password)) {
      showAppToast(context, l10n.authErrorPasswordSpaces);
      return;
    }
    if (RegExp('[^\x21-\x7E]').hasMatch(password)) {
      showAppToast(context, l10n.authErrorPasswordChars);
      return;
    }

    if (!_modalitaLogin) {
      if (password != _confermaCtrl.text) {
        showAppToast(context, l10n.authErrorPasswordMismatch);
        return;
      }
      if (password.length < 6) {
        showAppToast(context, l10n.authErrorPasswordTooShort);
        return;
      }
    }

    final email = pseudoEmail(nome, cognome);
    final authRepo = ref.read(authRepositoryProvider);

    setState(() => _busy = true);
    try {
      final AuthSession session;
      if (_modalitaLogin) {
        session = await authRepo.signIn(email: email, password: password);
      } else {
        session = await authRepo.register(email: email, password: password);
        try {
          await ref
              .read(userRepositoryProvider)
              .createProfile(
                AppUserProfile(uid: session.uid, nome: nome, cognome: cognome),
              );
        } catch (_) {}
      }

      _nomeCtrl.clear();
      _cognomeCtrl.clear();
      _passwordCtrl.clear();
      _confermaCtrl.clear();

      await ref
          .read(sessionControllerProvider.notifier)
          .enterAfterAuthSuccess(session, nome, cognome);
    } on AuthException catch (e) {
      if (!mounted) return;
      switch (e.failure) {
        case AuthFailure.duplicateAccount:
          final action = await showOmonimoDialog(
            context,
            nome: nome,
            cognome: cognome,
          );
          if (!mounted) return;
          if (action == OmonimoAction.switchToLogin) {
            setState(() => _modalitaLogin = true);
            _passwordCtrl.clear();
            _passwordFocus.requestFocus();
          } else if (action == OmonimoAction.addInitial) {
            _nomeCtrl.text = '${_nomeCtrl.text.trim()} ';
            _nomeCtrl.selection = TextSelection.collapsed(
              offset: _nomeCtrl.text.length,
            );
            _nomeFocus.requestFocus();
            showAppToast(context, l10n.omonimoToastAddInitial);
          }
          break;
        case AuthFailure.wrongCredentials:
        case AuthFailure.weakPassword:
          showAppToast(context, e.message);
          break;
        case AuthFailure.other:
          showAppToast(context, l10n.authErrorGeneric(e.message));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 50),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍝', style: TextStyle(fontSize: 38)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.appTitle,
                    style: AppTextStyles.display(
                      color: colors.wineDeep,
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _modalitaLogin ? l10n.authSubLogin : l10n.authSubCreate,
                    style: TextStyle(color: colors.inkSoft, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nomeCtrl,
                    focusNode: _nomeFocus,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: l10n.fieldNome,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  StepReveal(
                    visible: _showCognome,
                    child: Column(
                      children: [
                        TextField(
                          controller: _cognomeCtrl,
                          maxLength: 40,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: l10n.fieldCognome,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  StepReveal(
                    visible: _showPassword,
                    child: Column(
                      children: [
                        TextField(
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          obscureText: true,
                          maxLength: 64,
                          decoration: InputDecoration(
                            hintText: l10n.fieldPassword,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  StepReveal(
                    visible: _showConferma,
                    child: Column(
                      children: [
                        TextField(
                          controller: _confermaCtrl,
                          obscureText: true,
                          maxLength: 64,
                          decoration: InputDecoration(
                            hintText: l10n.fieldConfirmPassword,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  StepReveal(
                    visible: _showSubmit,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.wine,
                            foregroundColor: colors.paper,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                          child: Text(
                            _busy
                                ? (_modalitaLogin
                                      ? l10n.authSubmitSigningIn
                                      : l10n.authSubmitCreating)
                                : (_modalitaLogin
                                      ? l10n.authSubmitLogin
                                      : l10n.authSubmitCreate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _modalitaLogin
                          ? l10n.authToggleToRegister
                          : l10n.authToggleToLogin,
                      style: TextStyle(
                        color: colors.inkSoft,
                        fontSize: 12.5,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
