/// Documentary data, deliberately independent from Flutter presentation.
class PoliticalSource {
  const PoliticalSource({
    required this.id,
    required this.title,
    required this.publisher,
    required this.url,
    required this.checkedAt,
    this.publishedAt,
  });
  final String id, title, publisher, url, checkedAt;
  final String? publishedAt;
  factory PoliticalSource.fromJson(Map<String, dynamic> json) =>
      PoliticalSource(
        id: json['id'] as String,
        title: json['title'] as String,
        publisher: json['publisher'] as String,
        url: json['url'] as String,
        publishedAt: json['publishedAt'] as String?,
        checkedAt: json['checkedAt'] as String,
      );
}

class PoliticalPerson {
  const PoliticalPerson({
    required this.name,
    required this.role,
    required this.sourceIds,
  });
  final String name, role;
  final List<String> sourceIds;
  factory PoliticalPerson.fromJson(Map<String, dynamic> json) =>
      PoliticalPerson(
        name: json['name'] as String,
        role: (json['role'] ?? json['status'] ?? '') as String,
        sourceIds: List<String>.unmodifiable(json['sourceIds'] as List),
      );
}

class PresidentialPosition {
  const PresidentialPosition({
    required this.status,
    required this.summary,
    required this.people,
    required this.sourceIds,
  });
  final String status, summary;
  final List<PoliticalPerson> people;
  final List<String> sourceIds;
  bool get isDeclared => status == 'declared';
  String get label => switch (status) {
    'declared' => 'Candidature déclarée',
    'selection_pending' => 'Désignation en cours',
    'conditional' => 'Candidature conditionnelle',
    'support' => 'Soutien à une candidature',
    'withdrawn' => 'Candidature retirée',
    _ => 'Situation à confirmer',
  };
  factory PresidentialPosition.fromJson(Map<String, dynamic> json) =>
      PresidentialPosition(
        status: json['status'] as String,
        summary: json['summary'] as String,
        people: List.unmodifiable(
          (json['people'] as List).map((p) => PoliticalPerson.fromJson(p)),
        ),
        sourceIds: List<String>.unmodifiable(json['sourceIds'] as List),
      );
}

class PoliticalProposal {
  const PoliticalProposal({
    required this.id,
    required this.theme,
    required this.title,
    required this.summary,
    required this.detail,
    required this.context,
    required this.sourceIds,
  });
  final String id, theme, title, summary, detail, context;
  final List<String> sourceIds;
  factory PoliticalProposal.fromJson(Map<String, dynamic> json) =>
      PoliticalProposal(
        id: json['id'] as String,
        theme: json['theme'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        detail: json['detail'] as String,
        context: json['context'] as String,
        sourceIds: List<String>.unmodifiable(json['sourceIds'] as List),
      );
}

class PoliticalParty {
  const PoliticalParty({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.description,
    required this.leadership,
    required this.election2027,
    required this.proposals,
    required this.sources,
    required this.officialWebsite,
    required this.notes,
    required this.unknowns,
  });
  final String id, name, abbreviation, description, officialWebsite;
  final List<PoliticalPerson> leadership;
  final PresidentialPosition election2027;
  final List<PoliticalProposal> proposals;
  final List<PoliticalSource> sources;
  final List<String> notes, unknowns;
  List<PoliticalSource> sourcesFor(List<String> ids) =>
      sources.where((s) => ids.contains(s.id)).toList(growable: false);
  bool matches(String query) => normalizePoliticalSearch(
    [
      name,
      abbreviation,
      ...leadership.map((p) => p.name),
      ...election2027.people.map((p) => p.name),
      ...proposals.expand((p) => [p.theme, p.title, p.summary]),
    ].join(' '),
  ).contains(normalizePoliticalSearch(query.trim()));
  factory PoliticalParty.fromJson(Map<String, dynamic> json) => PoliticalParty(
    id: json['id'] as String,
    name: json['name'] as String,
    abbreviation: json['abbreviation'] as String,
    description: json['description'] as String,
    leadership: List.unmodifiable(
      (json['leadership'] as List).map((p) => PoliticalPerson.fromJson(p)),
    ),
    election2027: PresidentialPosition.fromJson(json['election2027']),
    proposals: List.unmodifiable(
      (json['proposals'] as List).map((p) => PoliticalProposal.fromJson(p)),
    ),
    sources: List.unmodifiable(
      (json['sources'] as List).map((s) => PoliticalSource.fromJson(s)),
    ),
    officialWebsite: json['officialWebsite'] as String,
    notes: List<String>.unmodifiable(json['notes'] as List),
    unknowns: List<String>.unmodifiable(json['unknowns'] as List),
  );
}

class IndependentCandidacy {
  const IndependentCandidacy({
    required this.name,
    required this.affiliation,
    required this.summary,
    required this.proposals,
    required this.sources,
    required this.unknowns,
  });
  final String name, affiliation, summary;
  final List<PoliticalProposal> proposals;
  final List<PoliticalSource> sources;
  final List<String> unknowns;
  factory IndependentCandidacy.fromJson(Map<String, dynamic> json) =>
      IndependentCandidacy(
        name: json['name'] as String,
        affiliation: json['affiliation'] as String,
        summary: json['summary'] as String,
        proposals: List.unmodifiable(
          (json['proposals'] as List).map((p) => PoliticalProposal.fromJson(p)),
        ),
        sources: List.unmodifiable(
          (json['sources'] as List).map((s) => PoliticalSource.fromJson(s)),
        ),
        unknowns: List<String>.unmodifiable(json['unknowns'] as List),
      );
}

class PoliticalCatalog {
  const PoliticalCatalog({
    required this.checkedAt,
    required this.scope,
    required this.electionNotice,
    this.additionalCandidates = const [],
    required this.parties,
    required this.sources,
  });
  final String checkedAt, scope, electionNotice;
  final List<IndependentCandidacy> additionalCandidates;
  final List<PoliticalParty> parties;
  final List<PoliticalSource> sources;
  factory PoliticalCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported political catalog version');
    }
    final parties =
        (json['parties'] as List)
            .map((p) => PoliticalParty.fromJson(p))
            .toList()
          ..sort(
            (a, b) => normalizePoliticalSearch(
              a.name,
            ).compareTo(normalizePoliticalSearch(b.name)),
          );
    return PoliticalCatalog(
      additionalCandidates: List.unmodifiable(
        ((json['additionalCandidates'] ?? []) as List).map(
          (c) => IndependentCandidacy.fromJson(c),
        ),
      ),
      checkedAt: json['checkedAt'] as String,
      scope: json['scope'] as String,
      electionNotice: json['electionNotice'] as String,
      parties: List.unmodifiable(parties),
      sources: List.unmodifiable(
        (json['sources'] as List).map((s) => PoliticalSource.fromJson(s)),
      ),
    );
  }
}

String normalizePoliticalSearch(String text) {
  var value = text.toLowerCase();
  const replacements = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'œ': 'oe',
    '’': "'",
  };
  replacements.forEach((from, to) => value = value.replaceAll(from, to));
  return value;
}

String politicalDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
