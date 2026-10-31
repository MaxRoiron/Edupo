import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/political_party.dart';
import '../theme/civic_theme.dart';
import 'civic_components.dart';

/// Shared frame for every public political reading surface.
class PoliticalPage extends StatelessWidget {
  const PoliticalPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: Civic.theme(context),
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Civic.paper,
        appBar: AppBar(
          backgroundColor: Civic.paper,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Civic.ink,
          title: Text(title, style: Civic.heading(17)),
          leading: BackButton(onPressed: () => Navigator.maybePop(context)),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

class PoliticalPanel extends StatelessWidget {
  const PoliticalPanel({super.key, required this.child, this.blue = false});
  final Widget child;
  final bool blue;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: blue ? Civic.pale : Colors.white,
      border: Border.all(color: blue ? Civic.pale : Civic.line),
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class PoliticalLabel extends StatelessWidget {
  const PoliticalLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Civic.pale,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Civic.blue,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class PartyMark extends StatelessWidget {
  const PartyMark(this.party, {super.key, this.size = 52});
  final PoliticalParty party;
  final double size;
  static const logos = {
    'lfi': 'lfilogo.png',
    'ps': 'pslogo.png',
    'ecologistes': 'ellvlogo.png',
    'renaissance': 'relogo.png',
    'lr': 'lrlogo.png',
    'rn': 'rnlogo.png',
    'reconquete': 'r!logo.png',
    'pcf': 'pcflogo.png',
  };
  @override
  Widget build(BuildContext context) {
    final logo = logos[party.id];
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Civic.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: logo == null
            ? Center(
                child: FittedBox(
                  child: Text(
                    party.abbreviation,
                    style: Civic.heading(18, color: Civic.blue),
                  ),
                ),
              )
            : Image.asset(
                'assets/images/$logo',
                fit: BoxFit.contain,
                cacheWidth: 150,
              ),
      ),
    );
  }
}

IconData politicalThemeIcon(String theme) =>
    switch (normalizePoliticalSearch(theme)) {
      'economie' ||
      'pouvoir d\'achat' ||
      'fiscalite' ||
      'travail' => Icons.account_balance_wallet_outlined,
      'ecologie' || 'environnement' || 'energie' => Icons.eco_outlined,
      'sante' ||
      'protection sociale' ||
      'retraites' => Icons.favorite_outline_rounded,
      'education' => Icons.school_outlined,
      'institutions' || 'democratie' => Icons.account_balance_outlined,
      'europe' || 'international' => Icons.public_rounded,
      'immigration' => Icons.people_outline_rounded,
      'securite' || 'justice' => Icons.balance_rounded,
      _ => Icons.article_outlined,
    };

class ProposalCard extends StatelessWidget {
  const ProposalCard({
    super.key,
    required this.proposal,
    required this.onTap,
    this.party,
  });
  final PoliticalProposal proposal;
  final PoliticalParty? party;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Civic.line),
    ),
    child: CivicPress(
      onTap: onTap,
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  politicalThemeIcon(proposal.theme),
                  size: 20,
                  color: Civic.blue,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    party == null
                        ? proposal.theme
                        : '${party!.abbreviation} · ${proposal.theme}',
                    style: const TextStyle(
                      color: Civic.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 20,
                  color: Civic.blue,
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(proposal.title, style: Civic.heading(20)),
            const SizedBox(height: 10),
            Text(
              proposal.summary,
              style: const TextStyle(
                color: Civic.muted,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              proposal.context,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Civic.blue,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SourcesButton extends StatelessWidget {
  const SourcesButton({super.key, required this.sources, this.label});
  final List<PoliticalSource> sources;
  final String? label;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    style: TextButton.styleFrom(
      foregroundColor: Civic.blue,
      minimumSize: const Size(48, 48),
      alignment: Alignment.centerLeft,
    ),
    onPressed: sources.isEmpty
        ? null
        : () => showPoliticalSources(context, sources),
    icon: const Icon(Icons.menu_book_outlined, size: 19),
    label: Text(
      label ?? '${sources.length} source${sources.length > 1 ? 's' : ''}',
      softWrap: true,
    ),
  );
}

void showPoliticalSources(BuildContext context, List<PoliticalSource> sources) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Civic.paper,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: .86,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 12, 12),
            child: Row(
              children: [
                Expanded(child: Text('Les sources', style: Civic.heading(26))),
                IconButton(
                  tooltip: 'Fermer les sources',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 0, 22, 15),
            child: Text(
              'Les propositions sont résumées par Édupo. Les liens permettent de consulter les documents et annonces d’origine.',
              style: TextStyle(color: Civic.muted, height: 1.5),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              itemCount: sources.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => SourceTile(sources[index]),
            ),
          ),
        ],
      ),
    ),
  );
}

class SourceTile extends StatelessWidget {
  const SourceTile(this.source, {super.key});
  final PoliticalSource source;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Civic.line),
    ),
    child: CivicPress(
      radius: 18,
      onTap: () => openPoliticalSource(context, source.url),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.publisher,
              style: const TextStyle(
                color: Civic.blue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(source.title, style: Civic.heading(16)),
            const SizedBox(height: 9),
            Text(
              source.publishedAt == null
                  ? 'Date de publication non indiquée'
                  : 'Publié le ${politicalDate(source.publishedAt!)}',
              style: const TextStyle(color: Civic.muted, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              'Consulté le ${politicalDate(source.checkedAt)}',
              style: const TextStyle(color: Civic.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    Uri.tryParse(source.url)?.host ?? source.url,
                    style: const TextStyle(color: Civic.blue, fontSize: 12),
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  color: Civic.blue,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> openPoliticalSource(BuildContext context, String url) async {
  try {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const FormatException('Source unavailable');
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Impossible d’ouvrir cette source.'),
        action: SnackBarAction(
          label: 'Copier le lien',
          onPressed: () => Clipboard.setData(ClipboardData(text: url)),
        ),
      ),
    );
  }
}

ChipAnimationStyle politicalChipMotion(BuildContext context) {
  final animation = AnimationStyle(
    duration: Civic.duration(context),
    reverseDuration: Civic.duration(context),
  );
  return ChipAnimationStyle(
    enableAnimation: animation,
    selectAnimation: animation,
    avatarDrawerAnimation: animation,
    deleteDrawerAnimation: animation,
  );
}

class PoliticalChoiceChip extends StatelessWidget {
  const PoliticalChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
    chipAnimationStyle: politicalChipMotion(context),
    showCheckmark: false,
    selectedColor: Civic.blue,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      color: selected ? Colors.white : Civic.ink,
      fontWeight: FontWeight.w700,
    ),
    side: BorderSide(color: selected ? Civic.blue : Civic.line),
  );
}
