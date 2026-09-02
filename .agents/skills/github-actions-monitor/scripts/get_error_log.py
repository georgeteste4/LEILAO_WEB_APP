import subprocess
import json
import urllib.request
import sys

def get_token():
    p = subprocess.Popen(['git', 'credential', 'fill'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    out, _ = p.communicate(input='protocol=https\nhost=github.com\n')
    for line in out.splitlines():
        if line.startswith('password='):
            return line.split('=', 1)[1].strip()
    return None

def fetch_logs(run_id, repo="georgeteste4/LEILAO_WEB_APP"):
    token = get_token()
    url = f"https://api.github.com/repos/{repo}/actions/runs/{run_id}/jobs"
    req = urllib.request.Request(url, headers={
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'GitHub-Actions-Monitor-Skill'
    })

    with urllib.request.urlopen(req) as resp:
        jobs = json.loads(resp.read().decode('utf-8')).get('jobs', [])

    if not jobs:
        print("Nenhum job encontrado.")
        return

    job = jobs[0]
    log_url = job['url'] + '/logs'
    req_log = urllib.request.Request(log_url, headers={
        'Authorization': f'token {token}',
        'User-Agent': 'GitHub-Actions-Monitor-Skill'
    })

    try:
        with urllib.request.urlopen(req_log) as resp:
            text = resp.read().decode('utf-8', errors='replace')
            lines = text.splitlines()
            print(f"--- ERROS DETECTADOS ({len(lines)} linhas totais) ---")
            for l in lines:
                if any(k in l for k in ['FAILURE:', 'Execution failed', 'AAPT:', 'Error:', 'Redeclaration:']):
                    print(l)
    except Exception as e:
        print(f"Erro ao baixar log: {e}")

if __name__ == '__main__':
    run_id = sys.argv[1] if len(sys.argv) > 1 else None
    if not run_id:
        print("Uso: python get_error_log.py <RUN_ID>")
        sys.exit(1)
    fetch_logs(run_id)
