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

  List<dynamic> _individualVotes = [];
  List<dynamic> _groups = [];
  Map<String, dynamic> _voteSummary = {};
  bool _isLoadingVotes = false;
  String? _hemicycleFilter; // null, 'pour', 'contre', 'abstention'
  String? _selectedGroup; // null or group abbreviation

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
        if (mounted) {
          setState(() {
            _voteSummary = resp.data!['summary'] ?? {};
            _groups = resp.data!['groups'] ?? [];
            _individualVotes = resp.data!['votes'] ?? [];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _voteSummary = {};
            _groups = [];
            _individualVotes = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching votes: $e');
      if (mounted) {
        setState(() {
          _voteSummary = {};
          _groups = [];
          _individualVotes = [];
        });
      }
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
      'oui': 'Vous avez voté Pour',
      'non': 'Vous avez voté Contre',
      'abstention': 'Vous vous êtes abstenu(e)',
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
    if (_individualVotes.isEmpty) {
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

    int dpour = _voteSummary['pour'] ?? 0;
    int dcontre = _voteSummary['contre'] ?? 0;
    int dabst = _voteSummary['abstentions'] ?? 0;
    int totalVotants = _voteSummary['votants'] ?? 1;
    String sort = _voteSummary['sort'] ?? '';

    return Column(
      children: [
        // --- Main hemicycle card ---
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Sort badge
              if (sort.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: sort == 'adopté'
                        ? AppColors.accentGreen.withValues(alpha: 0.1)
                        : AppColors.frRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: sort == 'adopté'
                          ? AppColors.accentGreen.withValues(alpha: 0.3)
                          : AppColors.frRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sort == 'adopté' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: sort == 'adopté' ? AppColors.accentGreen : AppColors.frRed,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sort == 'adopté' ? 'Texte adopté' : 'Texte rejeté',
                        style: TextStyle(
                          color: sort == 'adopté' ? AppColors.accentGreen : AppColors.frRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

              // Filter chips
              Row(
                children: [
                  _buildFilterChip('Pour', 'pour', dpour, totalVotants, const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Contre', 'contre', dcontre, totalVotants, const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Abst.', 'abstention', dabst, totalVotants, const Color(0xFF94A3B8)),
                ],
              ),
              const SizedBox(height: 28),

              // Hemicycle
              HemicycleChart(
                votesList: _individualVotes,
                activeFilter: _hemicycleFilter,
                selectedGroup: _selectedGroup,
              ),

              const SizedBox(height: 8),
              Text(
                _hemicycleFilter == null
                    ? '577 sièges • Colorés par groupe'
                    : 'Filtre actif — Appuyez à nouveau pour tout voir',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- Group legend card ---
        if (_groups.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.groups_rounded, size: 16, color: AppColors.textMuted.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    Text(
                      'Groupes parlementaires',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _groups.where((g) {
                    int gp = g['pour'] ?? 0;
                    int gc = g['contre'] ?? 0;
                    int ga = g['abstentions'] ?? 0;
                    return (gp + gc + ga) > 0;
                  }).map<Widget>((g) {
                    final color = _parseColor(g['color'] ?? '#808080');
                    final abbr = g['abbreviation'] ?? '?';
                    final gTotal = (g['pour'] ?? 0) + (g['contre'] ?? 0) + (g['abstentions'] ?? 0);
                    final bool isSelected = _selectedGroup == abbr;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedGroup = isSelected ? null : abbr;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? color : color.withValues(alpha: 0.12),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              abbr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                color: isSelected ? color : color.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '($gTotal)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? color.withValues(alpha: 0.7)
                                    : AppColors.textMuted.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Widget _buildFilterChip(String label, String filterId, int count, int total, Color c) {
    final bool isActive = _hemicycleFilter == filterId;
    final double pct = total > 0 ? (count / total * 100) : 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _hemicycleFilter = isActive ? null : filterId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? c.withValues(alpha: 0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? c.withValues(alpha: 0.4) : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: isActive ? c : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: isActive ? c.withValues(alpha: 0.7) : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? c : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
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
