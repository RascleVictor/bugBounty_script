#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 dossier_php_or_endpoints.txt"
  exit 1
fi

INPUT="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="php_analysis_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] Analyse PHP - Résultats dans $OUTPUT_DIR"

while read -r target; do
    if [[ -z "$target" ]]; then
        continue
    fi

    FILENAME=$(echo "$target" | sed 's/[^a-zA-Z0-9]/_/g')
    echo "[SCAN] $target"

    # 1️⃣ Vérification HTTP / headers
    httpx -u "$target" -silent -status-code -title -tech-detect -location -fr -json \
        > "$OUTPUT_DIR/${FILENAME}_httpx.json"

    # 2️⃣ Vérification méthodes HTTP autorisées
    curl -s -o /dev/null -w "Allowed: %{http_code} %{method}\n" -X OPTIONS "$target" \
        > "$OUTPUT_DIR/${FILENAME}_options.txt"

    # 3️⃣ Extraction GET params
    echo "$target" | grep -oP "\?.*" | sed 's/^[?]//' | tr '&' '\n' \
        | cut -d= -f1 | sort -u > "$OUTPUT_DIR/${FILENAME}_params.txt"

    # 4️⃣ Vérification XSS basique (GET)
    for p in $(cat "$OUTPUT_DIR/${FILENAME}_params.txt"); do
        TEST_URL="${target}&${p}=<script>alert(1)</script>"
        RESPONSE=$(curl -s "$TEST_URL")
        if echo "$RESPONSE" | grep -q "<script>alert(1)</script>"; then
            echo "[!] XSS possible sur param : $p" >> "$OUTPUT_DIR/${FILENAME}_vuln.txt"
        fi
    done

    # 5️⃣ Analyse statique fichiers PHP (si dossier local)
    if [[ -f "$target" && "$target" == *.php ]]; then
        # Variables sensibles
        grep -E "\$password|\$pass|\$secret|\$token" "$target" \
            > "$OUTPUT_DIR/${FILENAME}_credentials.txt"
        # Includes / require dynamiques
        grep -E "include|require|include_once|require_once" "$target" \
            > "$OUTPUT_DIR/${FILENAME}_includes.txt"
        # Commentaires / debug
        grep -E "//|/\*|\*/" "$target" > "$OUTPUT_DIR/${FILENAME}_comments.txt"
    fi

done < "$INPUT"

echo "[✓] Analyse PHP terminée. Résultats dans $OUTPUT_DIR"
