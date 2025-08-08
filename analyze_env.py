import requests
import re
import sys

SENSITIVE_KEYS = [
    "API_KEY", "API_SECRET", "SECRET", "TOKEN", "PASSWORD", "PWD", "DB_PASS", "ACCESS_KEY", "SECRET_KEY", "PRIVATE_KEY", "JWT"
]

def analyze_env_content(content):
    found_secrets = []
    lines = content.splitlines()
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '=' in line:
            key, value = line.split('=', 1)
            key = key.strip().upper()
            value = value.strip()
            for sensitive_key in SENSITIVE_KEYS:
                if sensitive_key in key:
                    found_secrets.append((key, value))
                    break
    return found_secrets

def main(file_with_urls):
    with open(file_with_urls, 'r') as f:
        urls = [line.strip() for line in f if line.strip()]

    for url in urls:
        print(f"\n[+] Checking URL: {url}")
        try:
            resp = requests.get(url, timeout=10)
            if resp.status_code == 200:
                print("[+] .env content found, analyzing...")
                secrets = analyze_env_content(resp.text)
                if secrets:
                    print(f"    Sensitive keys found in {url}:")
                    for key, value in secrets:
                        print(f"      {key} = {value}")
                else:
                    print("    No sensitive keys found.")
            else:
                print(f"    HTTP status code: {resp.status_code} (no content or not accessible)")
        except requests.RequestException as e:
            print(f"    Request failed: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <file_with_urls.txt>")
        sys.exit(1)
    main(sys.argv[1])
