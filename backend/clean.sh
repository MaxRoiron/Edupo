#!/bin/bash
# Script pour supprimer récursivement tous les dossiers __pycache__
echo "Nettoyage des fichiers temporaires Python..."

find . -type d -name "__pycache__" -exec rm -rf {} +

echo "Terminé : Tous les dossiers __pycache__ ont été supprimés."
