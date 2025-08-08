#!/bin/bash

# Vérification de l'argument
if [ -z "$1" ]; then
    echo "Usage: $0 fichier_urls.txt"
    exit 1
fi

INPUT_FILE="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="filtered_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] Filtrage des URLs depuis $INPUT_FILE..."
echo "[+] Résultats dans : $OUTPUT_DIR"

# URLs avec paramètres
grep "?" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/urls_with_params.txt"

# Fichiers JavaScript
grep -Ei "\.js(\?|$)" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/js_files.txt"

# Endpoints API (.json ou /api/)
grep -Ei "\.json(\?|$)" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/api_json.txt"
grep -Ei "/api/" "$INPUT_FILE" | sort -u >> "$OUTPUT_DIR/api_json.txt"
sort -u "$OUTPUT_DIR/api_json.txt" -o "$OUTPUT_DIR/api_json.txt"

# Extensions backend
grep -Ei "\.php(\?|$)" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/php_urls.txt"
grep -Ei "\.asp(\?|$)" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/asp_urls.txt"
grep -Ei "\.jsp(\?|$)" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/jsp_urls.txt"

# Fichiers sensibles
grep -Ei "\.xml(\?|$)" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/xml_files.txt"
grep -Ei "\.config(\?|$)" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/config_files.txt"
grep -Ei "\.env(\?|$)" "$INPUT_FILE" | sort -u > "$OUTPUT_DIR/env_files.txt"

# Résumé
echo "[✓] URLs avec paramètres : $(wc -l < "$OUTPUT_DIR/urls_with_params.txt")"
echo "[✓] Fichiers JS : $(wc -l < "$OUTPUT_DIR/js_files.txt")"
echo "[✓] Endpoints API : $(wc -l < "$OUTPUT_DIR/api_json.txt")"
echo "[✓] PHP : $(wc -l < "$OUTPUT_DIR/php_urls.txt")"
echo "[✓] ASP : $(wc -l < "$OUTPUT_DIR/asp_urls.txt")"
echo "[✓] JSP : $(wc -l < "$OUTPUT_DIR/jsp_urls.txt")"
echo "[✓] XML : $(wc -l < "$OUTPUT_DIR/xml_files.txt")"
echo "[✓] Config : $(wc -l < "$OUTPUT_DIR/config_files.txt")"
echo "[✓] ENV : $(wc -l < "$OUTPUT_DIR/env_files.txt")"

echo "[+] Filtrage terminé."
