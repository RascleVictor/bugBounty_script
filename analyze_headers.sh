#!/bin/bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <fichier_input.txt>"
    exit 1
fi

INPUT="$1"
OUTPUT="headers_findings.txt"

> "$OUTPUT"

while read -r url; do
    if [[ -z "$url" ]]; then
        continue
    fi

    echo "[SCAN] $url"

    # Récupération des headers avec httpx
    HEADERS=$(echo "$url" | httpx -silent -path / -status-code -server -tls-probe -csp-probe -fr -hdrs)

    echo "[URL] $url" >> "$OUTPUT"

    # ----------------------
    # Vérifications CORS
    # ----------------------
    if echo "$HEADERS" | grep -qi "access-control-allow-origin: \*"; then
        echo "- CORS permissif (*)" >> "$OUTPUT"
    fi
    if echo "$HEADERS" | grep -qi "access-control-allow-credentials: true"; then
        echo "- CORS avec credentials (dangereux si origin trop permissif)" >> "$OUTPUT"
    fi

    # ----------------------
    # Vérifications CSP
    # ----------------------
    if ! echo "$HEADERS" | grep -qi "content-security-policy:"; then
        echo "- Aucun CSP" >> "$OUTPUT"
    elif echo "$HEADERS" | grep -qi "unsafe-inline"; then
        echo "- CSP faible (unsafe-inline)" >> "$OUTPUT"
    fi

    # ----------------------
    # Vérifications de headers de sécurité classiques
    # ----------------------
    for h in "x-frame-options" "x-content-type-options" "strict-transport-security" \
             "referrer-policy" "x-xss-protection" "permissions-policy"; do
        if ! echo "$HEADERS" | grep -qi "$h:"; then
            echo "- Header manquant : $h" >> "$OUTPUT"
        fi
    done

    # ----------------------
    # Vérif SSL/TLS (via httpx -tls-probe)
    # ----------------------
    if echo "$HEADERS" | grep -qi "tls:"; then
        TLS=$(echo "$HEADERS" | grep -i "tls:")
        if echo "$TLS" | grep -q "1.0\|1.1"; then
            echo "- TLS faible (1.0/1.1 encore activé)" >> "$OUTPUT"
        fi
    fi

    # ----------------------
    # Vérif serveur exposé
    # ----------------------
    if echo "$HEADERS" | grep -qi "server:"; then
        SERVER=$(echo "$HEADERS" | grep -i "server:")
        echo "- Header Server exposé : $SERVER" >> "$OUTPUT"
    fi
    if echo "$HEADERS" | grep -qi "x-powered-by:"; then
        XPB=$(echo "$HEADERS" | grep -i "x-powered-by:")
        echo "- Header X-Powered-By exposé : $XPB" >> "$OUTPUT"
    fi

    # ----------------------
    # Vérif cache & cookies
    # ----------------------
    if echo "$HEADERS" | grep -qi "set-cookie:"; then
        if ! echo "$HEADERS" | grep -qi "httponly"; then
            echo "- Cookie sans HttpOnly" >> "$OUTPUT"
        fi
        if ! echo "$HEADERS" | grep -qi "secure"; then
            echo "- Cookie sans Secure" >> "$OUTPUT"
        fi
        if ! echo "$HEADERS" | grep -qi "samesite"; then
            echo "- Cookie sans SameSite" >> "$OUTPUT"
        fi
    fi

    if ! echo "$HEADERS" | grep -qi "cache-control:"; then
        echo "- Aucun cache-control (risque de fuite données sensibles)" >> "$OUTPUT"
    fi

    echo "" >> "$OUTPUT"
done < "$INPUT"

echo "[DONE] Résultats dans $OUTPUT"
