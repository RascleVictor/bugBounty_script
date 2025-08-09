import requests
import json
import sys

SENSITIVE_KEYS = [
    "apikey", "api_key", "token", "secret", "password", "access_token",
    "client_id", "client_secret", "auth", "passwd", "pwd"
]

def find_sensitive_data(obj, path=""):
    found = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            key_lower = k.lower()
            new_path = f"{path}.{k}" if path else k
            if any(skey in key_lower for skey in SENSITIVE_KEYS):
                found.append((new_path, v))
            found.extend(find_sensitive_data(v, new_path))
    elif isinstance(obj, list):
        for idx, item in enumerate(obj):
            new_path = f"{path}[{idx}]"
            found.extend(find_sensitive_data(item, new_path))
    return found

def analyze_url(url):
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        return find_sensitive_data(data)
    except Exception as e:
        print(f"Erreur avec l'URL {url} : {e}")
        return []

def analyze_urls_from_file(input_file, output_file):
    with open(input_file, 'r') as f_in, open(output_file, 'w', encoding='utf-8') as f_out:
        urls = [line.strip() for line in f_in if line.strip()]
        for url in urls:
            print(f"Analyse de {url} ...")
            secrets = analyze_url(url)
            if secrets:
                f_out.write(f"=== Sensitive data found at {url} ===\n")
                for path, value in secrets:
                    f_out.write(f"{path} : {value}\n")
                f_out.write("\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} urls.txt output_results.txt")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    analyze_urls_from_file(input_file, output_file)
    print(f"Analyse terminée, résultats dans {output_file}")
