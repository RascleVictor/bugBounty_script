#!/bin/bash

# Vérification des arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 fichier_urls_xss.txt"
    exit 1
fi

INPUT=$1
OUTPUT_DIR="scan_xss_results"
mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/xss_vulnerable.txt"

echo "[*] Lancement du scan XSS sur $INPUT"
> "$OUTPUT_FILE"  # vide le fichier de sortie

while read -r url; do
    echo "[+] Test de $url"

    # Test XSS avec XSStrike
    python3 /home/victor/XSStrike/xsstrike.py -u "$url" --skip-dom 2>&1 | tee "$OUTPUT_DIR/tmp.txt" > /dev/null

    # Recherche si XSStrike indique une vulnérabilité ou possible vulnérabilité
    if grep -Eqi "Vulnerable|Possible|JS file" "$OUTPUT_DIR/tmp.txt"; then
        echo "[VULN/POSSIBLE] $url"
        echo "$url" >> "$OUTPUT_FILE"
    fi

    rm -f "$OUTPUT_DIR/tmp.txt"
done < "$INPUT"

echo "[✔] Scan XSS terminé."
echo "Résultats : $OUTPUT_FILE"
