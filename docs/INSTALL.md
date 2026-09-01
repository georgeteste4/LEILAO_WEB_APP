# 📦 Instalação da Skill "universal-frontend-design-system"

A skill `universal-frontend-design-system` é agnóstica de nicho e pode ser instalada globalmente em qualquer ambiente de AI Agents (Antigravity, Gemini CLI, Claude Code).

---

## 🛠️ Instalação Global Automática

Copie a pasta `docs/` para o diretório de skills globais do seu ambiente:

### No Windows (PowerShell):
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.gemini\config\skills\universal-frontend-design-system"
Copy-Item -Path "c:\Users\Geo\Documents\IDEIAIS E COISAS\LEILAO\docs\*" -Destination "$env:USERPROFILE\.gemini\config\skills\universal-frontend-design-system" -Recurse -Force
```

### No Linux / macOS (Bash):
```bash
mkdir -p ~/.gemini/config/skills/universal-frontend-design-system
cp -r ./docs/* ~/.gemini/config/skills/universal-frontend-design-system/
```

---

## 📋 Conteúdo da Skill

| Arquivo | Descrição |
| :--- | :--- |
| [`SKILL.md`](file:///c:/Users/Geo/Documents/IDEIAIS%20E%20COISAS/LEILAO/docs/SKILL.md) | Especificação normativa e instrução completa da skill universal com YAML frontmatter. |
| [`components-guide.md`](file:///c:/Users/Geo/Documents/IDEIAIS%20E%20COISAS/LEILAO/docs/components-guide.md) | Snippets HTML e classes Tailwind CSS genéricos para qualquer aplicação. |
| [`tokens.json`](file:///c:/Users/Geo/Documents/IDEIAIS%20E%20COISAS/LEILAO/docs/tokens.json) | Design tokens semânticos em formato JSON para importação. |
| [`INSTALL.md`](file:///c:/Users/Geo/Documents/IDEIAIS%20E%20COISAS/LEILAO/docs/INSTALL.md) | Guia de instalação e ativação da skill. |
