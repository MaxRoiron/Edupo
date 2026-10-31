import 'package:flutter/material.dart';

/// Editorial orientation for navigation, not an official electoral designation.
/// Keep this map explicit: a new party should receive a reviewed label and colour.
class PoliticalIdentity {
  const PoliticalIdentity(this.position, this.color);

  final String position;
  final Color color;

  Color get surface => Color.lerp(Colors.white, color, .075)!;
  Color get border => Color.lerp(Colors.white, color, .24)!;
  Color get flagSurface => Color.lerp(Colors.white, color, .17)!;
}

const politicalIdentities = <String, PoliticalIdentity>{
  'lfi': PoliticalIdentity('Gauche', Color(0xFF61259D)),
  'ps': PoliticalIdentity('Gauche', Color(0xFFC43D64)),
  'ecologistes': PoliticalIdentity('Gauche', Color(0xFF24815E)),
  'pcf': PoliticalIdentity('Gauche', Color(0xFFB52E37)),
  'place-publique': PoliticalIdentity('Centre gauche', Color(0xFFB34077)),
  'lutte-ouvriere': PoliticalIdentity('Extrême gauche', Color(0xFFAF263D)),
  'npa-revolutionnaires': PoliticalIdentity(
    'Extrême gauche',
    Color(0xFF9A2746),
  ),
  'npa-anticapitaliste': PoliticalIdentity('Extrême gauche', Color(0xFF953454)),
  'debout': PoliticalIdentity('Gauche', Color(0xFFC46538)),
  'apres': PoliticalIdentity('Gauche', Color(0xFF257F84)),
  'revolution-permanente': PoliticalIdentity(
    'Extrême gauche',
    Color(0xFF812852),
  ),
  'renaissance': PoliticalIdentity('Centre', Color(0xFF6852B6)),
  'horizons': PoliticalIdentity('Centre droit', Color(0xFF3A6692)),
  'modem': PoliticalIdentity('Centre', Color(0xFFB66725)),
  'udi': PoliticalIdentity('Centre droit', Color(0xFF4277AA)),
  'lr': PoliticalIdentity('Droite', Color(0xFF295AA5)),
  'rn': PoliticalIdentity('Extrême droite', Color(0xFF304986)),
  'reconquete': PoliticalIdentity('Extrême droite', Color(0xFF443C7C)),
  'udr': PoliticalIdentity('Droite', Color(0xFF365386)),
  'dlf': PoliticalIdentity('Droite', Color(0xFF285F94)),
  'les-patriotes': PoliticalIdentity('Droite', Color(0xFF3C6088)),
  'upr': PoliticalIdentity('Souverainiste', Color(0xFF586274)),
  'resistons': PoliticalIdentity('Centre', Color(0xFF8E6A3B)),
  'nouvelle-energie': PoliticalIdentity('Droite', Color(0xFF167A87)),
  'nous-france': PoliticalIdentity('Droite', Color(0xFF5362A2)),
};

PoliticalIdentity politicalIdentity(String partyId) =>
    politicalIdentities[partyId] ??
    const PoliticalIdentity('À préciser', Color(0xFF606779));

class PoliticalPositionFlag extends StatelessWidget {
  const PoliticalPositionFlag(this.partyId, {super.key});

  final String partyId;

  @override
  Widget build(BuildContext context) {
    final identity = politicalIdentity(partyId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: identity.flagSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 14, color: identity.color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              identity.position,
              softWrap: true,
              style: const TextStyle(
                color: Color(0xFF151B2B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
