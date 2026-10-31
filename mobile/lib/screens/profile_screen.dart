import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/civic_theme.dart';
import '../widgets/civic_components.dart';
import 'account_edit_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'admin_users_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true, _guest = false, _loggingOut = false;
  Map<String, dynamic>? _user, _personal;
  bool _personalReady = false;
  List<Map<String, dynamic>> _professions = [], _genders = [];
  String? _error, _partial;
  int _version = 0;
  @override
  void initState() {
    super.initState();
    AuthService.sessionChanges.addListener(_sessionChanged);
    unawaited(_load());
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() {
      _user = null;
      _personal = null;
      _personalReady = false;
      _professions = [];
      _genders = [];
      _loading = true;
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    AuthService.sessionChanges.removeListener(_sessionChanged);
    _version++;
    super.dispose();
  }

  Future<void> _load() async {
    final version = ++_version;
    if (!await AuthService.isLoggedIn()) {
      if (mounted && version == _version) {
        setState(() {
          _guest = true;
          _loading = false;
          _user = null;
          _error = null;
          _partial = null;
          _personal = null;
          _personalReady = false;
          _professions = [];
          _genders = [];
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _guest = false;
      });
    }
    final me = await ApiService.getMe();
    if (!mounted || version != _version) return;
    if (!me.success) {
      setState(() {
        _loading = false;
        _error = me.message;
      });
      return;
    }
    setState(() {
      _user = me.data;
      _loading = false;
    });
    final responses = await Future.wait([
      ApiService.getUserData(),
      ApiService.getProfessionalStatuses(),
      ApiService.getGenders(),
    ]);
    if (!mounted || version != _version) return;
    setState(() {
      _personal = responses[0].success ? responses[0].data : null;
      _personalReady = responses[0].success || responses[0].statusCode == 404;
      _professions = responses[1].success
          ? List<Map<String, dynamic>>.from(responses[1].data!['list'])
          : [];
      _genders = responses[2].success
          ? List<Map<String, dynamic>>.from(responses[2].data!['list'])
          : [];
      _partial =
          !_personalReady || !responses[1].success || !responses[2].success
          ? 'Certaines informations ne sont pas disponibles pour le moment.'
          : null;
    });
  }

  Future<void> _edit(AccountSection section) async {
    final saved = await Navigator.of(context).push<bool>(
      CivicPageRoute(
        context: context,
        builder: (_) => AccountEditScreen(
          section: section,
          values: {...?_user, ...?_personal},
          hasPersonalData: _personal != null,
          professions: _professions,
          genders: _genders,
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations enregistrées.')),
      );
      unawaited(_load());
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('À bientôt.', style: Civic.heading(25)),
        content: const Text('Voulez-vous vous déconnecter de votre compte ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    await AuthService.deleteToken();
    if (!mounted) return;
    setState(() => _loggingOut = false);
    if (!widget.embedded) Navigator.of(context).pop('logged_out');
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Civic.theme(context),
    child: Scaffold(
      backgroundColor: Civic.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (!widget.embedded)
                                IconButton(
                                  tooltip: 'Retour',
                                  onPressed: () => Navigator.maybePop(context),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                              const CivicWordmark(size: 26),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'MON COMPTE',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: Civic.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          if (_loading && _user == null)
                            const Padding(
                              padding: EdgeInsets.all(60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (_guest)
                            ..._visitor()
                          else if (_user != null)
                            ..._profile()
                          else if (_error != null)
                            CivicNotice(
                              message: _error!,
                              error: true,
                              action: 'Réessayer',
                              onAction: _load,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> _visitor() => [
    const Text(
      'VOTRE ESPACE CITOYEN',
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w800,
        color: Civic.blue,
      ),
    ),
    const SizedBox(height: 12),
    Text('Vos idées ont\nleur place ici.', style: Civic.heading(36)),
    const SizedBox(height: 14),
    const Text(
      'Les lois sont accessibles à tous. Avec un compte, vous pouvez aussi donner votre avis.',
      style: TextStyle(fontSize: 14, color: Civic.muted, height: 1.6),
    ),
    const SizedBox(height: 26),
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Civic.blue,
        borderRadius: BorderRadius.circular(Civic.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 110,
            width: double.infinity,
            child: CivicHemicycle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Le débat commence\navec vous.',
            style: Civic.heading(25, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'Un texte. Des explications. Votre point de vue.',
            style: TextStyle(
              color: Color(0xFFD6DDF5),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    CivicButton(
      label: 'Se connecter',
      onPressed: () => Navigator.of(context).push(
        CivicPageRoute(context: context, builder: (_) => const LoginScreen()),
      ),
    ),
    const SizedBox(height: 12),
    CivicButton(
      label: 'Créer un compte',
      secondary: true,
      onPressed: () => Navigator.of(context).push(
        CivicPageRoute(
          context: context,
          builder: (_) => const RegisterScreen(),
        ),
      ),
    ),
  ];

  List<Widget> _profile() {
    final name = (_user!['username'] as String? ?? '').trim();
    final initials = name.isEmpty ? 'É' : name.characters.first.toUpperCase();
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VOTRE ESPACE CITOYEN',
                  style: TextStyle(
                    color: Civic.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Bonjour,', style: Civic.heading(30)),
                Text(
                  name.isEmpty ? 'bienvenue.' : '$name.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Civic.heading(30, color: Civic.blue),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 30,
            backgroundColor: Civic.pale,
            child: Text(initials, style: Civic.heading(27, color: Civic.blue)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        'Votre compte, à votre image.',
        style: TextStyle(color: Civic.muted, height: 1.5),
      ),
      const SizedBox(height: 28),
      if (_error != null) ...[
        CivicNotice(
          message: _error!,
          error: true,
          action: 'Réessayer',
          onAction: _load,
        ),
        const SizedBox(height: 16),
      ],
      _section(
        'Votre compte',
        () => _edit(AccountSection.identity),
        'Modifier le compte',
      ),
      _surface([
        _info(Icons.person_outline_rounded, 'Nom d’utilisateur', name),
        const Divider(height: 1, color: Civic.line),
        _info(
          Icons.alternate_email_rounded,
          'Adresse e-mail',
          _user!['email']?.toString() ?? '',
        ),
      ]),
      const SizedBox(height: 28),
      _section(
        'Informations personnelles',
        _personalReady ? () => _edit(AccountSection.personal) : null,
        'Modifier les informations personnelles',
      ),
      const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Text(
          'Facultatives. Vous gardez la main.',
          style: TextStyle(color: Civic.muted, fontSize: 12),
        ),
      ),
      if (_partial != null) ...[
        CivicNotice(message: _partial!, action: 'Réessayer', onAction: _load),
        const SizedBox(height: 14),
      ],
      if (!_personalReady && _partial == null)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Chargement des informations personnelles…',
            style: TextStyle(color: Civic.muted),
          ),
        ),
      if (_personalReady)
        _surface([
          _info(
            Icons.cake_outlined,
            'Âge',
            _personal?['age'] == null
                ? 'Non renseigné'
                : '${_personal!['age']} ans',
          ),
          const Divider(height: 1, color: Civic.line),
          _info(
            Icons.phone_outlined,
            'Téléphone',
            _personal?['phone_number']?.toString() ?? 'Non renseigné',
          ),
          const Divider(height: 1, color: Civic.line),
          _info(
            Icons.work_outline_rounded,
            'Situation professionnelle',
            _label(_professions, _personal?['professional_status_id']),
          ),
          const Divider(height: 1, color: Civic.line),
          _info(
            Icons.person_outline_rounded,
            'Genre',
            _label(_genders, _personal?['gender_identity_id']),
          ),
        ]),
      const SizedBox(height: 28),
      if (_user!['role'] == 'admin') ...[
        CivicButton(
          label: 'Administration',
          secondary: true,
          icon: Icons.admin_panel_settings_outlined,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
        ),
        const SizedBox(height: 12),
      ],
      CivicButton(
        label: 'Se déconnecter',
        secondary: true,
        busy: _loggingOut,
        icon: Icons.logout_rounded,
        onPressed: _logout,
      ),
      const SizedBox(height: 20),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 13, color: Civic.muted),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Vous seul décidez de votre participation.',
              style: TextStyle(fontSize: 11, color: Civic.muted),
            ),
          ),
        ],
      ),
    ];
  }

  String _label(List<Map<String, dynamic>> options, dynamic id) {
    if (id == null) return 'Non renseigné';
    for (final option in options) {
      if (option['id'] == id) return option['name'].toString();
    }
    return 'Indisponible pour le moment';
  }

  Widget _section(String title, VoidCallback? edit, String tooltip) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(title, style: Civic.heading(19))),
        IconButton(
          tooltip: tooltip,
          onPressed: edit,
          icon: const Icon(Icons.edit_outlined, size: 19, color: Civic.blue),
        ),
      ],
    ),
  );
  Widget _surface(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Civic.line),
      borderRadius: BorderRadius.circular(Civic.radius),
    ),
    child: Column(children: children),
  );
  Widget _info(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Civic.muted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Civic.muted, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: Civic.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
