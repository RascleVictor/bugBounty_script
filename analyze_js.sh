#!/bin/bash

# Vérification de l'argument
if [ -z "$1" ]; then
    echo "Usage: $0 js_files.txt"
    exit 1
fi

JS_LIST="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="js_analysis_$DATE"
mkdir -p "$OUTPUT_DIR/js_files" "$OUTPUT_DIR/linkfinder" "$OUTPUT_DIR/regex_hits"

echo "[+] Analyse JS - Résultats dans $OUTPUT_DIR"

# Boucle sur chaque JS
while read -r js_url; do
    if [[ -z "$js_url" ]]; then
        continue
    fi

    filename=$(echo "$js_url" | sed 's/[^a-zA-Z0-9]/_/g')
    js_file="$OUTPUT_DIR/js_files/$filename"

    echo "    [-] Téléchargement : $js_url"
    curl -s "$js_url" -o "$js_file"

    # 1️⃣ LinkFinder - extraction endpoints
    echo "    [-] LinkFinder sur $filename"
    python3 /home/victor/LinkFinder/linkfinder.py -i "$js_file" -o cli > "$OUTPUT_DIR/linkfinder/${filename}_endpoints.txt"

    # 2️⃣ Recherche via regex
    echo "    [-] Regex recherche sur $filename"

    # API keys & Tokens
    grep -Eoi "AIza[0-9A-Za-z\-_]{35}" "$js_file" >> "$OUTPUT_DIR/regex_hits/google_api_keys.txt"
    grep -Eoi "AKIA[0-9A-Z]{16}" "$js_file" >> "$OUTPUT_DIR/regex_hits/aws_access_keys.txt"
    grep -Eoi "ya29\.[0-9A-Za-z\-_]+" "$js_file" >> "$OUTPUT_DIR/regex_hits/google_oauth_tokens.txt"
    grep -Eoi "eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9._-]{20,}\.[A-Za-z0-9._-]{10,}" "$js_file" >> "$OUTPUT_DIR/regex_hits/jwt_tokens.txt"

    # Secrets courants
    grep -Eoi "secret[_-]?key[\"'=:\s]{0,5}[A-Za-z0-9\-_]{10,}" "$js_file" >> "$OUTPUT_DIR/regex_hits/secrets.txt"
    grep -Eoi "password[\"'=:\s]{0,5}[A-Za-z0-9\-_!@#\$%^&*]{5,}" "$js_file" >> "$OUTPUT_DIR/regex_hits/passwords.txt"

    # IPs internes
    grep -Eoi "([0-9]{1,3}\.){3}[0-9]{1,3}" "$js_file" | grep -vE "127\.0\.0\.1|0\.0\.0\.0" >> "$OUTPUT_DIR/regex_hits/ips.txt"

done < "$JS_LIST"

echo "[✓] Analyse terminée. Résultats dans : $OUTPUT_DIR"
