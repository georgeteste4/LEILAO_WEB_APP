# 🏛️ Leilão de Imóveis — Extrator Inteligente & Painel Administrativo

Sistema profissional e completo para extração, monitoramento e persistência de leilões de imóveis do portal [leilaoimovel.com.br](https://www.leilaoimovel.com.br/leilao-de-imoveis/ma), com suporte a banco de dados **MySQL (`leilao_app`)**, **Modo Offline & Online**, **Painel Administrativo**, **Links de Tarefa em Cron**, **Scrape.do**, **Firecrawl** com pool de tokens e failover automático.

---

## ⚡ Novas Funcionalidades Implementadas

### 1. 🗄️ Banco de Dados MySQL (`leilao_app`) & Schema Completo
- **Tabela `filtros_salvos`**: Armazena as configurações de filtros customizados criados no painel admin, tokens de cron e métricas de execução.
- **Tabela `imoveis`**: Armazena os dados estruturados de cada imóvel (título, tipo, endereço, cidade, UF, valor de avaliação, valor de leilão, desconto %, modalidade, encerramento, data de inclusão, edital, link da matrícula em PDF, número de matrícula, leiloeiro oficial, imagem e JSON completo).
- **Tabela `logs_cron`**: Histórico detalhado de execuções com páginas processadas, imóveis novos, atualizados e tempo de execução.

---

### 2. ⚙️ Página Administrativa (`public/admin.html`)
- **Painel de Métricas em Tempo Real**: Total de imóveis no banco, filtros ativos, total de execuções e data da última sincronização.
- **Configurador de Filtros**: Permite criar filtros por Estado (UF), Município, Tipo de Imóvel, Data Final de Leilão e Palavra-chave.
- **Gerador de Links para Cron**:
  - Cada filtro gera uma **URL única de Cron** autenticada por token (ex: `http://localhost:8000/api/cron.php?filter_id=1&token=TOKEN`).
  - **Comando Crontab pronto para copiar** com 1 clique (ex: `0 */6 * * * curl -s "http://localhost:8000/api/cron.php?filter_id=1&token=..." > /dev/null`).
  - Botão **"⚡ Baixar Tudo"**: Dispara o download de todas as páginas do filtro imediatamente com barra de progresso.
- **Tabela de Histórico de Logs**: Exibe todas as execuções do Cron, quantidade de imóveis novos inseridos, atualizados e duração.

---

### 3. 🔄 Modo Offline vs Modo Online na Home (`public/index.html`)
- **Modo Offline (Padrão)**: Busca instantânea diretamente na base local `leilao_app.imoveis` com ordenação por maior desconto, filtros por cidade, tipo e paginação com tempo de resposta em milissegundos sem gastar créditos de scraping.
- **Modo Online (Toggle no topo)**: Faz a consulta em tempo real no portal alvo e **automaticamente insere ou atualiza os imóveis na base MySQL `leilao_app` em background**!

---

### 4. ⏱️ Execução de Tarefas em Cron (`api/cron.php`)

#### Via Linha de Comando (CLI / Agendador de Tarefas do Windows):
```bash
# Executar um filtro específico:
php api/cron.php --filter_id=1

# Executar todos os filtros ativos:
php api/cron.php --all
```

#### Via Chamada Web / Crontab Linux:
```bash
# Executar filtro específico a cada 6 horas:
0 */6 * * * curl -s "http://localhost:8000/api/cron.php?filter_id=1&token=TOKEN_DO_FILTRO" > /dev/null

# Executar todos os filtros diariamente às 03:00:
0 3 * * * curl -s "http://localhost:8000/api/cron.php?all=1&token=leilao_cron_sec_a23b8b96e2ebd12b340e2e2a01581c5e" > /dev/null
```

---

## 📡 Endpoints da API

| Endpoint | Método | Descrição |
|---|---|---|
| `?action=imoveis&uf=MA&origem=offline` | GET | Lista imóveis salvos no banco local `leilao_app` |
| `?action=imoveis&uf=MA&origem=online` | GET | Busca ao vivo no site e salva no banco `leilao_app` |
| `?action=detalhes&url=URL` | GET | Extrai edital, certidão de matrícula, inclusão e leiloeiro |
| `?action=filtros_listar` | GET | Lista todos os filtros salvos com seus links de Cron |
| `?action=filtro_salvar` | POST | Cria/atualiza um filtro e gera token de Cron |
| `?action=filtro_excluir` | POST | Remove um filtro salvo |
| `?action=filtro_executar&filter_id=X` | GET | Executa download de todas as páginas do filtro |
| `?action=dashboard_stats` | GET | Estatísticas do banco `leilao_app` |
| `?action=logs_cron` | GET | Histórico de logs de execuções do Cron |
| `?action=tokens_status` | GET | Status de saúde dos tokens Scrape.do & Firecrawl |

---

## 🚀 Como Iniciar

1. Inicie o servidor clicando duas vezes em [`iniciar.bat`](file:///c:/Users/Geo/Documents/IDEIAIS%20E%20COISAS/LEILAO/iniciar.bat)
2. Acesse:
   - **Vitrine Principal**: [http://localhost:8000/public/](http://localhost:8000/public/)
   - **Painel Administrativo & Cron**: [http://localhost:8000/public/admin.html](http://localhost:8000/public/admin.html)
