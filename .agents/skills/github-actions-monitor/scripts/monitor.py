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

def get_latest_run(repo="georgeteste4/LEILAO_WEB_APP"):
    token = get_token()
    if not token:
        print("Erro: Não foi possível obter token do Git.")
        return None

    url = f"https://api.github.com/repos/{repo}/actions/runs"
    req = urllib.request.Request(url, headers={
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'GitHub-Actions-Monitor-Skill'
    })

    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        runs = data.get('workflow_runs', [])
        return runs[0] if runs else None

def get_job_steps(job_url, token):
    req = urllib.request.Request(job_url, headers={
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'GitHub-Actions-Monitor-Skill'
    })
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode('utf-8'))

if __name__ == '__main__':
    run = get_latest_run()
    if not run:
        print("Nenhuma run encontrada.")
        sys.exit(1)

    print(f"Run ID: {run['id']} | Status: {run['status']} | Conclusion: {run['conclusion']}")
    print(f"Commit: {run['head_commit']['id'][:7]} - {run['head_commit']['message']}")
    print(f"URL: {run['html_url']}")
