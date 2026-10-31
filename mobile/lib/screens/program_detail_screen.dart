import 'package:flutter/material.dart';
import '../models/political_party.dart';
import '../theme/civic_theme.dart';
import '../theme/political_identity.dart';
import '../widgets/civic_components.dart';
import '../widgets/political_components.dart';
import 'politician_detail_screen.dart';
import 'text_reader_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({super.key, required this.party});
  final PoliticalParty party;
  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  String? _theme;
  @override
  Widget build(BuildContext context) {
    final party = widget.party;
    final themes = party.proposals.map((p) => p.theme).toSet().toList()..sort();
    final proposals = party.proposals
        .where((p) => _theme == null || p.theme == _theme)
        .toList();
    return PoliticalPage(
      title: 'Le dossier ${party.abbreviation}',
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PartyMark(party, size: 68),
                  const SizedBox(height: 20),
                  Text(party.name, style: Civic.heading(34)),
                  const SizedBox(height: 12),
                  PoliticalPositionFlag(party.id),
                  const SizedBox(height: 14),
                  Text(
                    party.description,
                    style: const TextStyle(
                      color: Civic.muted,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 26),
                  PoliticalPanel(
                    blue: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRÉSIDENTIELLE 2027',
                          style: TextStyle(
                            color: Civic.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          party.election2027.label,
                          style: Civic.heading(23, color: Civic.blue),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          party.election2027.summary,
                          style: const TextStyle(
                            color: Civic.ink,
                            height: 1.65,
                          ),
                        ),
                        SourcesButton(
                          sources: party.sourcesFor(
                            party.election2027.sourceIds,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CivicButton(
                    label: 'Qui dirige ce parti ?',
                    secondary: true,
                    icon: Icons.people_outline_rounded,
                    onPressed: () => Navigator.push(
                      context,
                      CivicPageRoute(
                        context: context,
                        builder: (_) => PoliticianDetailScreen(party: party),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Les propositions',
                          style: Civic.heading(27),
                        ),
                      ),
                      Text(
                        '${party.proposals.length}',
                        style: Civic.heading(28, color: Civic.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Des mesures publiées par le parti ou sa campagne. Le document et sa date sont précisés pour chaque proposition.',
                    style: TextStyle(color: Civic.muted, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  if (themes.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        PoliticalChoiceChip(
                          label: 'Tous les thèmes',
                          selected: _theme == null,
                          onSelected: () => setState(() => _theme = null),
                        ),
                        for (final theme in themes)
                          PoliticalChoiceChip(
                            label: theme,
                            selected: _theme == theme,
                            onSelected: () => setState(() => _theme = theme),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (party.proposals.isEmpty)
                    const CivicNotice(
                      message:
                          'Aucune proposition suffisamment documentée dans cette édition du dossier.',
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverList.builder(
              itemCount: proposals.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ProposalCard(
                  proposal: proposals[index],
                  onTap: () => Navigator.push(
                    context,
                    CivicPageRoute(
                      context: context,
                      builder: (_) => TextReaderScreen(
                        party: party,
                        proposal: proposals[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (party.notes.isNotEmpty || party.unknowns.isNotEmpty)
                    PoliticalPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.manage_search_rounded,
                            color: Civic.blue,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Pour bien lire ce dossier',
                            style: Civic.heading(22),
                          ),
                          for (final note in party.notes)
                            Padding(
                              padding: const EdgeInsets.only(top: 13),
                              child: Text(
                                note,
                                style: const TextStyle(
                                  color: Civic.muted,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          for (final unknown in party.unknowns)
                            Padding(
                              padding: const EdgeInsets.only(top: 13),
                              child: Text(
                                unknown,
                                style: const TextStyle(
                                  color: Civic.ink,
                                  height: 1.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SourcesButton(
                    sources: party.sources,
                    label:
                        'Toutes les sources du dossier (${party.sources.length})',
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        openPoliticalSource(context, party.officialWebsite),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Consulter le site officiel'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
