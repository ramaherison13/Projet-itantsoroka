#!/bin/bash
# Script de lancement Flutter Web en mode développement
# Désactive les restrictions CORS du navigateur pour permettre
# les appels API cross-origin depuis localhost.
#
# Usage: ./run_web_dev.sh [port]
# Exemple: ./run_web_dev.sh 8080

PORT=${1:-40185}

# ── CORRECTIF ERREUR PERMISSION (étape 1) ─────────────────────────────────────
# Flutter peut tenter d'écrire ses Native Assets sur un disque externe monté
# dans /media (ex: Mah'hery). On force le cache vers le répertoire home.
export PUB_CACHE="$HOME/.pub-cache"

# S'assurer que le dossier chrome dev est dans le home et non sur un disque externe
CHROME_DIR="$HOME/.flutter_chrome_dev"
mkdir -p "$CHROME_DIR"

echo "🚀 Lancement de l'app Flutter Web en mode DEV (CORS désactivé)..."
echo "   Port: $PORT"
echo "   URL: http://localhost:$PORT"
echo "   Chrome data dir: $CHROME_DIR"
echo ""
echo "⚠️  NOTE: Ce script désactive la sécurité CORS uniquement pour le développement local."
echo "   Ne pas utiliser en production."
echo ""

flutter run -d chrome \
  --web-port=$PORT \
  --web-browser-flag="--disable-web-security" \
  --web-browser-flag="--user-data-dir=$CHROME_DIR"
