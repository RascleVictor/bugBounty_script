import json
import os
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

def analyze_json_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        secrets = find_sensitive_data(data)
        return secrets
    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
        return []

def find_json_files_and_analyze(directory, output_file):
    with open(output_file, 'w', encoding='utf-8') as out_f:
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith('.json'):
                    path = os.path.join(root, file)
                    secrets = analyze_json_file(path)
                    if secrets:
                        out_f.write(f"=== Sensitive data found in {path} ===\n")
                        for secret_path, value in secrets:
                            out_f.write(f"{secret_path} : {value}\n")
                        out_f.write("\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <directory_to_scan> <output_file.txt>")
        sys.exit(1)

    directory = sys.argv[1]
    output_file = sys.argv[2]

    find_json_files_and_analyze(directory, output_file)
    print(f"Analysis done. Results saved in {output_file}")
