#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 fichier_urls_ssti.txt"
    exit 1
fi

INPUT=$1
OUTPUT="ssti_vulnerable_results.txt"

# Vider le fichier output au départ
> "$OUTPUT"

echo "[*] Début des tests SSTI..."

while read -r url; do
    echo "[+] Test de : $url"

    # Lance sstimap, capture la sortie
    result=$(python3 /home/victor/SSTImap/sstimap.py -u "$url" 2>&1)

    # Si la sortie contient un indice de vulnérabilité, on la log
    if echo "$result" | grep -q "sstimap identified the following injection point"; then
        echo "Vulnérable : $url" >> "$OUTPUT"
        echo "$result" >> "$OUTPUT"
        echo "--------------------------------" >> "$OUTPUT"
        echo "[!] Vuln détectée et enregistrée pour $url"
    else
        echo "[*] Pas de vuln détectée pour $url"
    fi
done < "$INPUT"

echo "[✔] Scan SSTI terminé. Résultats dans $OUTPUT"
