import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/law.dart';
import '../widgets/law_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chip.dart';
import 'law_detail_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _profileButtonKey = GlobalKey();
  String _searchQuery = '';
  String? _selectedCategory;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Tout', 'icon': Icons.apps_rounded, 'color': AppColors.frRed},
    {'label': 'Défense', 'icon': Icons.shield_rounded, 'color': AppColors.catDefense, 'value': 'Défense'},
    {'label': 'Économie', 'icon': Icons.trending_up_rounded, 'color': AppColors.catEconomie, 'value': 'Économie'},
    {'label': 'Travail', 'icon': Icons.work_rounded, 'color': AppColors.catTravail, 'value': 'Travail'},
    {'label': 'Intérieur', 'icon': Icons.account_balance_rounded, 'color': AppColors.catInterieur, 'value': 'Intérieur'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<Law> get _filteredLaws {
    return sampleLaws.where((law) {
      final matchesSearch = _searchQuery.isEmpty ||
          law.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          law.summary.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == null ||
          law.category.contains(_selectedCategory!);
      return matchesSearch && matchesCategory;
    }).toList();
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

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 45, 20, 30),
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: SearchBarWidget(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ),
            ),

            // Category filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 20),
                child: SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    padding: const EdgeInsets.only(right: 20),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return CategoryChip(
                        label: cat['label'] as String,
                        icon: cat['icon'] as IconData,
                        color: cat['color'] as Color,
                        isSelected: _selectedCategory == cat['value'],
                        onTap: () => setState(() => _selectedCategory = cat['value'] as String?),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Section title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lois récentes',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.frRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_filteredLaws.length} résultat${_filteredLaws.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.frRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Law cards list
            _filteredLaws.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + index * 100),
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
                              law: _filteredLaws[index],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LawDetailScreen(law: _filteredLaws[index]),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: _filteredLaws.length,
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
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 10, 24, 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0036B3),
            AppColors.frBlue,
            AppColors.frBlue,
            AppColors.frBlue,
            Color(0xFF0036B3),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
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
                onTap: () => _showAuthPopup(),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun résultat',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essayez de modifier votre recherche\nou de changer de catégorie.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
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
              Icon(Icons.person_add_rounded, color: AppColors.frBlue, size: 20),
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
    ).then((value) {
      if (value == 'login') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else if (value == 'register') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
      }
    });
  }
}
