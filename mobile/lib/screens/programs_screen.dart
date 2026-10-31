import 'package:flutter/material.dart';
import '../models/political_party.dart';
import '../repositories/political_repository.dart';
import '../theme/civic_theme.dart';
import '../theme/political_identity.dart';
import '../widgets/civic_components.dart';
import '../widgets/political_components.dart';
import 'program_detail_screen.dart';
import 'text_reader_screen.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key, this.repository});
  final PoliticalRepository? repository;
  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  late Future<PoliticalCatalog> _catalog;
  final _search = TextEditingController();
  final _introKey = GlobalKey();
  final _scroll = ScrollController();
  bool _measures = false, _declared = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _catalog = (widget.repository ?? PoliticalRepository.instance).load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _showResults({bool animate = false}) {
    final intro = _introKey.currentContext?.findRenderObject();
    if (!_scroll.hasClients || intro is! RenderBox) return;
    final offset = intro.size.height.clamp(
      _scroll.position.minScrollExtent,
      _scroll.position.maxScrollExtent,
    );
    if (animate && Civic.duration(context, true) != Duration.zero) {
      _scroll.animateTo(
        offset,
        duration: Civic.duration(context, true),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scroll.jumpTo(offset);
    }
  }

  void _changeFilters(VoidCallback change) {
    setState(change);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showResults();
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Civic.theme(context),
    child: Scaffold(
      backgroundColor: Civic.paper,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: FutureBuilder<PoliticalCatalog>(
              future: _catalog,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _state(
                    'Le dossier n’a pas pu être chargé.',
                    'Réessayer',
                    () => setState(_load),
                    Icons.cloud_off_outlined,
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: Semantics(
                      liveRegion: true,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            semanticsLabel: 'Chargement du dossier politique',
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Chargement du dossier…',
                            style: TextStyle(color: Civic.muted),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _content(snapshot.requireData);
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget _state(
    String message,
    String action,
    VoidCallback onTap,
    IconData icon,
  ) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Civic.blue),
          const SizedBox(height: 18),
          Text(message, textAlign: TextAlign.center, style: Civic.heading(23)),
          const SizedBox(height: 20),
          CivicButton(label: action, onPressed: onTap),
        ],
      ),
    ),
  );

  Widget _content(PoliticalCatalog catalog) {
    final query = normalizePoliticalSearch(_search.text.trim());
    final parties = catalog.parties
        .where(
          (p) => (!_declared || p.election2027.isDeclared) && p.matches(query),
        )
        .toList();
    final measures = <({PoliticalParty party, PoliticalProposal proposal})>[
      for (final party in catalog.parties.where(
        (p) => !_declared || p.election2027.isDeclared,
      ))
        for (final proposal in party.proposals)
          if (normalizePoliticalSearch(
            '${party.name} ${party.abbreviation} ${party.leadership.map((p) => p.name).join(' ')} ${party.election2027.people.map((p) => p.name).join(' ')} ${proposal.theme} ${proposal.title} ${proposal.summary}',
          ).contains(query))
            (party: party, proposal: proposal),
    ];
    final count = _measures ? measures.length : parties.length;
    return CustomScrollView(
      key: const PageStorageKey('political-feed'),
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            key: _introKey,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CivicWordmark(),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Comprendre ce dossier',
                      onPressed: () => _method(catalog),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: Civic.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const PoliticalLabel('LE CAP SUR 2027'),
                const SizedBox(height: 14),
                Text('La politique,\nen clair.', style: Civic.heading(36)),
                const SizedBox(height: 14),
                const Text(
                  'Les partis, les candidatures et les idées.\nDes repères pour vous faire votre avis.',
                  style: TextStyle(
                    color: Civic.muted,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.verified_outlined,
                        size: 15,
                        color: Civic.blue,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Dossier vérifié le ${politicalDate(catalog.checkedAt)}',
                        style: const TextStyle(
                          color: Civic.blue,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        PinnedHeaderSliver(
          child: ColoredBox(
            color: Civic.paper,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _search,
                    onTap: () => _showResults(animate: true),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    onChanged: (_) => _changeFilters(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Rechercher dans les partis',
                      labelText: 'Rechercher dans les partis',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer la recherche',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => _changeFilters(_search.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _mode(
                          'Partis',
                          !_measures,
                          () => _changeFilters(() => _measures = false),
                        ),
                        const SizedBox(width: 8),
                        _mode(
                          'Mesures',
                          _measures,
                          () => _changeFilters(() => _measures = true),
                        ),
                        const SizedBox(width: 12),
                        FilterChip(
                          label: const Text('Candidatures déclarées'),
                          selected: _declared,
                          onSelected: (value) =>
                              _changeFilters(() => _declared = value),
                          selectedColor: Civic.pale,
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            color: Civic.blue,
                          ),
                          side: const BorderSide(color: Civic.line),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$count ${_measures ? 'mesure${count > 1 ? 's' : ''}' : 'parti${count > 1 ? 's' : ''}'} · ordre alphabétique',
                      style: const TextStyle(fontSize: 12, color: Civic.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (count == 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              child: PoliticalPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catalog.parties.isEmpty
                          ? 'Le dossier est encore vide.'
                          : 'Aucun résultat pour ces critères.',
                      style: Civic.heading(22),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Essayez un autre nom ou un autre thème.',
                      style: TextStyle(color: Civic.muted),
                    ),
                    TextButton(
                      onPressed: () => _changeFilters(() {
                        _search.clear();
                        _declared = false;
                      }),
                      child: const Text('Réinitialiser les filtres'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList.builder(
            itemCount: count,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _measures
                  ? ProposalCard(
                      proposal: measures[index].proposal,
                      party: measures[index].party,
                      onTap: () => Navigator.push(
                        context,
                        CivicPageRoute(
                          context: context,
                          builder: (_) => TextReaderScreen(
                            party: measures[index].party,
                            proposal: measures[index].proposal,
                          ),
                        ),
                      ),
                    )
                  : _partyCard(parties[index]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catalog.electionNotice,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Civic.muted,
                    height: 1.6,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _method(catalog),
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('Périmètre et méthode'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mode(String label, bool selected, VoidCallback onTap) =>
      PoliticalChoiceChip(label: label, selected: selected, onSelected: onTap);

  Widget _partyCard(PoliticalParty party) {
    final identity = politicalIdentity(party.id);
    final smallText = MediaQuery.textScalerOf(context).scale(14) <= 20;
    final featured = party.election2027.people.isNotEmpty
        ? party.election2027.people.map((person) => person.name).join(' · ')
        : party.election2027.summary;
    return Material(
      key: ValueKey('party-card-${party.id}'),
      color: identity.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: identity.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: CivicPress(
        radius: 20,
        onTap: () => Navigator.push(
          context,
          CivicPageRoute(
            context: context,
            builder: (_) => ProgramDetailScreen(party: party),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: identity.color),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PartyMark(party, size: 43),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              party.abbreviation,
                              style: TextStyle(
                                color: identity.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (smallText) ...[
                              const SizedBox(height: 2),
                              Text(
                                party.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Civic.heading(17),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: identity.color,
                        size: 19,
                      ),
                    ],
                  ),
                  if (!smallText) ...[
                    const SizedBox(height: 8),
                    Text(party.name, style: Civic.heading(18)),
                  ],
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PoliticalPositionFlag(party.id),
                      Text(
                        party.election2027.label,
                        style: const TextStyle(
                          color: Civic.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    featured,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Civic.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${party.proposals.length} propositions documentées',
                    style: const TextStyle(color: Civic.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _method(PoliticalCatalog catalog) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Civic.paper,
    builder: (context) => FractionallySizedBox(
      heightFactor: .85,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Des repères,\npas des consignes.',
                    style: Civic.heading(28),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer la méthode',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              catalog.scope,
              style: const TextStyle(color: Civic.ink, height: 1.7),
            ),
            const SizedBox(height: 20),
            Text(
              catalog.electionNotice,
              style: const TextStyle(color: Civic.muted, height: 1.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'Les synthèses sont éditoriales et sourcées. Elles distinguent la direction du parti, la candidature annoncée et la validation officielle. Les programmes antérieurs à 2027 portent leur contexte. Les propositions ne constituent pas une liste exhaustive ni un classement.',
              style: TextStyle(color: Civic.muted, height: 1.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'Les repères gauche, centre et droite sont des indications éditoriales simplifiées. Ils ne résument pas les courants, les alliances ou toutes les positions d’un parti. Les couleurs servent à identifier les fiches, sans ordre de préférence.',
              style: TextStyle(color: Civic.muted, height: 1.6),
            ),
            const SizedBox(height: 20),
            Text(
              'Version documentaire du ${politicalDate(catalog.checkedAt)}. Lecture hors ligne ; les annonces postérieures nécessitent une nouvelle édition du dossier.',
              style: const TextStyle(color: Civic.muted, height: 1.6),
            ),
            for (final candidate in catalog.additionalCandidates) ...[
              const SizedBox(height: 22),
              PoliticalPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PoliticalLabel('HORS DES FICHES PARTIS'),
                    const SizedBox(height: 12),
                    Text(candidate.name, style: Civic.heading(22)),
                    const SizedBox(height: 8),
                    Text(
                      candidate.affiliation,
                      style: const TextStyle(color: Civic.muted, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      candidate.summary,
                      style: const TextStyle(color: Civic.ink, height: 1.6),
                    ),
                    for (final proposal in candidate.proposals)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              proposal.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Civic.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              proposal.context,
                              style: const TextStyle(
                                color: Civic.muted,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final unknown in candidate.unknowns)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          unknown,
                          style: const TextStyle(
                            color: Civic.muted,
                            height: 1.6,
                          ),
                        ),
                      ),
                    SourcesButton(sources: candidate.sources),
                  ],
                ),
              ),
            ],
            SourcesButton(
              sources: catalog.sources,
              label: 'Règles de la présidentielle',
            ),
          ],
        ),
      ),
    ),
  );
}
