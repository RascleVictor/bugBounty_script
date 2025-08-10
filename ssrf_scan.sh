#!/bin/bash

# Vérification arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 fichier_urls_ssrf.txt"
    exit 1
fi

INPUT=$1
OUTPUT_DIR="scan_ssrf_results"
mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/ssrf_vulnerable.txt"

echo "[*] Lancement du scan SSRF sur $INPUT"
> "$OUTPUT_FILE"  # vide le fichier de sortie

while read -r url; do
    echo "[+] Test de $url"

    # Test SSRF avec ssrfmap
    python3 /home/victor/SSRFmap/ssrfmap.py -r "$url" -p url --level 3 2>&1 | tee "$OUTPUT_DIR/tmp.txt" > /dev/null

    # Si "Vulnerable" trouvé dans la sortie
    if grep -qi "Vulnerable" "$OUTPUT_DIR/tmp.txt"; then
        echo "[VULN] $url"
        echo "$url" >> "$OUTPUT_FILE"
    fi

    rm -f "$OUTPUT_DIR/tmp.txt"
done < "$INPUT"

echo "[✔] Scan SSRF terminé."
echo "Résultats : $OUTPUT_FILE"
