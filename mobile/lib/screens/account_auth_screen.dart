import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/civic_theme.dart';
import '../widgets/civic_components.dart';

/// One accessible form implementation for registration and sign-in.
class AccountAuthScreen extends StatefulWidget {
  const AccountAuthScreen({super.key, required this.register});
  final bool register;
  @override
  State<AccountAuthScreen> createState() => _AccountAuthScreenState();
}

class _AccountAuthScreenState extends State<AccountAuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hidden = true, _hiddenConfirmation = true, _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = widget.register
        ? await ApiService.register(
            username: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          )
        : await ApiService.login(
            email: _email.text.trim(),
            password: _password.text,
          );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = result.success ? null : result.message;
    });
    if (result.success) {
      TextInput.finishAutofillContext();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.register
                ? 'Votre compte a été créé.'
                : 'Vous êtes connecté.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Civic.theme(context),
    child: PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: Civic.paper,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Retour',
                            onPressed: _busy
                                ? null
                                : () => Navigator.maybePop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Civic.ink,
                            ),
                          ),
                          const Spacer(),
                          const CivicWordmark(size: 26),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'VOTRE ESPACE CITOYEN',
                        style: TextStyle(
                          color: Civic.blue,
                          letterSpacing: 1.6,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.register
                            ? 'Une opinion.\nUne voix. La vôtre.'
                            : 'Votre voix\ncompte.',
                        style: Civic.heading(38),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.register
                            ? 'Créez votre compte pour prendre part au débat.'
                            : 'Retrouvez votre espace et prenez part au débat.',
                        style: const TextStyle(
                          color: Civic.muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Civic.line),
                          borderRadius: BorderRadius.circular(Civic.radius),
                        ),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.register
                                    ? 'Créer un compte'
                                    : 'Se connecter',
                                style: Civic.heading(23),
                              ),
                              const SizedBox(height: 24),
                              if (widget.register) ...[
                                TextFormField(
                                  enabled: !_busy,
                                  controller: _name,
                                  decoration: const InputDecoration(
                                    labelText: 'Nom d’utilisateur',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  autofillHints: const [AutofillHints.nickname],
                                  textInputAction: TextInputAction.next,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Indiquez votre nom d’utilisateur.'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                enabled: !_busy,
                                controller: _email,
                                decoration: const InputDecoration(
                                  labelText: 'Adresse e-mail',
                                  prefixIcon: Icon(
                                    Icons.alternate_email_rounded,
                                  ),
                                ),
                                autofillHints: const [AutofillHints.email],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                validator: (value) =>
                                    value == null ||
                                        !RegExp(
                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                        ).hasMatch(value.trim())
                                    ? 'Indiquez une adresse e-mail valide.'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                enabled: !_busy,
                                controller: _password,
                                obscureText: _hidden,
                                autofillHints: [
                                  widget.register
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textInputAction: widget.register
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!widget.register) _submit();
                                },
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _hidden
                                        ? 'Afficher le mot de passe'
                                        : 'Masquer le mot de passe',
                                    onPressed: () =>
                                        setState(() => _hidden = !_hidden),
                                    icon: Icon(
                                      _hidden
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Indiquez votre mot de passe.'
                                    : widget.register && value.length < 6
                                    ? 'Utilisez au moins 6 caractères.'
                                    : null,
                              ),
                              if (widget.register) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  enabled: !_busy,
                                  controller: _confirmation,
                                  obscureText: _hiddenConfirmation,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Confirmer le mot de passe',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _hiddenConfirmation
                                          ? 'Afficher la confirmation'
                                          : 'Masquer la confirmation',
                                      onPressed: () => setState(
                                        () => _hiddenConfirmation =
                                            !_hiddenConfirmation,
                                      ),
                                      icon: Icon(
                                        _hiddenConfirmation
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  validator: (value) => value != _password.text
                                      ? 'Les mots de passe ne correspondent pas.'
                                      : null,
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                CivicNotice(message: _error!, error: true),
                              ],
                              const SizedBox(height: 22),
                              CivicButton(
                                label: widget.register
                                    ? 'Créer mon compte'
                                    : 'Se connecter',
                                busy: _busy,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        widget.register
                            ? 'Déjà un compte ?'
                            : 'Première visite ?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Civic.muted,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pushReplacement(
                                CivicPageRoute(
                                  context: context,
                                  builder: (_) => AccountAuthScreen(
                                    register: !widget.register,
                                  ),
                                ),
                              ),
                        child: Text(
                          widget.register ? 'Se connecter' : 'Créer un compte',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Lire les lois reste accessible sans compte.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Civic.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
