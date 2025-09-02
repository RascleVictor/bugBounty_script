#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 fichier_urls.txt"
    exit 1
fi

URLS="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="gf_scan_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] Lancement du scan GF sur $URLS"
echo "[+] Résultats dans $OUTPUT_DIR"

# Liste des patterns GF à utiliser
PATTERNS=("xss" "sqli" "lfi" "rce" "redirect" "ssrf" "idor" "ssti" "open_redirect")

# Créer les dossiers pour chaque pattern
for pattern in "${PATTERNS[@]}"; do
    mkdir -p "$OUTPUT_DIR/$pattern"
done

# Boucle sur chaque URL
while read -r url; do
    if [[ -z "$url" ]]; then
        continue
    fi

    FILENAME=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')
    echo "[SCAN] $url"

    for pattern in "${PATTERNS[@]}"; do
        gf "$pattern" <<< "$url" > "$OUTPUT_DIR/$pattern/${FILENAME}_$pattern.txt"
    done

done < "$URLS"

echo "[✓] Scan GF terminé. Résultats organisés par pattern dans $OUTPUT_DIR"
