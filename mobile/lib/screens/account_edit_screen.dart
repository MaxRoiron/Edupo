import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/civic_theme.dart';
import '../widgets/civic_components.dart';

enum AccountSection { identity, personal }

class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({
    super.key,
    required this.section,
    required this.values,
    this.hasPersonalData = false,
    this.professions = const [],
    this.genders = const [],
  });
  final AccountSection section;
  final Map<String, dynamic> values;
  final bool hasPersonalData;
  final List<Map<String, dynamic>> professions, genders;
  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _email, _age, _phone;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int? _profession, _gender;
  bool _busy = false;
  String? _error;
  bool get _personal => widget.section == AccountSection.personal;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: widget.values['username'] as String? ?? '',
    );
    _email = TextEditingController(
      text: widget.values['email'] as String? ?? '',
    );
    _age = TextEditingController(text: widget.values['age']?.toString() ?? '');
    _phone = TextEditingController(
      text: widget.values['phone_number'] as String? ?? '',
    );
    _profession = widget.values['professional_status_id'] as int?;
    _gender = widget.values['gender_identity_id'] as int?;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _age,
      _phone,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final payload = _personal
        ? <String, dynamic>{
            'age': _age.text.trim().isEmpty ? null : int.parse(_age.text),
            'phone_number': _phone.text.trim().isEmpty
                ? null
                : _phone.text.trim(),
            'professional_status_id': _profession,
            'gender_identity_id': _gender,
          }
        : <String, dynamic>{
            'username': _name.text.trim(),
            'email': _email.text.trim(),
            if (_password.text.isNotEmpty) 'password': _password.text,
          };
    final response = _personal
        ? widget.hasPersonalData
              ? await ApiService.updateUserData(payload)
              : await ApiService.createUserData(payload)
        : await ApiService.updateAccount(payload);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = response.success ? null : response.message;
    });
    if (response.success) Navigator.of(context).pop(true);
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
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Annuler les modifications',
                            onPressed: _busy
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          const CivicWordmark(size: 25),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        _personal
                            ? 'Un profil\nqui vous ressemble.'
                            : 'Les détails\nfont la différence.',
                        style: Civic.heading(33),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _personal
                            ? 'Ces informations sont facultatives.'
                            : 'Gérez vos identifiants et votre accès à Édupo.',
                        style: const TextStyle(color: Civic.muted, height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      if (!_personal) ...[
                        TextFormField(
                          controller: _name,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Nom d’utilisateur',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Indiquez votre nom d’utilisateur.'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Adresse e-mail',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              value == null ||
                                  !RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(value.trim())
                              ? 'Indiquez une adresse e-mail valide.'
                              : null,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Modifier le mot de passe',
                          style: Civic.heading(18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Laissez ces champs vides pour conserver votre mot de passe.',
                          style: TextStyle(
                            color: Civic.muted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nouveau mot de passe',
                          ),
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (value) =>
                              value != null &&
                                  value.isNotEmpty &&
                                  value.length < 6
                              ? 'Utilisez au moins 6 caractères.'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _confirm,
                          enabled: !_busy,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmer le nouveau mot de passe',
                          ),
                          validator: (value) => value != _password.text
                              ? 'Les mots de passe ne correspondent pas.'
                              : null,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _age,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Âge',
                            suffixText: 'ans',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) =>
                              value != null &&
                                  value.isNotEmpty &&
                                  (int.tryParse(value) == null ||
                                      int.parse(value) > 120)
                              ? 'Indiquez un âge entre 0 et 120 ans.'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _phone,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                          ),
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                        ),
                        const SizedBox(height: 18),
                        _dropdown(
                          'Situation professionnelle',
                          widget.professions,
                          _profession,
                          (value) => setState(() => _profession = value),
                        ),
                        const SizedBox(height: 18),
                        _dropdown(
                          'Genre',
                          widget.genders,
                          _gender,
                          (value) => setState(() => _gender = value),
                        ),
                        if (widget.professions.isEmpty ||
                            widget.genders.isEmpty) ...[
                          const SizedBox(height: 16),
                          const CivicNotice(
                            message:
                                'Certaines listes sont indisponibles. Les informations déjà enregistrées seront conservées.',
                          ),
                        ],
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        CivicNotice(message: _error!, error: true),
                      ],
                      const SizedBox(height: 28),
                      CivicButton(
                        label: 'Enregistrer les modifications',
                        icon: Icons.check_rounded,
                        busy: _busy,
                        onPressed: _save,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        child: const Text('Annuler'),
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
  Widget _dropdown(
    String label,
    List<Map<String, dynamic>> options,
    int? selected,
    ValueChanged<int?> onChanged,
  ) => DropdownButtonFormField<int>(
    initialValue: selected,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      const DropdownMenuItem<int>(value: null, child: Text('Non renseigné')),
      if (selected != null &&
          !options.any((option) => option['id'] == selected))
        DropdownMenuItem<int>(
          value: selected,
          child: const Text(
            'Valeur enregistrée',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ...options.map(
        (option) => DropdownMenuItem<int>(
          value: option['id'] as int,
          child: Text(
            option['name'] as String,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
    onChanged: _busy || options.isEmpty ? null : onChanged,
  );
}
