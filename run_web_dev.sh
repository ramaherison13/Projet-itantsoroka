#!/bin/bash
# Script de lancement Flutter Web en mode développement
# Désactive les restrictions CORS du navigateur pour permettre
# les appels API cross-origin depuis localhost.
#
# Usage: ./run_web_dev.sh [port]
# Exemple: ./run_web_dev.sh 8080

PORT=${1:-40185}

echo "🚀 Lancement de l'app Flutter Web en mode DEV (CORS désactivé)..."
echo "   Port: $PORT"
echo "   URL: http://localhost:$PORT"
echo ""
echo "⚠️  NOTE: Ce script désactive la sécurité CORS uniquement pour le développement local."
echo "   Ne pas utiliser en production."
echo ""

flutter run -d chrome \
  --web-port=$PORT \
  --web-browser-flag="--disable-web-security" \
  --web-browser-flag="--user-data-dir=/tmp/flutter_chrome_dev"
