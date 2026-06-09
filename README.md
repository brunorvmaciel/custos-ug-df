# Dashboards de Custos — GDF

Dashboards interativos de custos do Governo do Distrito Federal, publicados via GitHub Pages e alimentados por ETL automatizado a partir do banco Oracle (SIGGO).

🔗 **Acesso público:** https://brunorvmaciel.github.io/custos-ug-df/

---

## Arquitetura

```
Oracle (ORAPRD06 — 10.69.1.118:1521)
    ↓ extrair_dados.py  (Python + oracledb)      → dados por Unidade Gestora
    ↓ extrair_pt.py     (Python + oracledb)      → dados por Programa de Trabalho
         ↓
    data/dados/*.json        →  git push  →  GitHub Pages  (custos por UG)
    data/dados_pt/*.json     →  git push  →  GitHub Pages  (custos por PT)
                                    ↓
                           Dashboards HTML
              (browser busca JSON direto do GitHub raw content)
```

O ETL roda automaticamente todo **dia 10 do mês às 09:00** via **Agendador de Tarefas do Windows** na estação local.

---

## Dashboards disponíveis

| Dashboard | Arquivo | Descrição |
|-----------|---------|-----------|
| Página inicial | `index.html` | Menu de acesso aos três painéis |
| Custos por UG | `ug.html` | Custos por Unidade Gestora — evolução mensal, anual e comparativos |
| Custos por PT | `pt.html` | Custos por Programa de Trabalho — ranking de PTs e UGs |
| Custo por Habitante | `ra.html` | Mapa interativo do DF com custo por habitante por Região Administrativa |

---

## Estrutura do projeto

```
custos-ug-df/
├── index.html                    # Página inicial — links para os dashboards
├── ug.html                       # Dashboard Custos por Unidade Gestora
├── pt.html                       # Dashboard Custos por Programa de Trabalho
├── ra.html                       # Dashboard Custo por Habitante (mapa DF)
│
├── dados/                        # JSONs de custos por UG (um por ano)
│   ├── index.json                # Índice com lista de exercícios disponíveis
│   ├── 2015.json
│   ├── 2016.json
│   ├── ...
│   └── 2026.json
│
├── dados_pt/                     # JSONs de custos por PT (um por ano)
│   ├── index.json                # Índice com lista de exercícios disponíveis
│   ├── 2020.json
│   ├── ...
│   └── 2026.json
│
└── C:\dashboard-custos\          # Pasta local na estação de trabalho
    ├── extrair_dados.py          # ETL — custos por UG
    ├── extrair_pt.py             # ETL — custos por PT
    └── atualizar_dados.bat       # Script de automação mensal
```

---

## Fonte dos dados

| Dado | Fonte | Tabela Oracle |
|------|-------|---------------|
| Custos por UG | SIGGO | `MIL2001.saldocontabil_EX` |
| Custos por PT | SIGGO | `MILaaaa.CONSULTORCUG` + `MILaaaa.PT` + `MILaaaa.UNIDADEGESTORA` |
| Dados demográficos | Codeplan — Projeções Populacionais por RA do DF 2020–2030 | — |
| De-Para RA × UG | Planilha interna `De-Para_RA-UG.xlsx` | — |

> **Nota:** os dados de PT usam schemas separados por ano (`MIL2020`, `MIL2021` ... `MIL2026`). Cada schema contém as tabelas `CONSULTORCUG`, `PT` e `UNIDADEGESTORA` do respectivo exercício.

---

## Categorias de custo

Os custos são classificados em 7 categorias a partir das contas contábeis:

| Categoria | Contas contábeis (prefixo) |
|-----------|---------------------------|
| Laborais | 88111, 88211, 88311, 88121, 88221, 88321 |
| Materiais | 88112, 88212, 88312, 88122, 88222, 88322 |
| Serviços | 88113, 88213, 88313, 88123, 88223, 88323 |
| Serviço da Dívida | 88114, 88214, 88314, 88124, 88224, 88324 |
| Funcionamento | 88115, 88215, 88315, 88125, 88225, 88325 |
| Benefício | 88116, 88216, 88316, 88126, 88226, 88326 |
| Investimento | 88117, 88217, 88317, 88127, 88227, 88327 |

---

## Configuração do ambiente

### Pré-requisitos

- Python 3.10+
- Oracle Client instalado em `C:\Program Files\Oracle Client for Microsoft Tools`
- Acesso à rede interna do GDF (IP `10.69.1.118`)
- Token GitHub com permissão `repo`

### Instalar dependências

```cmd
pip install oracledb requests flask flask-cors
```

### Credenciais Oracle

As credenciais estão fixas nos scripts. Para alterar, edite as variáveis no topo de cada arquivo:

