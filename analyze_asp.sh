#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 dossier_asp"
  exit 1
fi

ASP_DIR="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="asp_analysis_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] Analyse ASP dans $ASP_DIR - Résultats dans $OUTPUT_DIR"

find "$ASP_DIR" -type f \( -name "*.asp" -o -name "*.aspx" -o -name "*.config" -o -name "*.cs" \) | while read -r asp_file; do
  echo "  [-] Analyse $asp_file"

  filename=$(basename "$asp_file")

  # 1️⃣ Extraction des URLs
  grep -Eo "(http|https)://[^ \"'>]+" "$asp_file" \
    > "$OUTPUT_DIR/${filename}_urls.txt"

  # 2️⃣ Emails
  grep -Eoi "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$asp_file" \
    > "$OUTPUT_DIR/${filename}_emails.txt"

  # 3️⃣ ConnectionStrings
  grep -i "<connectionStrings>" -A 5 "$asp_file" \
    > "$OUTPUT_DIR/${filename}_connectionStrings.txt"

  # 4️⃣ Credentials
  grep -Eoi "(user(id)?|username|password|pwd|secret)[\"'> ]*[:=][\"'> ]*[^ \"'>]+" "$asp_file" \
    > "$OUTPUT_DIR/${filename}_credentials.txt"

  # 5️⃣ API Keys & Tokens
  grep -Eoi "eyJ[A-Za-z0-9._-]{20,}" "$asp_file" > "$OUTPUT_DIR/${filename}_jwts.txt"
  grep -Eoi "AIza[0-9A-Za-z\-_]{35}" "$asp_file" > "$OUTPUT_DIR/${filename}_apikeys.txt"
  grep -Eoi "AKIA[0-9A-Z]{16}" "$asp_file" >> "$OUTPUT_DIR/${filename}_apikeys.txt"

  # 6️⃣ IP internes
  grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" "$asp_file" \
    | grep -vE "127\.0\.0\.1|0\.0\.0\.0" \
    > "$OUTPUT_DIR/${filename}_ips.txt"

  # 7️⃣ Chemins internes Windows
  grep -Eoi "[A-Z]:\\\\[A-Za-z0-9_\\\\.-]+" "$asp_file" \
    > "$OUTPUT_DIR/${filename}_paths.txt"

  # 8️⃣ Debug activé
  grep -Ei "debug=\"true\"|customErrors\s*=\s*\"off\"" "$asp_file" \
    > "$OUTPUT_DIR/${filename}_debug.txt"

  # 9️⃣ Commentaires HTML/ASP
  grep -o "<!--.*-->" "$asp_file" > "$OUTPUT_DIR/${filename}_comments.txt"
  grep -o "<%--.*--%>" "$asp_file" >> "$OUTPUT_DIR/${filename}_comments.txt"

done

echo "[✓] Analyse ASP terminée. Résultats dans $OUTPUT_DIR"
