import 'package:flutter/material.dart';
import '../models/political_party.dart';
import '../theme/civic_theme.dart';
import '../widgets/political_components.dart';

class TextReaderScreen extends StatelessWidget {
  const TextReaderScreen({
    super.key,
    required this.party,
    required this.proposal,
  });
  final PoliticalParty party;
  final PoliticalProposal proposal;
  @override
  Widget build(BuildContext context) => PoliticalPage(
    title: 'Comprendre la mesure',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              politicalThemeIcon(proposal.theme),
              color: Civic.blue,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${party.abbreviation} · ${proposal.theme}',
                style: const TextStyle(
                  color: Civic.blue,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(proposal.title, style: Civic.heading(33)),
        const SizedBox(height: 20),
        Text(
          proposal.summary,
          style: const TextStyle(color: Civic.ink, fontSize: 19, height: 1.65),
        ),
        const SizedBox(height: 24),
        PoliticalPanel(
          blue: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LE CONTEXTE',
                style: TextStyle(
                  color: Civic.blue,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                proposal.context,
                style: const TextStyle(color: Civic.ink, height: 1.65),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Ce qui est proposé', style: Civic.heading(23)),
        const SizedBox(height: 16),
        SelectableText(
          proposal.detail,
          style: const TextStyle(color: Civic.ink, fontSize: 17, height: 1.8),
        ),
        const SizedBox(height: 28),
        const Divider(color: Civic.line),
        const SizedBox(height: 18),
        Text('Pour aller plus loin', style: Civic.heading(23)),
        const SizedBox(height: 12),
        const Text(
          'Quel calendrier, quel financement et quelles conditions de mise en œuvre ? Pour évaluer cette proposition, consultez les précisions et les limites du document d’origine.',
          style: TextStyle(color: Civic.muted, height: 1.65),
        ),
        const SizedBox(height: 22),
        for (final source in party.sourcesFor(proposal.sourceIds))
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SourceTile(source),
          ),
        const Text(
          'Synthèse Édupo. Il s’agit d’une proposition politique, pas d’une mesure déjà en vigueur.',
          style: TextStyle(color: Civic.muted, height: 1.6, fontSize: 12),
        ),
      ],
    ),
  );
}
