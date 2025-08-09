#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 fichier_urls_redirect.txt"
    exit 1
fi

INPUT=$1
OUTPUT="openredirex_vulnerable.txt"

> "$OUTPUT"

echo "[*] Début des tests OpenRedirex..."

# Lecture et exécution en direct
cat "$INPUT" | openredirex 2>&1 | grep "\[FOUND\]" >> "$OUTPUT"

echo "[✔] Scan OpenRedirex terminé. Résultats dans $OUTPUT"
