import os
import sys
import datetime
import hashlib
from app.core.config import settings
from app.modules.law.text import clean_law_title, subject_title

sys.path.append(os.path.join(os.path.dirname(__file__), "app"))

from app.core.database import engine
from sqlmodel import Session, select
from app.modules.law.model import Law
from app.modules.political_party.model import Domain
from app.modules.country.model import Country

# Demonstration content only: never import these examples into the real feed.
# Dates and vote numbers below are kept as historical fixture metadata.
# 10 upcoming, 10 past
laws_data = [
    # ---- DÉJÀ VOTÉES (past laws, vote_date < now) ----
    {
        "title": "Majorité numérique et lutte contre la haine en ligne",
        "subtitle": "Instauration de la majorité numérique à 15 ans pour protéger les mineurs.",
        "description": "Cette loi impose aux réseaux sociaux de vérifier l'âge des utilisateurs et d'obtenir l'accord des parents pour l'inscription des moins de 15 ans. Elle renforce aussi la lutte contre le cyberharcèlement.",
        "vote_date": datetime.datetime(2023, 6, 28, tzinfo=datetime.timezone.utc),
        "scrutin_id": "1940",
        "category": "Numérique & Jeunesse",
    },
    {
        "title": "Aide financière pour le permis de conduire",
        "subtitle": "Création d'une plateforme nationale et extension de l'aide au permis.",
        "description": "Loi visant à étendre le financement du permis de conduire via le CPF et simplifier les démarches des jeunes pour faciliter leur mobilité et accès à l'emploi.",
        "vote_date": datetime.datetime(2023, 6, 12, tzinfo=datetime.timezone.utc),
        "scrutin_id": "1738",
        "category": "Transports & Emploi",
    },
    {
        "title": "Repas à 1 euro pour les étudiants boursiers",
        "subtitle": "Pérennisation du tarif très social du repas au CROUS.",
        "description": "Un texte très commenté visant à ouvrir ou pérenniser le repas à 1 euro pour aider les étudiants face à l'inflation. (Note: Initialement rejeté lors d'un vote serré puis adapté).",
        "vote_date": datetime.datetime(2023, 2, 9, tzinfo=datetime.timezone.utc),
        "scrutin_id": "998",
        "category": "Social & Étudiants",
    },
    {
        "title": "Loi pour le pouvoir d'achat",
        "subtitle": "Bouclier loyer et aides exceptionnelles de rentrée.",
        "description": "Mesures d'urgence comprenant la revalorisation des bourses étudiantes, des aides personnalisées au logement (APL), et le blocage des loyers.",
        "vote_date": datetime.datetime(2022, 7, 22, tzinfo=datetime.timezone.utc),
        "scrutin_id": "146",
        "category": "Économie",
    },
    {
        "title": "Loi contre le Harcèlement scolaire",
        "subtitle": "Le harcèlement scolaire devient un délit pénal autonome.",
        "description": "Loi fondamentale qui crée un délit spécifique de harcèlement scolaire avec des peines pouvant aller jusqu'à 10 ans d'emprisonnement et 150 000 euros d'amende en cas de suicide.",
        "vote_date": datetime.datetime(2022, 2, 24, tzinfo=datetime.timezone.utc),
        "scrutin_id": "4220",  # Estimé
        "category": "Éducation",
    },
    {
        "title": "Protection de l'environnement et Climat",
        "subtitle": "Loi 'Climat et résilience' issue de la Convention citoyenne.",
        "description": "Un texte massif interdisant les vols intérieurs courts, créant les Zones à Faibles Émissions (ZFE), et interdisant à la location les passoires thermiques, touchant fortement la nouvelle génération.",
        "vote_date": datetime.datetime(2021, 7, 20, tzinfo=datetime.timezone.utc),
        "scrutin_id": "3915",
        "category": "Écologie",
    },
    {
        "title": "Loi sur l'IVG dans la Constitution",
        "subtitle": "Inscription de la liberté de recourir à l'IVG dans la Constitution.",
        "description": "Ce texte inscrit la liberté garantie d'avoir recours à une interruption volontaire de grossesse, une avancée historique pour les droits des femmes en France.",
        "vote_date": datetime.datetime(2024, 1, 30, tzinfo=datetime.timezone.utc),
        "scrutin_id": "3333",
        "category": "Santé & Éthique",
    },
    {
        "title": "Interdiction des 'Puffs'",
        "subtitle": "Interdiction des cigarettes électroniques jetables.",
        "description": "Loi visant à interdire la fabrication, la vente et l'offre des 'Puffs', très populaires chez les jeunes, pour des raisons de santé publique et d'écologie.",
        "vote_date": datetime.datetime(2023, 12, 4, tzinfo=datetime.timezone.utc),
        "scrutin_id": "3045",
        "category": "Santé",
    },
    {
        "title": "Loi sur l'influence commerciale (Influenceurs)",
        "subtitle": "Encadrement de la profession d'influenceur et lutte contre les dérives.",
        "description": "Première loi en Europe qui donne un statut aux influenceurs et leur interdit la promotion de certains produits liés à la santé, la cryptomonnaie ou la chirurgie esthétique.",
        "vote_date": datetime.datetime(2023, 5, 31, tzinfo=datetime.timezone.utc),
        "scrutin_id": "1642",
        "category": "Numérique & Économie",
    },
    {
        "title": "Loi Immigration 2024",
        "subtitle": "Durcissement des règles relatives aux étudiants internationaux.",
        "description": "La loi immigration, qui a notamment instauré des mesures controversées concernant les cautions pour les étudiants étrangers.",
        "vote_date": datetime.datetime(2023, 12, 19, tzinfo=datetime.timezone.utc),
        "scrutin_id": "3213",
        "category": "Intérieur",
    },
    # ---- À VENIR (upcoming laws, vote_date > now) ----
    {
        "title": "Loi sur la Fin de vie",
        "subtitle": "Projet de loi relatif à l'accompagnement des malades et de la fin de vie.",
        "description": "Légalisation de l'aide à mourir sous conditions strictes pour les patients en phase terminale, très suivie par les jeunes adultes pour leurs proches.",
        "vote_date": datetime.datetime(2026, 6, 11, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9001",
        "category": "Santé & Éthique",
    },
    {
        "title": "Généralisation du SNU",
        "subtitle": "Rendre le Service National Universel obligatoire.",
        "description": "Projet de loi visant à rendre le Service National Universel (SNU) obligatoire sur le temps scolaire pour tous les jeunes en classe de seconde.",
        "vote_date": datetime.datetime(2026, 4, 25, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9002",
        "category": "Jeunesse & Défense",
    },
    {
        "title": "Légalisation du Cannabis Récréatif",
        "subtitle": "Proposition visant à légaliser et encadrer la vente de cannabis.",
        "description": "Proposition de loi portée par plusieurs groupes politiques visant à légaliser le cannabis récréatif pour en reprendre le contrôle à l'économie souterraine.",
        "vote_date": datetime.datetime(2026, 5, 14, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9003",
        "category": "Justice & Santé",
    },
    {
        "title": "Semaine de 4 Jours",
        "subtitle": "Réforme sur l'organisation et le temps de travail hebdomadaire.",
        "description": "Projet de loi facilitant l'expérimentation de la semaine de 4 jours pour améliorer l'équilibre vie pro / vie perso.",
        "vote_date": datetime.datetime(2026, 7, 10, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9004",
        "category": "Travail",
    },
    {
        "title": "Transports en Commun Gratuits pour les -26 ans",
        "subtitle": "Pass Jeune National pour la gratuité des TER et TGV.",
        "description": "Instauration de la gratuité totale des transports régionaux et nationaux pour les jeunes afin de soutenir la lutte contre le réchauffement climatique.",
        "vote_date": datetime.datetime(2026, 4, 18, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9005",
        "category": "Social & Écologie",
    },
    {
        "title": "Encadrement strict de l'IA (IA Act national)",
        "subtitle": "Loi de transposition sur l'Intelligence Artificielle en France.",
        "description": "Réglementation de l'utilisation de l'intelligence artificielle dans l'éducation nationale, l'université, et l'emploi.",
        "vote_date": datetime.datetime(2026, 5, 2, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9006",
        "category": "Numérique",
    },
    {
        "title": "Création du Droit à l'Erreur Administrative Étudiant",
        "subtitle": "Soutien aux démarches Parcoursup et Crous.",
        "description": "Garantit qu'aucune pénalité ou perte de droit ne sera appliquée lors d'un retard initial ou d'une erreur excusable sur les dossiers étudiants.",
        "vote_date": datetime.datetime(2026, 6, 20, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9007",
        "category": "Enseignement Supérieur",
    },
    {
        "title": "Congé Menstruel Étudiant et Salarié",
        "subtitle": "13 jours supplémentaires fractionnables par an.",
        "description": "La prise en de douleur liées aux règles s'apparente à l'arrêt maladie : cette loi permet d'obtenir un arrêt spécifique, sans délai de carence, à l'université ou en entreprise.",
        "vote_date": datetime.datetime(2026, 8, 10, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9008",
        "category": "Santé & Égalité",
    },
    {
        "title": "Revenu Minimum Universel Jeune",
        "subtitle": "Attribution automatique d'une allocation d'autonomie dès 18 ans.",
        "description": "Ce revenu s'adresse à tous les jeunes majeurs, étudiants ou non, pour lutter contre la précarité grandissante et garantir l'indépendance de la jeunesse.",
        "vote_date": datetime.datetime(2026, 9, 21, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9009",
        "category": "Société & Économie",
    },
    {
        "title": "Fast-Fashion et pénalité écologique",
        "subtitle": "Taxation exceptionnelle des entreprises de la Fast-Fashion.",
        "description": "Application d'un malus environnemental systématique par article de mode issu de marques type Shein ou Temu pour protéger l'industrie locale et l'environnement.",
        "vote_date": datetime.datetime(2026, 4, 30, tzinfo=datetime.timezone.utc),
        "scrutin_id": "9010",
        "category": "Écologie & Mode",
    },
]


def seed():
    if not any(word in settings.POSTGRES_DB.lower() for word in ("demo", "test")):
        raise RuntimeError("Données de démonstration réservées à une base demo/test")
    with Session(engine) as session:
        # Create a generic Country France if doesn't exist
        country = session.exec(select(Country).where(Country.name == "France")).first()
        if not country:
            country = Country(name="France", iso_code="FR")
            session.add(country)
            session.commit()
            session.refresh(country)

        # Create default domain
        domain = session.exec(select(Domain).where(Domain.name == "Général")).first()
        if not domain:
            domain = Domain(name="Général")
            session.add(domain)
            session.commit()
            session.refresh(domain)

        for data in laws_data:
            existing = session.exec(
                select(Law).where(
                    Law.source_key
                    == "demo:" + hashlib.sha256(data["title"].encode()).hexdigest()
                )
            ).first()
            if not existing:
                l = Law(
                    title=clean_law_title(data["title"]),
                    official_title=data["title"],
                    short_title=subject_title(data["title"]),
                    source="demo",
                    status="pending",
                    source_key="demo:"
                    + hashlib.sha256(data["title"].encode()).hexdigest(),
                    legacy_data={**data, "vote_date": data["vote_date"].isoformat()},
                    description=data["description"],
                    domain_id=domain.id,
                    country_id=country.id,
                    vote_date=None,
                    scrutin_id=None,
                    category=data["category"],
                )
                session.add(l)

        session.commit()
        print("Données de démonstration créées dans la base dédiée.")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Exemples fictifs pour une base de démonstration dédiée"
    )
    parser.add_argument(
        "--demo",
        action="store_true",
        help="Accepter explicitement les données de démonstration",
    )
    if not parser.parse_args().demo:
        parser.error("--demo requis; ces fiches ne sont pas des scrutins officiels")
    seed()
