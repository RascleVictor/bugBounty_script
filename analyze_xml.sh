#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 dossier_xml"
  exit 1
fi

XML_DIR="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="xml_analysis_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] Analyse XML dans $XML_DIR - Résultats dans $OUTPUT_DIR"

find "$XML_DIR" -type f -name "*.xml" | while read -r xml_file; do
  echo "  [-] Analyse $xml_file"

  filename=$(basename "$xml_file" .xml)

  # 1️⃣ Extraction des URLs
  grep -Eo "(http|https)://[^ \"<>]+" "$xml_file" \
    > "$OUTPUT_DIR/${filename}_urls.txt"

  # 2️⃣ Emails
  grep -Eoi "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$xml_file" \
    > "$OUTPUT_DIR/${filename}_emails.txt"

  # 3️⃣ API Keys & Tokens
  grep -Eoi "AIza[0-9A-Za-z\-_]{35}" "$xml_file" >> "$OUTPUT_DIR/${filename}_apikeys.txt"
  grep -Eoi "AKIA[0-9A-Z]{16}" "$xml_file" >> "$OUTPUT_DIR/${filename}_apikeys.txt"
  grep -Eoi "ya29\.[0-9A-Za-z\-_]+" "$xml_file" >> "$OUTPUT_DIR/${filename}_tokens.txt"
  grep -Eoi "eyJ[A-Za-z0-9._-]{20,}\.[A-Za-z0-9._-]{20,}\.[A-Za-z0-9._-]{10,}" "$xml_file" >> "$OUTPUT_DIR/${filename}_jwts.txt"

  # 4️⃣ Credentials
  grep -Eoi "<(password|passwd|secret|key|token)>([^<]+)</\1>" "$xml_file" \
    > "$OUTPUT_DIR/${filename}_credentials.txt"

  # 5️⃣ IP internes
  grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" "$xml_file" \
    | grep -vE "127\.0\.0\.1|0\.0\.0\.0" \
    > "$OUTPUT_DIR/${filename}_ips.txt"

  # 6️⃣ Commentaires XML
  grep -o "<!--.*-->" "$xml_file" \
    > "$OUTPUT_DIR/${filename}_comments.txt"

  # 7️⃣ Détection XXE
  grep -E "DOCTYPE|ENTITY" "$xml_file" \
    > "$OUTPUT_DIR/${filename}_xxe.txt"

done

echo "[✓] Analyse XML terminée. Résultats dans $OUTPUT_DIR"
