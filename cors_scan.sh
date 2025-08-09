#!/bin/bash

# Usage: ./corsy_safe.sh urls.txt
URLS_FILE="$1"
OUTPUT_FILE="cors_vuln.txt"
CORSY_PATH=/home/victor/Corsy/corsy.py # Chemin vers corsy.py

if [[ -z "$URLS_FILE" ]]; then
    echo "Usage: $0 <urls_file>"
    exit 1
fi

echo "[+] Scan CORS sur les URLs de $URLS_FILE"
echo "" > "$OUTPUT_FILE"

while read -r url; do
    [[ -z "$url" ]] && continue  # Skip lignes vides
    echo "[*] Test CORS sur $url"

    # Scan une seule URL
    python3 "$CORSY_PATH" -u "$url" > temp_cors.txt 2>/dev/null

    # Vérifie si vulnérable
    if grep -qi "VULNERABLE" temp_cors.txt; then
        echo "[!] Vulnérable trouvé sur $url"
        {
            echo "URL: $url"
            cat temp_cors.txt
            echo "----------------------------------"
        } >> "$OUTPUT_FILE"
    fi

    # On supprime la sortie temporaire pour éviter d'encombrer la RAM
    rm -f temp_cors.txt

done < "$URLS_FILE"

echo "[+] Scan terminé. Résultats dans $OUTPUT_FILE"
