#!/bin/bash

# Vérification de l'argument
if [ -z "$1" ]; then
    echo "Usage: $0 domaine.com"
    exit 1
fi

DOMAIN=$1
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="recon_$DOMAIN_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] 1/ Recherche de sous-domaines avec subfinder..."
subfinder -d "$DOMAIN" -silent > "$OUTPUT_DIR/raw_subdomains.txt"
echo "[+] Sous-domaines trouvés : $(wc -l < "$OUTPUT_DIR/raw_subdomains.txt")"

echo "[+] 2/ Résolution DNS avec dnsx..."
dnsx -l "$OUTPUT_DIR/raw_subdomains.txt" -silent -a -resp > "$OUTPUT_DIR/dnsx_a.txt" || true
awk '{print $1}' "$OUTPUT_DIR/dnsx_a.txt" 2>/dev/null | sort -u > "$OUTPUT_DIR/subdomains.txt" || true
echo "[+] Sous-domaines résolus : $(wc -l < "$OUTPUT_DIR/subdomains.txt" 2>/dev/null || echo 0)"

echo "[+] 3/ Vérification des sous-domaines vivants avec httpx..."
httpx -l "$OUTPUT_DIR/subdomains.txt" -silent -status-code -title -content-length > "$OUTPUT_DIR/alive.txt"
cut -d ' ' -f1 "$OUTPUT_DIR/alive.txt" > "$OUTPUT_DIR/alive_domains.txt"
echo "[+] Sous-domaines vivants : $(wc -l < "$OUTPUT_DIR/alive_domains.txt")"

echo "[+] 4/ Récupération des informations ASN avec asnmap..."
mkdir -p "$OUTPUT_DIR/asnmap"
if [ -s "$OUTPUT_DIR/subdomains.txt" ]; then
  while read -r sub; do
    echo "    [-] ASN pour $sub"
    asnmap -d "$sub" >> "$OUTPUT_DIR/asnmap/asnmap_raw.txt" || true
  done < "$OUTPUT_DIR/subdomains.txt"

  sort -u "$OUTPUT_DIR/asnmap/asnmap_raw.txt" > "$OUTPUT_DIR/asnmap/asnmap.txt"
  echo "[+] ASNs trouvés : $(wc -l < "$OUTPUT_DIR/asnmap/asnmap.txt" 2>/dev/null || echo 0)"
else
  echo "[-] Aucun sous-domaine résolu, asnmap ignoré."
fi

echo "[+] 5/ Extraction d'URLs avec gau..."
cat "$OUTPUT_DIR/alive_domains.txt" | gau --threads 5 --subs --blacklist png,jpg,jpeg,gif,svg,woff,css > "$OUTPUT_DIR/gau_urls.txt"

echo "[+] 6/ Extraction d'URLs avec waybackurls..."
cat "$OUTPUT_DIR/alive_domains.txt" | waybackurls > "$OUTPUT_DIR/waybackurls.txt"

echo "[+] 7/ Fusion et nettoyage des URLs..."
cat "$OUTPUT_DIR/gau_urls.txt" "$OUTPUT_DIR/waybackurls.txt" | sort -u > "$OUTPUT_DIR/all_urls.txt"
echo "[+] Total d'URLs uniques : $(wc -l < "$OUTPUT_DIR/all_urls.txt")"

echo "[+] 8/ Extraction des URLs avec paramètres via ParamSpider..."
mkdir -p "$OUTPUT_DIR/paramspider"
while read -r sub; do
    echo "    [-] ParamSpider sur $sub"
    paramspider -d "$sub" --output "$OUTPUT_DIR/paramspider/$sub.txt"
done < "$OUTPUT_DIR/alive_domains.txt"

echo "[+] Fusion des résultats ParamSpider..."
cat "$OUTPUT_DIR/paramspider/"*.txt 2>/dev/null | grep "=" | sort -u > "$OUTPUT_DIR/urls_with_params.txt"
echo "[+] Total d'URLs avec paramètres : $(wc -l < "$OUTPUT_DIR/urls_with_params.txt" 2>/dev/null || echo 0)"

echo "[✓] Fichiers finaux générés dans : $OUTPUT_DIR"
