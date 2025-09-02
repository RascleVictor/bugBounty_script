#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 fichier_targets.txt"
    exit 1
fi

TARGETS="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="nuclei_scan_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] Lancement du scan Nuclei sur $TARGETS"
echo "[+] Résultats dans $OUTPUT_DIR"

# Dossier pour chaque type de tag
TAGS=("cve" "exposures" "misconfiguration" "tokens" "xss" "lfi" "sqli")
for tag in "${TAGS[@]}"; do
    mkdir -p "$OUTPUT_DIR/$tag"
done

# Boucle sur chaque target
while read -r target; do
    if [[ -z "$target" ]]; then
        continue
    fi

    echo "[SCAN] $target"

    # Lancer nuclei sur la target et récupérer les résultats JSON
    nuclei -u "$target" -json -t ~/nuclei-templates/ -silent > "$OUTPUT_DIR/${target//[^a-zA-Z0-9]/_}_raw.json"

    # Séparer les résultats par tag
    for tag in "${TAGS[@]}"; do
        jq --arg TAG "$tag" 'select(.info.tags[]? | contains($TAG))' \
            "$OUTPUT_DIR/${target//[^a-zA-Z0-9]/_}_raw.json" \
            > "$OUTPUT_DIR/$tag/${target//[^a-zA-Z0-9]/_}_$tag.json"
    done

done < "$TARGETS"

echo "[✓] Scan Nuclei terminé. Résultats triés par tag dans $OUTPUT_DIR"
