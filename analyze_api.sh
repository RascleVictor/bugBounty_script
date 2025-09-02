#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <api_endpoints.txt>"
    exit 1
fi

INPUT="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="api_analysis_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] Analyse API - Résultats dans $OUTPUT_DIR"

# Boucle sur chaque endpoint API
while read -r url; do
    if [[ -z "$url" ]]; then
        continue
    fi

    echo "[SCAN] $url"
    FILENAME=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g')

    # 1️⃣ Vérification HTTP
    echo "    [-] Vérification HTTP avec httpx"
    httpx -u "$url" -silent -status-code -title -tech-detect -location -fr -json > "$OUTPUT_DIR/${FILENAME}_httpx.json"

    # 2️⃣ Vérification méthodes HTTP autorisées
    echo "    [-] Méthodes HTTP autorisées"
    curl -s -o /dev/null -w "Allowed: %{http_code} %{method}\n" -X OPTIONS "$url" > "$OUTPUT_DIR/${FILENAME}_options.txt"

    # 3️⃣ Recherche Swagger / OpenAPI
    echo "    [-] Test Swagger/OpenAPI"
    for endpoint in "/swagger.json" "/swagger/v1/swagger.json" "/openapi.json" "/v2/api-docs"; do
        test_url="${url%/}$endpoint"
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$test_url")
        if [[ "$STATUS" == "200" ]]; then
            echo "[+] Trouvé : $test_url" | tee -a "$OUTPUT_DIR/swagger_openapi.txt"
            curl -s "$test_url" -o "$OUTPUT_DIR/${FILENAME}_swagger.json"

            # Analyse rapide du swagger.json
            jq '.info' "$OUTPUT_DIR/${FILENAME}_swagger.json" > "$OUTPUT_DIR/${FILENAME}_swagger_info.txt"
            jq '.paths' "$OUTPUT_DIR/${FILENAME}_swagger.json" > "$OUTPUT_DIR/${FILENAME}_endpoints.txt"
            jq '.components.securitySchemes' "$OUTPUT_DIR/${FILENAME}_swagger.json" > "$OUTPUT_DIR/${FILENAME}_auth.txt"
        fi
    done

    # 4️⃣ Détection GraphQL
    echo "    [-] Test GraphQL"
    GRAPHQL=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"query":"{__schema{types{name}}}"}' "$url" | grep -i "data")
    if [[ ! -z "$GRAPHQL" ]]; then
        echo "[+] GraphQL introspection ouverte : $url" | tee -a "$OUTPUT_DIR/graphql.txt"
    fi

    # 5️⃣ Vérification CORS
    echo "    [-] Vérification CORS"
    curl -s -I -H "Origin: https://evil.com" "$url" | grep -i "access-control-allow-origin" > "$OUTPUT_DIR/${FILENAME}_cors.txt"

    # 6️⃣ Analyse JSON générique (si la réponse est JSON)
    echo "    [-] Analyse JSON générique"
    RESPONSE=$(curl -s "$url")
    if echo "$RESPONSE" | jq empty >/dev/null 2>&1; then
        echo "$RESPONSE" > "$OUTPUT_DIR/${FILENAME}_response.json"

        # Extraire toutes les clés
        jq 'path(..)|[.[]|tostring]|join(".")' "$OUTPUT_DIR/${FILENAME}_response.json" | sort -u > "$OUTPUT_DIR/${FILENAME}_keys.txt"

        # Rechercher des données sensibles
        jq -r '..|objects|keys[]?' "$OUTPUT_DIR/${FILENAME}_response.json" | \
        grep -Ei "token|apikey|secret|password|session|auth|key|bearer|client_id|client_secret|auth|passwd|pwd"\
        > "$OUTPUT_DIR/${FILENAME}_sensitive.txt"
    fi

done < "$INPUT"

echo "[✓] Analyse API terminée. Résultats dans : $OUTPUT_DIR"
