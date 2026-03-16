#!/bin/bash
echo "Nettoyage des fichiers temporaires Python..."

sudo find . -type d -name "__pycache__" -exec rm -rf {} +

rm -f .coverage coverage.xml

sudo rm -rf .pytest_cache