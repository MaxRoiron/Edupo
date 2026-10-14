import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/law_feed_controller.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey _profileButtonKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  late final LawFeedController _feed;
  bool _isLoggedIn = false;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _feed = LawFeedController(
      canApplyUpdate: () =>
          !_scrollController.hasClients || _scrollController.offset < 320,
    )..addListener(_onFeedChanged);
    unawaited(_feed.refresh(sync: true));
    _checkLoginStatus();
  }

  void _onFeedChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_feed.refresh(sync: true, preservePosition: true));
      _checkLoginStatus();
    }
  }

  void _selectGroup(bool upcoming) {
    unawaited(_feed.select(group: upcoming ? 'pending' : 'voted'));
  }

  void _search(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_feed.select(query: query)),
    );
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (mounted && loggedIn != _isLoggedIn) {
      setState(() => _isLoggedIn = loggedIn);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchTimer?.cancel();
    _feed.removeListener(_onFeedChanged);
    _feed.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4FF), AppColors.background],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RefreshIndicator(
              // A refresh reads the database immediately; collection runs beside it.
              onRefresh: () => _feed.refresh(sync: true),
              child: CustomScrollView(
                key: const PageStorageKey('laws'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: RepaintBoundary(child: _buildHeroHeader()),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: TextField(
                        onChanged: _search,
                        decoration: const InputDecoration(
                          labelText: 'Rechercher une loi',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildToggleTabs()),
                  if (_feed.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(_feed.error!),
                            TextButton(
                              onPressed: () => _feed.refresh(sync: true),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_feed.loading && _feed.laws.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_feed.laws.isEmpty && _feed.error == null)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('Aucune loi trouvée.')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final law = _feed.laws[index];
                            return LawCard(
                              key: ValueKey(law.id),
                              law: law,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LawDetailScreen(law: law),
                                ),
                              ),
                            );
                          },
                          childCount: _feed.laws.length,
                          addAutomaticKeepAlives: false,
                        ),
                      ),
                    ),
                  if (_feed.hasMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Center(
                          child: _feed.loadingMore
                              ? const CircularProgressIndicator()
                              : TextButton(
                                  onPressed: _feed.loading
                                      ? null
                                      : _feed.loadMore,
                                  child: const Text('Charger la suite'),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_feed.updatesAvailable || _feed.syncWarning != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: _feed.updatesAvailable
                      ? TextButton(
                          onPressed: () => _feed.refresh(),
                          child: const Text(
                            'De nouvelles informations sont disponibles. Actualiser',
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _feed.syncWarning!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final imageWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(1, 1200);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/slider/hemicycle.png',
              fit: BoxFit.cover,
              cacheWidth: imageWidth,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0xB3002395)],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 12,
              24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Édupo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      key: _profileButtonKey,
                      tooltip: 'Mon profil',
                      onPressed: _handleProfileTap,
                      icon: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Vous aussi, prenez part à la vie politique !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _feed.syncing
                      ? 'Recherche de mises à jour…'
                      : '${_feed.laws.length} textes de loi chargés',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTabs() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.frBlue.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildTabButton(
            label: 'À venir',
            icon: Icons.schedule_rounded,
            isSelected: _feed.group == 'pending',
            onTap: () => _selectGroup(true),
          ),
          _buildTabButton(
            label: 'Déjà votées',
            icon: Icons.how_to_vote_rounded,
            isSelected: _feed.group == 'voted',
            onTap: () => _selectGroup(false),
          ),
        ],
      ),
    ),
  );

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
                color: isSelected
                    ? Colors.white
                    : AppColors.frBlue.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColors.frBlue.withValues(alpha: 0.6),
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
      final result = await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
    ).then((value) async {
      if (!mounted) return;
      if (value == 'login') {
        final result = await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
        if (result == true) _checkLoginStatus();
      } else if (value == 'register') {
        final result = await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
        if (result == true) _checkLoginStatus();
      }
    });
  }
}
