#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 dossier_env"
  exit 1
fi

ENV_DIR="$1"
DATE=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="env_analysis_$DATE"
mkdir -p "$OUTPUT_DIR"

echo "[+] Analyse des fichiers .env dans $ENV_DIR - Résultats dans $OUTPUT_DIR"

find "$ENV_DIR" -type f -name ".env*" | while read -r env_file; do
  echo "  [-] Analyse $env_file"

  filename=$(basename "$env_file")

  # 1️⃣ Extraire toutes les lignes non commentées
  grep -vE "^\s*#" "$env_file" > "$OUTPUT_DIR/${filename}_cleaned.txt"

  # 2️⃣ Base de données
  grep -Ei "DB_HOST|DB_USER|DB_PASS|DB_PASSWORD|DATABASE_URL" "$env_file" \
    > "$OUTPUT_DIR/${filename}_database.txt"

  # 3️⃣ AWS Keys
  grep -Eoi "AKIA[0-9A-Z]{16}" "$env_file" > "$OUTPUT_DIR/${filename}_aws_keys.txt"
  grep -Eoi "aws_secret_access_key.+|AWS_SECRET_ACCESS_KEY.+|aws_access_key_id.+" "$env_file" \
    >> "$OUTPUT_DIR/${filename}_aws_keys.txt"

  # 4️⃣ Google / GCP / Firebase
  grep -Eoi "AIza[0-9A-Za-z\-_]{35}" "$env_file" > "$OUTPUT_DIR/${filename}_gcp_keys.txt"

  # 5️⃣ JWT / OAuth / Tokens
  grep -Ei "JWT_SECRET|OAUTH|TOKEN|SECRET_KEY" "$env_file" \
    > "$OUTPUT_DIR/${filename}_secrets.txt"

  # 6️⃣ SMTP
  grep -Ei "MAIL_HOST|MAIL_PORT|MAIL_USER|MAIL_USERNAME|MAIL_PASS|MAIL_PASSWORD" "$env_file" \
    > "$OUTPUT_DIR/${filename}_smtp.txt"

  # 7️⃣ Debug / Environnement
  grep -Ei "APP_ENV|APP_DEBUG" "$env_file" > "$OUTPUT_DIR/${filename}_debug.txt"

  # 8️⃣ URLs / Endpoints
  grep -Eo "(http|https)://[^ \"']+" "$env_file" > "$OUTPUT_DIR/${filename}_urls.txt"

  # 9️⃣ Emails
  grep -Eoi "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$env_file" \
    > "$OUTPUT_DIR/${filename}_emails.txt"

done

echo "[✓] Analyse des .env terminée. Résultats dans $OUTPUT_DIR"