```python
# em extrair_dados.py e extrair_pt.py
ORACLE_USER   = "usefp62"
ORACLE_PASS   = "mar2024"
ORACLE_DSN    = "10.69.1.118:1521/oraprd06"
GITHUB_TOKEN  = "seu_token_aqui"
GITHUB_USER   = "brunorvmaciel"
GITHUB_REPO   = "custos-ug-df"
```

### Gerar novo token GitHub

1. Acesse: https://github.com/settings/tokens
2. Clique em **Generate new token (classic)**
3. Note: `custos-ug`  ·  Expiration: `No expiration`
4. Marque: ✅ **repo**
5. Copie o token e substitua em `GITHUB_TOKEN` nos dois scripts

---

## Executar os scripts manualmente

```cmd
cd C:\dashboard-custos
python extrair_dados.py
python extrair_pt.py
```

Os scripts são **incrementais**:
- Dados históricos (anos anteriores ao atual) são mantidos no GitHub — **não reextraem do Oracle**
- Apenas o ano corrente é reextraído, a partir do último mês disponível

---

## Lógica incremental dos ETLs

### extrair_dados.py

```
1. Verifica index.json no GitHub → descobre quais anos já existem
2. Baixa histórico (2015–2025) do GitHub sem acessar o Oracle
3. Consulta o Oracle apenas para o ano atual (2026+)
4. Combina histórico + dados novos
5. Faz upload de um arquivo por ano + atualiza index.json
```

### extrair_pt.py

```
1. Verifica index.json no GitHub → descobre quais anos já existem
2. Mantém 2020–2025 intocados no GitHub
3. Consulta o Oracle apenas o ano atual, a partir do último mês disponível
4. Combina meses anteriores do cache + meses novos
5. Faz upload apenas do ano atual + atualiza index.json
```

---

## Automação — Agendador de Tarefas do Windows

O script `atualizar_dados.bat` roda automaticamente todo **dia 10 às 09:00** via Agendador de Tarefas do Windows.

### Configuração (já realizada)

A tarefa foi criada com:
- **Nome:** `Atualização Dashboard Custos`
- **Gatilho:** Mensalmente, dia 10, às 09:00
- **Ação:** `C:\dashboard-custos\atualizar_dados.bat`
- **Pasta de trabalho:** `C:\dashboard-custos`

### Verificar se a tarefa existe

```
Win + R → taskschd.msc → Biblioteca do Agendador → "Atualização Dashboard Custos"
```

### Recriar a tarefa (se necessário)

```
taskschd.msc → Criar Tarefa Básica → preencher conforme acima
```

### Logs de execução

Cada execução gera um log em:
```
C:\dashboard-custos\logs\atualizacaoAAAAMMDD.txt
```

### Executar manualmente

Clique com botão direito na tarefa → **Executar**

Ou via linha de comando:
```cmd
C:\dashboard-custos\atualizar_dados.bat
```

---

## Adicionar novo dashboard

1. Crie o arquivo HTML na raiz do repositório (ex: `despesa.html`)
2. Adicione o botão **← INÍCIO** no cabeçalho apontando para `index.html`
3. Adicione um novo card em `index.html` apontando para o novo arquivo
4. Se precisar de novos dados, crie o script de extração seguindo o padrão de `extrair_dados.py`
5. Adicione a chamada do novo script em `atualizar_dados.bat`

---

## Adicionar novo exercício

Os exercícios são detectados automaticamente pelo `extrair_dados.py` via:

```sql
SELECT DISTINCT COEXERCICIO FROM MIL2001.saldocontabil_EX ORDER BY COEXERCICIO DESC
```

Para o dashboard de PT, novos schemas `MILaaaa` são detectados automaticamente incrementando `ANO_ATUAL` no script.

---

## Reverter dados para versão anterior

### Ver histórico de commits

```cmd
git log --oneline
```

### Restaurar um arquivo específico

```cmd
git checkout <hash> -- dados/2026.json
git add .
git commit -m "fix: reverte dados de 2026 para versão anterior"
git push origin main
```

### Desfazer o último commit

```cmd
git revert HEAD
git push origin main
```

---

## Navegação dos dashboards

```
index.html  (Página inicial)
├── ug.html          → Custos por Unidade Gestora
├── pt.html          → Custos por Programa de Trabalho
└── ra.html          → Custo por Habitante (mapa DF)
```

---

## Contato e responsável

**Responsável:** Bruno V. Maciel  
**Setor:** Secretaria de Estado de Economia — Distrito Federal  
**Repositório:** https://github.com/brunorvmaciel/custos-ug-df  
**Dashboard:** https://brunorvmaciel.github.io/custos-ug-df/
