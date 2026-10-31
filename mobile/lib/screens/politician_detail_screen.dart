import 'package:flutter/material.dart';
import '../models/political_party.dart';
import '../models/political_portraits.dart';
import '../theme/civic_theme.dart';
import '../widgets/political_components.dart';

/// Separates organisational office holders from presidential contenders.
/// No old portrait, constituency or seat is inferred from a party affiliation.
class PoliticianDetailScreen extends StatelessWidget {
  const PoliticianDetailScreen({super.key, required this.party});
  final PoliticalParty party;
  @override
  Widget build(BuildContext context) => PoliticalPage(
    title: 'Les personnes · ${party.abbreviation}',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: PartyMark(party, size: 62),
        ),
        const SizedBox(height: 22),
        Text('Qui fait quoi ?', style: Civic.heading(34)),
        const SizedBox(height: 12),
        Text(
          party.name,
          style: const TextStyle(color: Civic.muted, fontSize: 16),
        ),
        const SizedBox(height: 26),
        Text('La direction du parti', style: Civic.heading(23)),
        const SizedBox(height: 14),
        if (party.leadership.isEmpty)
          const PoliticalPanel(
            child: Text('Direction actuelle non vérifiée dans ce dossier.'),
          ),
        for (final person in party.leadership)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _person(context, person),
          ),
        const SizedBox(height: 18),
        Text('Pour la présidentielle', style: Civic.heading(23)),
        const SizedBox(height: 14),
        PoliticalPanel(
          blue: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                party.election2027.label,
                style: Civic.heading(20, color: Civic.blue),
              ),
              const SizedBox(height: 12),
              Text(
                party.election2027.summary,
                style: const TextStyle(height: 1.6, color: Civic.ink),
              ),
              SourcesButton(
                sources: party.sourcesFor(party.election2027.sourceIds),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final person in party.election2027.people)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _person(context, person),
          ),
        const SizedBox(height: 12),
        const Text(
          'Diriger un parti et être candidat sont deux fonctions distinctes. Une candidature annoncée reste soumise aux conditions légales et à la validation du Conseil constitutionnel.',
          style: TextStyle(color: Civic.muted, height: 1.65),
        ),
      ],
    ),
  );

  Widget _person(BuildContext context, PoliticalPerson person) {
    final portrait = politicalPortraits[person.name];
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return PoliticalPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (largeText) ...[
            _portrait(person, portrait),
            const SizedBox(height: 12),
            Text(person.name, style: Civic.heading(22)),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _portrait(person, portrait),
                const SizedBox(width: 15),
                Expanded(child: Text(person.name, style: Civic.heading(22))),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            person.role,
            style: const TextStyle(color: Civic.muted, height: 1.55),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: [
              SourcesButton(sources: party.sourcesFor(person.sourceIds)),
              if (portrait != null)
                TextButton.icon(
                  onPressed: () => _photoCredit(context, portrait),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Crédit photo'),
                  style: TextButton.styleFrom(
                    foregroundColor: Civic.blue,
                    minimumSize: const Size(48, 48),
                  ),
                ),
            ],
          ),
          if (portrait == null)
            const Text(
              'Portrait indisponible en licence réutilisable.',
              style: TextStyle(color: Civic.muted, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _portrait(PoliticalPerson person, PoliticalPortrait? portrait) {
    final initials = person.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    Widget fallback() => Center(
      child: Text(initials, style: Civic.heading(24, color: Civic.blue)),
    );
    return Semantics(
      label: portrait == null
          ? 'Portrait indisponible de ${person.name}'
          : 'Portrait de ${person.name}',
      image: portrait != null,
      child: Container(
        width: 78,
        height: 84,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Civic.pale,
          borderRadius: BorderRadius.circular(16),
        ),
        child: portrait == null
            ? fallback()
            : Image.asset(
                portrait.asset,
                key: ValueKey('portrait-image-${person.name}'),
                fit: BoxFit.cover,
                cacheWidth: 240,
                errorBuilder: (context, error, stackTrace) => fallback(),
              ),
      ),
    );
  }

  void _photoCredit(
    BuildContext context,
    PoliticalPortrait portrait,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Civic.paper,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Crédit photo', style: Civic.heading(24))),
              IconButton(
                tooltip: 'Fermer le crédit photo',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Auteur : ${portrait.author}'),
          const SizedBox(height: 7),
          Text('Licence : ${portrait.license}'),
          const SizedBox(height: 7),
          const Text(
            'Miniature Wikimedia Commons ; affichage recadré dans la fiche.',
            style: TextStyle(color: Civic.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => openPoliticalSource(context, portrait.sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Voir la photo et sa source'),
          ),
          if (portrait.licenseUrl.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  openPoliticalSource(context, portrait.licenseUrl),
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('Lire la licence'),
            ),
        ],
      ),
    ),
  );
}
