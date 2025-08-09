#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 urls.txt"
  exit 1
fi

INPUT=$1
OUTPUT_DIR="server_config_scan"
mkdir -p "$OUTPUT_DIR"

echo "[*] Début analyse configuration serveur..."

while read -r url; do
  echo "[+] Analyse de $url"

  # Nettoyer URL pour enlever protocole pour testssl.sh
  host=$(echo "$url" | sed -E 's|https?://||' | cut -d'/' -f1)

  # 1. Récupération des headers avec httpx
  httpx -silent -title -server -status-code -tech-detect -no-color -o "$OUTPUT_DIR/httpx_${host}.txt" -u "$url"

  # 2. Tester pages d'erreur custom (404, 500)
  for code in 404 500; do
    test_url="${url}/page-that-does-not-exist-${code}"
    echo "[*] Test page erreur $code sur $test_url"
    httpx -silent -status-code -o "$OUTPUT_DIR/error_${host}_${code}.txt" -u "$test_url"
  done

  # 3. SSL/TLS scan (testssl.sh doit être installé et dans le PATH)
  echo "[*] Lancement testssl.sh pour $host"
  /home/victor/testssl.sh/testssl.sh --quiet --jsonfile "$OUTPUT_DIR/testssl_${host}.json" "$host" > /dev/null 2>&1

done < "$INPUT"

echo "[✔] Analyse terminée. Résultats dans $OUTPUT_DIR/"
