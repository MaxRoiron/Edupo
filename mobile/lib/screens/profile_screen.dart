import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String _username = '';
  String _email = '';

  // Informations complémentaires
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedProfessionalStatus;
  int? _selectedProfessionalStatusId;
  String? _selectedGender;
  int? _selectedGenderId;
  bool _isEditingExtra = false;
  bool _hasUserData = false;

  List<Map<String, dynamic>> _professionalStatusesList = [];
  List<Map<String, dynamic>> _gendersList = [];

  List<String> get _professionalStatuses => _professionalStatusesList.map((e) => e['name'] as String).toList();
  List<String> get _genders => _gendersList.map((e) => e['name'] as String).toList();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _loadUserInfo();
  }

  @override
  void dispose() {
    _animController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    // Parallel fetching
    final results = await Future.wait([
      ApiService.getMe(),
      ApiService.getUserData(),
      ApiService.getProfessionalStatuses(),
      ApiService.getGenders(),
    ]);

    if (!mounted) return;
    
    final meResp = results[0];
    final dataResp = results[1];
    final profResp = results[2];
    final genderResp = results[3];

    if (meResp.success && meResp.data != null) {
      if (profResp.success && profResp.data != null) {
        _professionalStatusesList = List<Map<String, dynamic>>.from(profResp.data!['list']);
      }
      if (genderResp.success && genderResp.data != null) {
        _gendersList = List<Map<String, dynamic>>.from(genderResp.data!['list']);
      }

      _username = meResp.data!['username'] ?? '';
      _email = meResp.data!['email'] ?? '';

      if (dataResp.success && dataResp.data != null) {
        _hasUserData = true;
        
        final age = dataResp.data!['age'];
        if (age != null) _ageController.text = age.toString();
        
        final phone = dataResp.data!['phone_number'];
        if (phone != null) _phoneController.text = phone.toString();

        _selectedProfessionalStatusId = dataResp.data!['professional_status_id'];
        if (_selectedProfessionalStatusId != null) {
          final found = _professionalStatusesList.where((p) => p['id'] == _selectedProfessionalStatusId).toList();
          if (found.isNotEmpty) _selectedProfessionalStatus = found.first['name'];
        }

        _selectedGenderId = dataResp.data!['gender_identity_id'];
        if (_selectedGenderId != null) {
          final found = _gendersList.where((g) => g['id'] == _selectedGenderId).toList();
          if (found.isNotEmpty) _selectedGender = found.first['name'];
        }
      }

      setState(() => _isLoading = false);
      _animController.forward();
    } else {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Déconnexion',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.frRed,
            ),
            child: const Text(
              'Déconnexion',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    await AuthService.deleteToken();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vous avez été déconnecté'),
        backgroundColor: AppColors.frBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Pop back to home — return "logged_out" so home can update its state
    Navigator.of(context).pop('logged_out');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.frBlue,
                      strokeWidth: 2.5,
                    ),
                  )
                : SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildProfileContent(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0036B3),
            AppColors.frBlue,
            AppColors.frBlue,
            AppColors.frBlue,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.frBlue.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Mon Profil',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Invisible spacer to center the title
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Profile avatar bubble
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0036B3),
                  AppColors.frBlue,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.frBlue.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),

          // Username
          Text(
            _username.isNotEmpty ? _username : 'Utilisateur',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 40),

          // Info cards
          _buildInfoCard(
            icon: Icons.person_outline_rounded,
            label: 'Nom d\'utilisateur',
            value: _username.isNotEmpty ? _username : '—',
          ),
          const SizedBox(height: 14),
          _buildInfoCard(
            icon: Icons.email_outlined,
            label: 'Adresse e-mail',
            value: _email.isNotEmpty ? _email : '—',
          ),

          const SizedBox(height: 36),

          // ── Informations complémentaires ──
          _buildSectionTitleWithEdit(),
          const SizedBox(height: 16),

          // Show either read-only or editable view
          if (_isEditingExtra) ...[
            _buildEditableInfoCard(
              icon: Icons.cake_outlined,
              label: 'Âge',
              controller: _ageController,
              hint: 'Votre âge',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
            const SizedBox(height: 14),

            _buildEditableInfoCard(
              icon: Icons.phone_outlined,
              label: 'Numéro de téléphone',
              controller: _phoneController,
              hint: '06 12 34 56 78',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                LengthLimitingTextInputFormatter(18),
              ],
            ),
            const SizedBox(height: 14),

            _buildDropdownCard(
              icon: Icons.work_outline_rounded,
              label: 'Statut professionnel',
              value: _selectedProfessionalStatus,
              hint: 'Sélectionner...',
              items: _professionalStatuses,
              onChanged: (value) {
                if (value != null) {
                  final mapped = _professionalStatusesList.where((p) => p['name'] == value).toList();
                  setState(() {
                    _selectedProfessionalStatus = value;
                    _selectedProfessionalStatusId = mapped.isNotEmpty ? mapped.first['id'] : null;
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            _buildDropdownCard(
              icon: Icons.transgender_rounded,
              label: 'Genre',
              value: _selectedGender,
              hint: 'Sélectionner...',
              items: _genders,
              onChanged: (value) {
                if (value != null) {
                  final mapped = _gendersList.where((g) => g['name'] == value).toList();
                  setState(() {
                    _selectedGender = value;
                    _selectedGenderId = mapped.isNotEmpty ? mapped.first['id'] : null;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Valider button
            GestureDetector(
              onTap: _handleSaveExtra,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.frBlue,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.frBlue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Valider',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildInfoCard(
              icon: Icons.cake_outlined,
              label: 'Âge',
              value: _ageController.text.isNotEmpty ? '${_ageController.text} ans' : 'Non renseigné',
            ),
            const SizedBox(height: 14),
            _buildInfoCard(
              icon: Icons.phone_outlined,
              label: 'Numéro de téléphone',
              value: _phoneController.text.isNotEmpty ? _phoneController.text : 'Non renseigné',
            ),
            const SizedBox(height: 14),
            _buildInfoCard(
              icon: Icons.work_outline_rounded,
              label: 'Statut professionnel',
              value: _selectedProfessionalStatus ?? 'Non renseigné',
            ),
            const SizedBox(height: 14),
            _buildInfoCard(
              icon: Icons.transgender_rounded,
              label: 'Genre',
              value: _selectedGender ?? 'Non renseigné',
            ),
          ],

          const SizedBox(height: 48),

          // Logout button
          GestureDetector(
            onTap: _isLoggingOut ? null : _handleLogout,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isLoggingOut
                    ? AppColors.frRed.withValues(alpha: 0.6)
                    : AppColors.frRed,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.frRed.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoggingOut)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else ...[
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.frBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.frBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitleWithEdit() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.frBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Informations complémentaires',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _isEditingExtra = !_isEditingExtra),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isEditingExtra
                  ? AppColors.frBlue.withValues(alpha: 0.12)
                  : AppColors.frBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isEditingExtra ? Icons.close_rounded : Icons.edit_rounded,
              color: AppColors.frBlue,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  void _handleSaveExtra() async {
    setState(() => _isEditingExtra = false);

    Map<String, dynamic> updateData = {
      'age': int.tryParse(_ageController.text),
      'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'professional_status_id': _selectedProfessionalStatusId,
      'social_status_id': null,
      'gender_identity_id': _selectedGenderId,
      'user_id': -1, // Needed for creation but ignored mostly wait it's not needed for patch
    };

    if (!_hasUserData) {
      final meResp = await ApiService.getMe();
      if (meResp.success) {
        updateData['user_id'] = meResp.data!['id'];
        await ApiService.createUserData(updateData);
        _hasUserData = true;
      }
    } else {
      await ApiService.updateUserData(updateData);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Informations enregistrées'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildEditableInfoCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.frBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.frBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCard({
    required IconData icon,
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.frBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.frBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    hint: Text(
                      hint,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.frBlue.withValues(alpha: 0.6),
                      size: 22,
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    dropdownColor: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    menuMaxHeight: 300,
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: onChanged,
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
