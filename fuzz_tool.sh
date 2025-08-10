#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 input_urls.txt output_urls.txt"
    exit 1
fi

INPUT=$1
OUTPUT=$2
> "$OUTPUT"  # vide le fichier de sortie

while read -r url; do
    # Vérifie qu'on a bien un "?" (paramètres)
    if [[ "$url" == *"?"* ]]; then
        base="${url%%\?*}"   # tout avant le ?
        params="${url#*\?}" # tout après le ?

        IFS='&' read -ra parts <<< "$params"

        # Pour chaque paramètre, remplacer sa valeur par FUZZ
        for i in "${!parts[@]}"; do
            key="${parts[$i]%%=*}"  # nom du paramètre

            # On clone la liste pour modifier un seul param à la fois
            new_parts=("${parts[@]}")
            new_parts[$i]="$key=FUZZ"

            # Recompose l'URL
            fuzzed_url="$base?$(IFS='&'; echo "${new_parts[*]}")"

            echo "$fuzzed_url" >> "$OUTPUT"
        done
    fi
done < "$INPUT"

echo "[✔] Fuzz URLs générées dans $OUTPUT"
