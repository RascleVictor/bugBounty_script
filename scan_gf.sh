#!/bin/bash

# Vérification arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <fichier_urls>"
    exit 1
fi

URLS_FILE="$1"
OUTPUT_DIR="gf_results"

# Création du dossier de sortie
mkdir -p "$OUTPUT_DIR"

# Liste des patterns gf à utiliser
PATTERNS=(xss sqli lfi ssrf redirect rce idor)

# Boucle sur chaque pattern
for pattern in "${PATTERNS[@]}"; do
    echo "[+] Scan avec gf pattern: $pattern"
    cat "$URLS_FILE" | gf "$pattern" > "$OUTPUT_DIR/$pattern.txt"

    # Si le fichier est vide, on le supprime
    if [ ! -s "$OUTPUT_DIR/$pattern.txt" ]; then
        rm "$OUTPUT_DIR/$pattern.txt"
    else
        echo "    → Résultats enregistrés dans $OUTPUT_DIR/$pattern.txt"
    fi
done

echo "[+] Scan terminé. Résultats dans $OUTPUT_DIR/"
