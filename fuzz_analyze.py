import argparse
import subprocess
import json
import re
from pathlib import Path

# Signatures par vulnérabilité
SIGNATURES = {
    "lfi": ["/etc/passwd", "root:x:0:0", "boot.ini", "C:\\Windows\\System32"],
    "rce": ["uid=", "gid=", "whoami", "root"],
    "sqli": ["SQL syntax", "mysql_fetch_", "ORA-", "syntax error", "MySQL"],
    "xss": ["<script>", "alert(1)", "<svg", "onerror="],
    "other": []
}

def run_ffuf(url, wordlist, output_json):
    cmd = [
        "ffuf",
        "-u", url,
        "-w", wordlist,
        "-o", output_json,
        "-of", "json",
        "-mc", "200,302"  # codes à analyser
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def analyze_results(output_json, vuln_type):
    results = []
    if not Path(output_json).exists():
        return results

    with open(output_json, "r", encoding="utf-8") as f:
        data = json.load(f)

    for r in data.get("results", []):
        content = r.get("input", {}).get("FUZZ", "")
        body = r.get("content", "")

        # Recherche signature
        if vuln_type != "other":
            for sig in SIGNATURES[vuln_type]:
                if re.search(sig, body, re.IGNORECASE):
                    results.append(r["url"])
                    break
        else:
            results.append(r["url"])
    return results

def main():
    parser = argparse.ArgumentParser(description="Fuzzing scanner avec détection de vulnérabilités")
    parser.add_argument("--input", required=True, help="Fichier contenant les URLs avec FUZZ")
    parser.add_argument("--wordlist", required=True, help="Chemin de la wordlist")
    parser.add_argument("--type", required=True, choices=SIGNATURES.keys(), help="Type de vuln à rechercher")
    parser.add_argument("--output", required=True, help="Fichier pour stocker les résultats suspects")
    args = parser.parse_args()

    with open(args.input, "r") as f:
        urls = [line.strip() for line in f if line.strip()]

    Path(args.output).write_text("")  # vide fichier sortie

    for url in urls:
        print(f"[*] Fuzzing {url}")
        tmp_json = "tmp_ffuf.json"
        run_ffuf(url, args.wordlist, tmp_json)
        suspicious = analyze_results(tmp_json, args.type)

        if suspicious:
            with open(args.output, "a") as out_f:
                for s in suspicious:
                    out_f.write(s + "\n")
            print(f"[VULN] {len(suspicious)} résultats suspects pour {url}")
        Path(tmp_json).unlink(missing_ok=True)

    print(f"[✔] Scan terminé. Résultats dans {args.output}")

if __name__ == "__main__":
    main()
