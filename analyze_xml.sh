#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 dossier_xml"
  exit 1
fi

XML_DIR="$1"
OUTPUT="extracted_urls_from_xml.txt"
> "$OUTPUT"

echo "[+] Extraction URLs dans $XML_DIR"

find "$XML_DIR" -type f -name "*.xml" | while read -r xml_file; do
  echo "  [-] Analyse $xml_file"
  grep -Eo "(http|https)://[^ \"<> ]+" "$xml_file" >> "$OUTPUT"
done

echo "[✓] Extraction terminée, résultats dans $OUTPUT"
