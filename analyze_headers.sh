#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <fichier_input.txt>"
    exit 1
fi

INPUT="$1"
OUTPUT="headers_findings.txt"

> "$OUTPUT"

while read -r url; do
    if [[ -z "$url" ]]; then
        continue
    fi

    echo "[SCAN] $url"

    # Récupération des headers avec httpx
    HEADERS=$(echo "$url" | httpx -silent -path / -status-code -server -tls-probe -csp-probe -fr -hdrs)

    # Vérif CORS permissif
    if echo "$HEADERS" | grep -qi "access-control-allow-origin: \*"; then
        echo "[URL] $url" >> "$OUTPUT"
        echo "- CORS permissif (*)" >> "$OUTPUT"
    fi

    # Vérif CSP absent ou faible
    if ! echo "$HEADERS" | grep -qi "content-security-policy:"; then
        echo "[URL] $url" >> "$OUTPUT"
        echo "- Aucun CSP" >> "$OUTPUT"
    elif echo "$HEADERS" | grep -qi "unsafe-inline"; then
        echo "[URL] $url" >> "$OUTPUT"
        echo "- CSP faible (unsafe-inline)" >> "$OUTPUT"
    fi

    # Vérif headers manquants
    for h in "x-frame-options" "x-content-type-options" "strict-transport-security"; do
        if ! echo "$HEADERS" | grep -qi "$h:"; then
            echo "[URL] $url" >> "$OUTPUT"
            echo "- Header manquant : $h" >> "$OUTPUT"
        fi
    done

    echo "" >> "$OUTPUT"
done < "$INPUT"

echo "[DONE] Résultats dans $OUTPUT"
