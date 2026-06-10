import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/law.dart';
import '../theme/app_theme.dart';
import '../widgets/hemicycle_chart.dart';

class LawDetailScreen extends StatefulWidget {
  final Law law;

  const LawDetailScreen({super.key, required this.law});

  @override
  State<LawDetailScreen> createState() => _LawDetailScreenState();
}

class _LawDetailScreenState extends State<LawDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _vote; // null = pas voté, 'oui', 'non', 'abstention'
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  List<dynamic> _assemblyVotes = [];
  bool _isLoadingVotes = false;
  String? _hemicycleFilter; // null, 'pour', 'contre', 'abstention'

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    if (widget.law.daysUntilVote < 0) {
      _fetchAssemblyVotes();
    }
  }

  Future<void> _fetchAssemblyVotes() async {
    setState(() => _isLoadingVotes = true);
    try {
      final resp = await ApiService.getAssemblyVotes(widget.law.id);
      if (resp.success && resp.data != null) {
        if (mounted) setState(() => _assemblyVotes = resp.data!['votes'] ?? []);
      } else {
        if (mounted) setState(() => _assemblyVotes = []);
      }
    } catch (e) {
      debugPrint('Error fetching votes: $e');
      if (mounted) setState(() => _assemblyVotes = []);
    }
    if (mounted) setState(() => _isLoadingVotes = false);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleVote(String vote) {
    setState(() => _vote = vote);

    // Feedback visuel
    final messages = {
      'oui': 'Vous avez voté Pour ✅',
      'non': 'Vous avez voté Contre ❌',
      'abstention': 'Vous vous êtes abstenu(e) ⚪',
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          messages[vote]!,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        backgroundColor: vote == 'oui'
            ? AppColors.accentGreen
            : vote == 'non'
            ? AppColors.frRed
            : AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: widget.law.urgencyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.law.urgencyColor.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.law.urgencyColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.event_rounded,
                              color: widget.law.urgencyColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date du vote · ${widget.law.urgencyLabel}',
                                style: TextStyle(
                                  color: widget.law.urgencyColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.law.date,
                                style: TextStyle(
                                  color: widget.law.urgencyColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.frBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.law.category,
                              style: const TextStyle(
                                color: AppColors.frBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      widget.law.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      widget.law.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Divider(
                      color: AppColors.border.withValues(alpha: 0.6),
                      thickness: 1,
                    ),
                    const SizedBox(height: 20),

                    // Section: Explications
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.accentPurple,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Comprendre ce texte',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.law.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.8,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Section: Vote ou Résultats
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.frBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.law.daysUntilVote < 0
                                ? Icons.bar_chart_rounded
                                : Icons.how_to_vote_rounded,
                            color: AppColors.frBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.law.daysUntilVote < 0
                              ? 'Résultat des votes'
                              : 'Votre vote',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Vote buttons or Results
                    widget.law.daysUntilVote < 0
                        ? _buildVoteResults()
                        : _buildVoteButtons(),

                    const SizedBox(height: 40),
                  ],
                ),
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
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
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
            'Détail du texte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Invisible spacer for centering
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildVoteButtons() {
    return Column(
      children: [
        // Oui / Non row
        Row(
          children: [
            // Voter Oui
            Expanded(
              child: _buildVoteButton(
                label: 'Voter Pour',
                icon: Icons.thumb_up_rounded,
                color: AppColors.accentGreen,
                voteValue: 'oui',
              ),
            ),
            const SizedBox(width: 14),
            // Voter Non
            Expanded(
              child: _buildVoteButton(
                label: 'Voter Contre',
                icon: Icons.thumb_down_rounded,
                color: AppColors.frRed,
                voteValue: 'non',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // S'abstenir
        _buildAbstainButton(),
      ],
    );
  }

  Widget _buildVoteResults() {
    if (_isLoadingVotes) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.frBlue),
      );
    }
    if (_assemblyVotes.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 48, color: AppColors.frBlue.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Les résultats ne sont pas encore disponibles pour ce texte.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    // Extract totals from API
    final firstVote = _assemblyVotes.first['vote']['scrutin'];
    int dpour = int.tryParse(firstVote['nombre_pours'] ?? '0') ?? 0;
    int dcontre = int.tryParse(firstVote['nombre_contres'] ?? '0') ?? 0;
    int dabst = int.tryParse(firstVote['nombre_abstentions'] ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Filter Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterBtn('Pour', 'pour', dpour, AppColors.accentGreen),
              _buildFilterBtn('Contre', 'contre', dcontre, AppColors.frRed),
              _buildFilterBtn(
                'Abstention',
                'abstention',
                dabst,
                AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Dynamic Parliament Hemicycle
          HemicycleChart(
            votesList: _assemblyVotes,
            activeFilter: _hemicycleFilter,
          ),

          const SizedBox(height: 12),
          Text(
            _hemicycleFilter == null
                ? 'Tous les suffrages'
                : 'Sièges colorés par groupe politique',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String title, String filterId, int count, Color c) {
    final bool isActive = _hemicycleFilter == filterId;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            setState(() => _hemicycleFilter = isActive ? null : filterId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? c : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? c : c.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : c,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : c.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required String label,
    required IconData icon,
    required Color color,
    required String voteValue,
  }) {
    final isSelected = _vote == voteValue;
    final isOtherSelected = _vote != null && _vote != voteValue;

    return GestureDetector(
      onTap: () => _handleVote(voteValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : isOtherSelected
              ? color.withValues(alpha: 0.06)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : isOtherSelected
                ? color.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isOtherSelected
                    ? color.withValues(alpha: 0.4)
                    : color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                '✓ Votre choix',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAbstainButton() {
    final isSelected = _vote == 'abstention';
    final isOtherSelected = _vote != null && _vote != 'abstention';

    return GestureDetector(
      onTap: () => _handleVote('abstention'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9CA3AF)
              : isOtherSelected
              ? const Color(0xFFF0F0F0)
              : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9CA3AF)
                : isOtherSelected
                ? const Color(0xFFE5E5E5)
                : const Color(0xFFDDDDDD),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.front_hand_rounded,
              color: isSelected
                  ? Colors.white
                  : isOtherSelected
                  ? AppColors.textMuted.withValues(alpha: 0.4)
                  : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isSelected ? 'Abstention ✓' : 'S\'abstenir',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : isOtherSelected
                    ? AppColors.textMuted.withValues(alpha: 0.4)
                    : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
