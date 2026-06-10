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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Header
            SliverToBoxAdapter(child: _buildHeroHeader()),

            // Toggle Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.frBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showUpcoming = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _showUpcoming ? AppColors.frBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _showUpcoming
                                  ? [
                                      BoxShadow(
                                        color: AppColors.frBlue.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'À venir',
                                style: TextStyle(
                                  color: _showUpcoming ? Colors.white : AppColors.frBlue.withValues(alpha: 0.7),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showUpcoming = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_showUpcoming ? AppColors.frBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: !_showUpcoming
                                  ? [
                                      BoxShadow(
                                        color: AppColors.frBlue.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                'Déjà votées',
                                style: TextStyle(
                                  color: !_showUpcoming ? Colors.white : AppColors.frBlue.withValues(alpha: 0.7),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
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
                                child: Text('Aucune loi trouvée.'),
                              ),
                            );
                          }
                          if (index >= currentList.length) return const SizedBox.shrink();
                          final law = currentList[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                      // reset animation key when switching list
                      key: ValueKey('${law.id}_$index'),
                      duration: Duration(milliseconds: 300 + index * 50),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
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
                  childCount: _showUpcoming ? _upcomingLaws.length : _pastLaws.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 10, 24, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0036B3),
            AppColors.frBlue,
            AppColors.frBlue,
            Color(0xFF0036B3),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 24,
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
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'po',
                          style: TextStyle(
                            color: AppColors.frRed,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Avatar / profile
              GestureDetector(
                key: _profileButtonKey,
                onTap: () => _handleProfileTap(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Subtitle
          // Text(
          //   'Votez sur les lois de demain.',
          //   style: TextStyle(
          //     color: Colors.white.withValues(alpha: 0.85),
          //     fontSize: 15,
          //     fontWeight: FontWeight.w500,
          //     height: 1.4,
          //   ),
          // ),
        ],
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
