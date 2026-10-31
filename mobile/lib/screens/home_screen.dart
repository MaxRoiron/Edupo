import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/civic_theme.dart';
import '../services/law_feed_controller.dart';
import '../widgets/civic_components.dart';
import '../widgets/law_card.dart';
import 'law_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _introKey = GlobalKey();
  late final LawFeedController _feed;
  Timer? _searchTimer;
  bool _lastLoadWasMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _feed = LawFeedController(
      canApplyUpdate: () =>
          !_scrollController.hasClients ||
          (_scrollController.offset < 120 &&
              !_scrollController.position.isScrollingNotifier.value),
    )..addListener(_onFeedChanged);
    _scrollController.addListener(_onScroll);
    unawaited(_feed.refresh(sync: true));
  }

  void _onFeedChanged() {
    if (_feed.loading || _feed.loadingMore) {
      _lastLoadWasMore = _feed.loadingMore;
    }
    if (mounted) setState(() {});
  }

  Future<void> _selectFeed({String? group, String? query}) {
    if ((group ?? _feed.group) == _feed.group &&
        (query ?? _feed.query) == _feed.query) {
      return Future.value();
    }
    if (group != null) FocusScope.of(context).unfocus();
    final introHeight = _introKey.currentContext?.size?.height;
    if (_scrollController.hasClients &&
        introHeight != null &&
        _scrollController.offset > introHeight) {
      _scrollController.jumpTo(introHeight);
    }
    return _feed.select(group: group, query: query);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 450 &&
        _feed.hasMore &&
        !_feed.loading &&
        !_feed.loadingMore &&
        _feed.error == null) {
      unawaited(_feed.loadMore());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_feed.refresh(sync: true, preservePosition: true));
    }
  }

  void _search(String value) {
    setState(() {}); // Only changes the clear affordance, never sorts the feed.
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_selectFeed(query: value.trim())),
    );
  }

  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    unawaited(_selectFeed(query: ''));
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchTimer?.cancel();
    _feed.removeListener(_onFeedChanged);
    _feed.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Civic.theme(context),
    child: Scaffold(
      backgroundColor: Civic.paper,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: Civic.blue,
              onRefresh: () => _feed.refresh(sync: true),
              child: CustomScrollView(
                key: const PageStorageKey('laws'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(child: _center(_intro())),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _FeedTools(
                      height: MediaQuery.textScalerOf(context).scale(16) > 23
                          ? 178
                          : 148,
                      child: _center(_tools()),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _center(
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              _feed.group == 'pending'
                                  ? 'Au cœur du débat'
                                  : 'Les décisions de l’Assemblée',
                              style: Civic.heading(19),
                            ),
                            Text(
                              '${_feed.laws.length} textes affichés',
                              style: const TextStyle(
                                color: Civic.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_feed.syncWarning != null)
                    SliverToBoxAdapter(
                      child: _center(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: CivicNotice(message: _feed.syncWarning!),
                        ),
                      ),
                    ),
                  if (_feed.error != null)
                    SliverToBoxAdapter(
                      child: _center(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: CivicNotice(
                            message: _feed.error!,
                            error: true,
                            action: 'Réessayer',
                            onAction: () => _lastLoadWasMore
                                ? _feed.loadMore()
                                : _feed.refresh(
                                    sync: true,
                                    preservePosition: true,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  if (_feed.loading && _feed.laws.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (!_feed.loading &&
                      _feed.laws.isEmpty &&
                      _feed.error == null)
                    SliverFillRemaining(hasScrollBody: false, child: _empty()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final law = _feed.laws[index];
                          return _center(
                            maxWidth: 672,
                            LawCard(
                              key: ValueKey(law.id),
                              law: law,
                              featured: index == 0 && _feed.query.isEmpty,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LawDetailScreen(law: law),
                                ),
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
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: _feed.loading
                                      ? null
                                      : _feed.loadMore,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Charger la suite'),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_feed.updatesAvailable)
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: _center(
                  CivicNotice(
                    message: 'De nouvelles informations sont disponibles.',
                    action: 'Actualiser',
                    onAction: () => _feed.refresh(),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _center(Widget child, {double maxWidth = 720}) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  Widget _intro() => LayoutBuilder(
    builder: (context, constraints) {
      final illustrationWidth = (constraints.maxWidth * .76)
          .clamp(240.0, 320.0)
          .toDouble();
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // The decoration paints first, behind every header control and label.
          Positioned(
            top: -5,
            right: -36,
            width: illustrationWidth,
            height: 230,
            child: const IgnorePointer(child: CivicHemicycle(fadeEdges: true)),
          ),
          Padding(
            key: _introKey,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CivicWordmark(),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Actualiser les lois',
                      onPressed: _feed.loading
                          ? null
                          : () => _feed.refresh(sync: true),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Civic.muted,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      tooltip: 'Mon compte',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Civic.blue,
                        side: const BorderSide(color: Civic.line),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        CivicPageRoute(
                          context: context,
                          builder: (_) => const ProfileScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.person_outline_rounded, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'LE DÉBAT VOUS APPARTIENT',
                  style: TextStyle(
                    color: Civic.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.7,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'La politique,\nà votre portée.',
                  style: Civic.heading(34),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Comprendre. Se positionner. Participer.',
                  style: TextStyle(
                    color: Civic.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _tools() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
    child: Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _tab('À venir', 'pending', Icons.schedule_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _tab('Déjà votées', 'voted', Icons.how_to_vote_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              _searchTimer?.cancel();
              unawaited(_selectFeed(query: value.trim()));
            },
            style: const TextStyle(fontSize: 14, color: Civic.ink),
            decoration: InputDecoration(
              hintText: 'Un sujet, une loi, une question…',
              labelText: 'Rechercher une loi',
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 21,
                color: Civic.muted,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Effacer la recherche',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded, size: 19),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Civic.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Civic.blue, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tab(String label, String group, IconData icon) {
    final selected = _feed.group == group;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? Civic.blue : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? Civic.blue : Civic.line),
        ),
        child: CivicPress(
          onTap: () => unawaited(_selectFeed(group: group)),
          radius: 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : Civic.muted,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : Civic.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  Widget _empty() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.manage_search_rounded, color: Civic.blue, size: 40),
        const SizedBox(height: 16),
        Text(
          _feed.syncing && _feed.query.isEmpty
              ? 'Les textes arrivent.'
              : 'Aucune loi trouvée.',
          style: Civic.heading(23),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          _feed.query.isEmpty
              ? 'Les textes disponibles apparaîtront ici.'
              : 'Essayez un autre mot-clé ou revenez à tous les textes.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Civic.muted, height: 1.5),
        ),
        if (_feed.query.isNotEmpty)
          TextButton(
            onPressed: _clearSearch,
            child: const Text('Effacer la recherche'),
          ),
      ],
    ),
  );
}

class _FeedTools extends SliverPersistentHeaderDelegate {
  _FeedTools({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: Civic.paper, child: child);
  @override
  bool shouldRebuild(covariant _FeedTools oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
