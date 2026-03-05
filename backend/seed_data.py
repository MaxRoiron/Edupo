import os
import sys

# Add the app path to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), "app"))

from app.core.database import engine
from sqlmodel import Session, select
from app.modules.user_data.model import ProfessionalStatus, GenderIdentities

professional_statuses = [
    'Étudiant(e)', 'Lycéen(ne)', 'Apprenti(e)', 'Stagiaire', 'Demandeur d\'emploi',
    'Salarié(e)', 'Cadre', 'Ingénieur(e)', 'Technicien(ne)', 'Ouvrier / Ouvrière',
    'Artisan(e)', 'Commerçant(e)', 'Chef(fe) d\'entreprise', 'Auto-entrepreneur(e)',
    'Profession libérale', 'Fonctionnaire', 'Enseignant(e)', 'Chercheur(se)',
    'Médecin / Santé', 'Avocat(e) / Juridique', 'Restauration / Hôtellerie',
    'Agriculture', 'Artiste / Créatif', 'Journaliste / Média', 'Militaire',
    'Retraité(e)', 'Au foyer', 'Autre'
]

genders = [
    'Homme', 'Femme', 'Non-binaire', 'Genderqueer', 'Genderfluid', 'Agenre',
    'Bigenre', 'Demigarçon', 'Demifille', 'Transgenre', 'Two-Spirit', 'Autre',
    'Non renseigné'
]

def seed_data():
    with Session(engine) as session:
        for status_name in professional_statuses:
            existing = session.exec(select(ProfessionalStatus).where(ProfessionalStatus.name == status_name)).first()
            if not existing:
                session.add(ProfessionalStatus(name=status_name))
        
        for gender_name in genders:
            existing = session.exec(select(GenderIdentities).where(GenderIdentities.name == gender_name)).first()
            if not existing:
                session.add(GenderIdentities(name=gender_name))
                
        session.commit()
        print("Done seeding user data.")

if __name__ == "__main__":
    seed_data()
