import os
import re

def extract_from_jsp(file_path):
    urls = set()
    params = set()
    includes = set()
    comments = []
    vuln_patterns = []

    url_pattern = re.compile(r'(?:http|https)://[^\s"\'<>]+')
    param_pattern = re.compile(r'request\.getParameter\("([^"]+)"\)')
    include_pattern = re.compile(r'<jsp:include\s+page="([^"]+)"\s*/?>')
    comment_pattern = re.compile(r'<!--(.*?)-->', re.DOTALL)

    # Patterns vulnérables à détecter
    el_pattern = re.compile(r'\$\{[^}]+\}')  # Expression Language
    eval_pattern = re.compile(r'\beval\s*\(')
    exec_pattern = re.compile(r'(Runtime\.getRuntime\(\)\.exec|ProcessBuilder)')
    sensitive_file_pattern = re.compile(r'(/etc/passwd|/WEB-INF/web\.xml|/WEB-INF/classes|/WEB-INF/lib)', re.IGNORECASE)
    # Exemple simple pour request.getParameter sans validation = recherche usage direct sans filtre
    direct_param_usage_pattern = re.compile(r'request\.getParameter\(\s*".+?"\s*\)')

    with open(file_path, encoding='utf-8', errors='ignore') as f:
        content = f.read()

        urls.update(url_pattern.findall(content))
        params.update(param_pattern.findall(content))
        includes.update(include_pattern.findall(content))
        comments.extend(comment_pattern.findall(content))

        # Recherche vulnérabilités
        if el_pattern.search(content):
            vuln_patterns.append("Possible Expression Language usage (${...})")
        if eval_pattern.search(content):
            vuln_patterns.append("Use of eval() detected")
        if exec_pattern.search(content):
            vuln_patterns.append("Use of Runtime.exec or ProcessBuilder detected")
        if sensitive_file_pattern.search(content):
            vuln_patterns.append("Access to sensitive file paths detected")
        # Simple indication si getParameter est utilisée (à approfondir dans un vrai audit)
        if direct_param_usage_pattern.search(content):
            vuln_patterns.append("request.getParameter usage found - check for input validation")

    return urls, params, includes, comments, vuln_patterns

def analyze_directory(directory):
    all_urls = set()
    all_params = set()
    all_includes = set()
    all_comments = []
    all_vulns = {}

    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.jsp'):
                path = os.path.join(root, file)
                urls, params, includes, comments, vulns = extract_from_jsp(path)
                all_urls.update(urls)
                all_params.update(params)
                all_includes.update(includes)
                all_comments.extend(comments)
                if vulns:
                    all_vulns[path] = vulns

    return all_urls, all_params, all_includes, all_comments, all_vulns

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <directory_with_jsp_files>")
        sys.exit(1)

    directory = sys.argv[1]
    urls, params, includes, comments, vulns = analyze_directory(directory)

    print(f"Found {len(urls)} URLs:")
    for url in urls:
        print(url)
    print(f"\nFound {len(params)} request.getParameter calls:")
    for p in params:
        print(p)
    print(f"\nFound {len(includes)} jsp:include pages:")
    for inc in includes:
        print(inc)
    print(f"\nFound {len(comments)} comments snippets (showing first 5):")
    for c in comments[:5]:
        print(c.strip())

    print(f"\nVulnerable patterns found in {len(vulns)} files:")
    for file_path, issues in vulns.items():
        print(f"\nFile: {file_path}")
        for issue in issues:
            print(f" - {issue}")
