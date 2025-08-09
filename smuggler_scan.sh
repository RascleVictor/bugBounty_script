#!/bin/bash

INPUT=$1
OUTPUT="vuln_smuggler.txt"

if [ -z "$INPUT" ]; then
  echo "Usage: $0 urls.txt"
  exit 1
fi

> "$OUTPUT"  # vide le fichier résultat au début

while read -r url; do
  echo "[*] Test de $url avec Smuggler..."

  # Lance smugller sur l'url et récupère la sortie
  output=$(python3 /home/victor/smuggler/smuggler.py -u "$url" 2>&1)

  # Exemple : on cherche une phrase clé qui indique vuln (à adapter selon la sortie de smugller)
  # Ici on suppose que "Vulnerable" ou "Success" dans la sortie indique vuln
  if echo "$output" | grep -iqE "vulnerable|success"; then
    echo "[!] Vuln détectée sur $url"
    echo "URL: $url" >> "$OUTPUT"
    echo "Détails:" >> "$OUTPUT"
    echo "$output" >> "$OUTPUT"
    echo "---------------------------------" >> "$OUTPUT"
  else
    echo "[-] Pas de vuln sur $url"
  fi
done < "$INPUT"

echo "Scan terminé, résultats dans $OUTPUT"
