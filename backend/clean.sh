#!/bin/bash
echo "Nettoyage des fichiers temporaires Python..."

sudo find . -type d -name "__pycache__" -exec rm -rf {} +

rm -f .coverage

echo "Terminé : Tous les dossiers __pycache__ ont été supprimés."
