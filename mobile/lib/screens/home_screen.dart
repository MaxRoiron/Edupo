import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/law.dart';
import '../services/api_service.dart';
import '../widgets/law_card.dart';
import 'law_detail_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey _profileButtonKey = GlobalKey();
  bool _isLoggedIn = false;
  bool _showUpcoming = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late AnimationController _gradientController;
  late ScrollController _scrollController;

  bool _isLoading = true;
  List<Law> _allLaws = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    // Gradient animation for the background
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _scrollController = ScrollController();

    _animController.forward();
    _fetchLaws();
    _checkLoginStatus();
  }

  Future<void> _fetchLaws() async {
    final response = await ApiService.getAllLaws();
    if (response.success && response.data != null) {
      final List<dynamic> lawsJson = response.data!['list'] ?? [];
      final laws = lawsJson.map((json) => Law.fromJson(json)).toList();
      if (mounted) {
        setState(() {
          _allLaws = laws;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _scoreLawForYouth(Law law) {
    int score = 0;
    // Mots-clés qui impactent soit directement les 12-30 ans, soit qui génèrent plus d'intérêt
    final keywords = [
      'jeune', 'étudiant', 'école', 'ecole', 'université', 'lycée', 'éducation', 'enseignement',
      'numérique', 'internet', 'réseaux', 'cyber', 'harcèlement', 'mineur',
      'climat', 'écologie', 'environnement', 'logement', 'pouvoir d\'achat', 'inflation',
      'emploi', 'loyer', 'smic', 'transport', 'permis', 'précarité', 'santé mentale',
      'ivg', 'avortement', 'fin de vie', 'cannabis', 'légalisation', 'police', 'sécurité'
    ];
    
    final textToSearch = '${law.title} ${law.subtitle} ${law.description}'.toLowerCase();
    
    for (final kw in keywords) {
      if (textToSearch.contains(kw)) {
        score += 3;
      }
    }
    
    // Malus pour les lois trop administratives ou locales qui intéressent moins la cible globale
    if (textToSearch.contains('ratification') || textToSearch.contains('ordonnance') || textToSearch.contains('approbation')) {
      score -= 5;
    }
    if (textToSearch.contains('codification') || textToSearch.contains('simplification administrative')) {
      score -= 3;
    }

    return score;
  }

  List<Law> get _upcomingLaws {
    // 2 months old law max
    var list = _allLaws.where((law) => law.daysUntilVote >= 0 && law.daysUntilVote <= 60).toList();
    list.sort((a, b) => _scoreLawForYouth(b).compareTo(_scoreLawForYouth(a)));
    // keep 10 most relevant upcoming laws max
    if (list.length > 10) list = list.sublist(0, 10);
    list.sort((a, b) => a.voteDate.compareTo(b.voteDate));
    return list;
  }

  List<Law> get _pastLaws {
    var list = _allLaws.where((law) => law.daysUntilVote < 0).toList();
    list.sort((a, b) => _scoreLawForYouth(b).compareTo(_scoreLawForYouth(a)));
    if (list.length > 15) list = list.sublist(0, 15);
    list.sort((a, b) => b.voteDate.compareTo(a.voteDate));
    return list;
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (mounted) {
      setState(() => _isLoggedIn = loggedIn);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _gradientController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Animated gradient background
            RepaintBoundary(
              child: _buildAnimatedBackground(),
            ),
            // Main content
            RepaintBoundary(
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                // Hero Header with hemicycle image
                SliverToBoxAdapter(child: _buildHeroHeader()),

                // Toggle Tabs
                SliverToBoxAdapter(child: _buildToggleTabs()),

                // Law cards list
                _isLoading
                    ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: AppColors.frBlue)),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final currentList = _showUpcoming ? _upcomingLaws : _pastLaws;
                              if (currentList.isEmpty && index == 0) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Center(
                                    child: Text('Aucune loi trouvée.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              if (index >= currentList.length) return const SizedBox.shrink();
                              final law = currentList[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                key: ValueKey('${law.id}_$index'),
                                duration: Duration(milliseconds: 400 + index * 80),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 30 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: LawCard(
                                  law: law,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LawDetailScreen(law: law),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: _showUpcoming
                                ? (_upcomingLaws.isEmpty ? 1 : _upcomingLaws.length)
                                : (_pastLaws.isEmpty ? 1 : _pastLaws.length),
                          ),
                        ),
                      ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  /// Animated gradient background that slowly shifts
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        final value = _gradientController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-.5 + value * 0.3, -1.0),
              end: Alignment(.5 - value * 0.3, 1.0),
              colors: [
                Color.lerp(
                  const Color(0xFFF0F4FF),
                  const Color(0xFFEDF1FA),
                  value,
                )!,
                Color.lerp(
                  AppColors.background,
                  const Color(0xFFF8F9FC),
                  value,
                )!,
                Color.lerp(
                  const Color(0xFFF8F9FC),
                  const Color(0xFFF0F4FF),
                  value,
                )!,
              ],
              stops: [0.0, 0.5 + value * 0.1, 1.0],
            ),
          ),
        );
      },
    );
  }

  /// Hero Header with hemicycle background and parallax
  Widget _buildHeroHeader() {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final double currentScrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
        final double parallaxOffset = currentScrollOffset * 0.4;
        final double headerOpacity = (1.0 - (currentScrollOffset / 300)).clamp(0.0, 1.0);

        return Container(
          height: 260,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image with parallax
              Transform.translate(
            offset: Offset(0, -parallaxOffset),
            child: Image.asset(
              'assets/images/hemicycle.png',
              fit: BoxFit.cover,
              height: 320,
              cacheHeight: 800,
              alignment: Alignment.center,
            ),
          ),

          // Dark gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.35),
                  AppColors.frBlue.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Decorative tricolor stripe at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(child: Container(height: 3, color: AppColors.frBlue)),
                Expanded(child: Container(height: 3, color: AppColors.frWhite)),
                Expanded(child: Container(height: 3, color: AppColors.frRed)),
              ],
            ),
          ),

          // Content overlay
          Positioned(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 20,
            child: Opacity(
              opacity: headerOpacity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: Logo + Profile
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Édu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'po',
                                  style: TextStyle(
                                    color: AppColors.frRed,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Profile button with glass effect
                      GestureDetector(
                        key: _profileButtonKey,
                        onTap: () => _handleProfileTap(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Tagline
                  Text(
                    'Mieux comprendre les lois,\nC\'est mieux comprendre son monde.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_allLaws.length} textes de loi en cours de suivi',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  /// Modern pill-shaped toggle tabs
  Widget _buildToggleTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.frBlue.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.frBlue.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabButton(
                  label: 'À venir',
                  icon: Icons.schedule_rounded,
                  isSelected: _showUpcoming,
                  onTap: () => setState(() => _showUpcoming = true),
                ),
                _buildTabButton(
                  label: 'Déjà votées',
                  icon: Icons.how_to_vote_rounded,
                  isSelected: !_showUpcoming,
                  onTap: () => setState(() => _showUpcoming = false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.frBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.frBlue.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.frBlue.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.frBlue.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProfileTap() async {
    if (_isLoggedIn) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      // If user logged out from profile, refresh status
      if (result == 'logged_out') {
        _checkLoginStatus();
      }
    } else {
      _showAuthPopup();
    }
  }

  void _showAuthPopup() {
    final RenderBox renderBox =
        _profileButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 120 + size.width,
        offset.dy + size.height + 8,
        offset.dx + size.width,
        0,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.cardBackground,
      items: [
        PopupMenuItem<String>(
          value: 'login',
          child: Row(
            children: [
              Icon(Icons.login_rounded, color: AppColors.frBlue, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Se connecter',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'register',
          child: Row(
            children: [
              Icon(Icons.person_add_rounded,
                  color: AppColors.frBlue, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Créer un compte',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == 'login') {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        if (result == true) _checkLoginStatus();
      } else if (value == 'register') {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
        if (result == true) _checkLoginStatus();
      }
    });
  }
}
