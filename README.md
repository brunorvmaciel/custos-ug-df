# Sistema de Custos — GDF

Dashboards interativos de custos do Governo do Distrito Federal, publicados via GitHub Pages e alimentados por ETL automatizado a partir dos bancos Oracle (SIGGO) e Informix (SIGRH).

🔗 **Acesso público:** https://sistema-custos-gdf.github.io/dashboards/
📦 **Repositório:** https://github.com/sistema-custos-gdf/dashboards

---

## Fluxo de trabalho

Este projeto é operado através do **Claude Code**, em linguagem natural — não é mais necessário editar scripts, rodar comandos ou publicar dados manualmente via VS Code/Git. As instruções são dadas em português diretamente ao Claude, que:

- Lê e edita os scripts Python de ETL
- Executa extrações do Oracle/Informix e publica os JSONs no GitHub (via API)
- Ajusta os dashboards HTML
- Gerencia credenciais, automações e a estrutura do repositório

Credenciais (Oracle, Informix, token do GitHub) ficam no arquivo local `.env` (nunca versionado) e são carregadas via `python-dotenv` — não há mais nada hardcoded nos scripts.

---

## Arquitetura

```
Oracle (ORAPRD06 — SIGGO)                    Informix (GDF_CLONE_a — SIGRH)
    ↓ extrair_dados.py  → custos por UG           ↓ extrair_pessoal.py → custos de pessoal
    ↓ extrair_pt.py     → custos por PT            ↓
         ↓                                         ↓
    dados/*.json         dados_pt/*.json      dados_pessoal/*.json
                              ↓ upload via API do GitHub (requests)
                     GitHub Pages (sistema-custos-gdf/dashboards)
                                    ↓
                           Dashboards HTML
              (browser busca JSON direto do GitHub raw content)
```

O ETL de UG/PT roda automaticamente todo **dia 10 do mês às 09:00** via **Agendador de Tarefas do Windows** na estação local (`atualizar_dados.bat`).

---

## Dashboards disponíveis

| Dashboard | Arquivo | Descrição | Status |
|-----------|---------|-----------|--------|
| Página inicial | `index.html` | Menu de acesso aos painéis | ✅ |
| Custos por UG | `ug.html` | Custos por Unidade Gestora — evolução mensal, anual e comparativos | ✅ |
| Custos por PT | `pt.html` | Custos por Programa de Trabalho — ranking de PTs e UGs | ✅ |
| Custo por Habitante | `ra.html` | Mapa interativo do DF com custo por habitante por Região Administrativa | ✅ |
| Custos de Pessoal | `pessoal.html` | Folha de pagamento por lotação, órgão e rubricas (SIGRH) — Visão Geral, Evolução, Composição, Força de Trabalho, Custos por Lotação, Análise de Rubricas | 🚧 em evolução (alinhado ao SDP) |

---

## Estrutura do projeto

```
dashboards/                          (repositório GitHub — sistema-custos-gdf)
├── index.html                    # Página inicial — links para os dashboards
├── ug.html                       # Dashboard Custos por Unidade Gestora
├── pt.html                       # Dashboard Custos por Programa de Trabalho
├── ra.html                       # Dashboard Custo por Habitante (mapa DF)
├── pessoal.html                  # Dashboard Custos de Pessoal
│
├── dados/                        # JSONs de custos por UG (um por ano)
│   ├── index.json
│   └── AAAA.json
│
├── dados_pt/                     # JSONs de custos por PT (um por ano)
│   ├── index.json
│   └── AAAA.json
│
└── dados_pessoal/                # JSONs de custos de pessoal (por competência AAAAMM)
    ├── index.json
    ├── rubricas/                 # Dicionário nome+natureza eSocial por órgão
    └── AAAAMM/
        ├── resumo.json           # Agregado leve (por órgão + por vínculo + CPF único)
        ├── rubricas_agregado.json # Agregado de rubricas GDF inteiro
        └── emp_<id>[_pN].json    # Detalhe por órgão (particionado se grande)

C:\dashboard-custos\               # Pasta local na estação de trabalho
├── .env                          # Credenciais (Oracle, Informix, GitHub) — NUNCA versionado
├── .gitignore
├── extrair_dados.py              # ETL — custos por UG (Oracle)
├── extrair_pt.py                 # ETL — custos por PT (Oracle)
├── extrair_pessoal.py            # ETL — custos de pessoal (Informix)
├── enriquecer_cpf_unico.py       # Passada leve — publica pessoas físicas únicas por CPF
├── atualizar_dados.bat           # Script de automação mensal (UG + PT)
└── logs/                         # Logs de execução do agendador
```

---

## Fonte dos dados

| Dado | Fonte | Tabela / Banco |
|------|-------|---------------|
| Custos por UG | SIGGO (Oracle) | `MIL2001.saldocontabil_EX` |
| Custos por PT | SIGGO (Oracle) | `MILaaaa.CONSULTORCUG` + `MILaaaa.PT` + `MILaaaa.UNIDADEGESTORA` |
| Custos de Pessoal | SIGRH (Informix) | `dbgestao` (via JDBC, schema por competência/empresa) |
| Dados demográficos | Codeplan — Projeções Populacionais por RA do DF 2020–2030 | — |
| De-Para RA × UG | Planilha interna `De-Para_RA-UG.xlsx` | — |

> **Nota:** os dados de PT usam schemas separados por ano (`MIL2020`, `MIL2021` ... `MIL2026`). Cada schema contém as tabelas `CONSULTORCUG`, `PT` e `UNIDADEGESTORA` do respectivo exercício.

---

## Categorias de custo

Os custos (UG/PT) são classificados em 7 categorias a partir das contas contábeis:

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
- Oracle Client instalado (caminho configurado em `.env` → `ORACLE_CLIENT`)
- Driver JDBC Informix (para `extrair_pessoal.py`)
- Acesso à rede interna do GDF
- Token GitHub com permissão `repo`

### Instalar dependências

```cmd
pip install oracledb requests flask flask-cors python-dotenv pandas jaydebeapi
```

### Credenciais — arquivo `.env`

As credenciais **não ficam mais no código**. Ficam em `C:\dashboard-custos\.env` (fora do controle de versão):

```
ORACLE_CLIENT=C:\Program Files\Oracle Client for Microsoft Tools
ORACLE_USER=usuario
ORACLE_PASS=senha
ORACLE_DSN=host:porta/servico

GITHUB_TOKEN=ghp_xxxxxxxxxxxx
GITHUB_USER=sistema-custos-gdf
GITHUB_REPO=dashboards

INFORMIX_HOST=host
INFORMIX_PORT=porta
INFORMIX_SERVER=servidor
INFORMIX_DB=banco
INFORMIX_USER=usuario
INFORMIX_PASS=senha
```

Os scripts carregam essas variáveis via `python-dotenv` (`load_dotenv()`).

### Gerar novo token GitHub

1. Acesse: https://github.com/settings/tokens
2. Clique em **Generate new token (classic)**
3. Note: `sistema-custos-gdf`  ·  Expiration: `No expiration`
4. Marque: ✅ **repo**
5. Copie o token e substitua `GITHUB_TOKEN` no `.env`

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
2. Baixa histórico do GitHub sem acessar o Oracle
3. Consulta o Oracle apenas para o ano atual
4. Combina histórico + dados novos
5. Faz upload de um arquivo por ano + atualiza index.json
```

### extrair_pt.py

```
1. Verifica index.json no GitHub → descobre quais anos já existem
2. Mantém anos anteriores intocados no GitHub
3. Consulta o Oracle apenas o ano atual, a partir do último mês disponível
4. Combina meses anteriores do cache + meses novos
5. Faz upload apenas do ano atual + atualiza index.json
```

### extrair_pessoal.py

```
1. Carrega a referencia oficial local (Portal da Transparencia DF), se existir
2. Verifica index.json em dados_pessoal/ → descobre quais competências (AAAAMM) já foram extraídas por completo
3. Extrai do Informix (SIGRH) até o último mês já PUBLICADO pelo Portal da Transparência DF (se a
   referência estiver carregada) — ficamos sempre alinhados ao que já foi validado externamente,
   mesmo que isso signifique ficar "um mês atrás" do calendário (praxe de dados abertos oficiais).
   Sem referência carregada, cai no heurístico antigo (mês anterior ao atual)
4. Para cada competência, itera todos os órgãos (empresas) disponíveis
5. Resolve a hierarquia completa de lotação (Órgão → Unidade Administrativa → ... → Lotação final),
   caminhando pelos segmentos de 2 dígitos do código de lotação contra a tabela de lotações do próprio órgão
6. Classifica cada servidor em um vínculo padronizado (Ativo/Inativo/Pensionista/Temporário/Outros/
   Cedido/Federal-SIAPE) — prioriza a referência oficial quando disponível para aquele órgão/mês,
   caindo no heurístico (dc_sit_func) fora da cobertura oficial
7. Classifica cada rubrica pela natureza oficial nacional do eSocial (ds_esocial_rubrica +
   ds_esocial_nat_rubrica), além do nome já existente em vw_contdf_rubrica
8. Grava um JSON por órgão (particionado em várias partes se muito grande, ex: SEE/SES) + um resumo
   agregado por competência + um agregado de rubricas GDF inteiro (rubricas_agregado.json)
9. Publica dicionário de rubricas (código → nome + natureza eSocial) uma vez por órgão, em arquivo separado
10. Uma competência só é marcada como "completa" no index se TODOS os órgãos foram extraídos com sucesso —
    se algum falhar (ex: banco fechou no meio), a competência fica marcada como incompleta e é
    reprocessada (só os órgãos faltantes seriam refeitos) na próxima execução
```

**Referência oficial (Portal da Transparência DF)** — `logs/referencia_oficial_servidores.json`:
arquivo local (**nunca publicado**, contém matrícula), destilado dos CSVs "Servidores_Orgao" baixados
manualmente em https://www.transparencia.df.gov.br/#/downloads#downloadServidores (dados abertos).
Mapeamento: `CÓDIGO DO ÓRGÃO` do portal = `"01" + empresa.zfill(5)` (ex: SEEC/empresa 7 → `0100007`).
Quando o órgão/mês está coberto pela referência, ela é a **fonte de verdade** para inclusão/classificação
— substitui os heurísticos abaixo. Para atualizar: baixar novo ZIP do portal, extrair, e regerar o JSON
(script usado uma vez, não versionado — ver histórico da sessão).

**Exclusões do quantitativo de pessoal** (não contam em `qtd_servidores`/`por_vinculo`, mas ficam no
arquivo bruto do órgão):
- **Cedido (exercício em outro órgão):** registro-espelho no órgão de ORIGEM de quem está cedido —
  a lotação de destino já conta essa pessoa como Ativo.
- **Federal (SIAPE):** Policiais Civis (PCDF) e militares não-comissionados (PMDF/CBMDF) são pagos via
  SIAPE federal, não pelo GDF — exclusão confirmada contra o glossário oficial do Painel Estatístico de
  Pessoal do GDF. Sem essa regra, o total de servidores ficava **~57% acima** do painel oficial (ex:
  CBMDF tinha 97% dos registros nessas categorias).
- **Não contabilizado (fora da referência oficial):** matrícula que o Portal da Transparência não lista
  para aquele órgão/mês, quando há cobertura oficial disponível.
- **Sem movimentação (heurístico, só fora da cobertura oficial):** bruto E desconto zerados no mês —
  não agregam custo algum àquela lotação. Validado contra o painel oficial: SEEC caiu de 7.920 para
  2.925 registros (oficial: 2.826) ao excluir esses.

**Pessoas físicas únicas (CPF):** como uma mesma pessoa pode ter mais de uma matrícula (mesmo órgão —
provável duplicidade de cadastro — ou órgãos diferentes — provável acúmulo legal de cargo), rodamos
`enriquecer_cpf_unico.py` após a extração para publicar `total_pessoas_unicas_cpf` no resumo de cada
competência, sem nunca expor CPF ou matrícula.

> **⚠️ Restrição do banco Informix (SIGRH/GDF_CLONE_a):** o ambiente passa por rotina diária de
> backup + restore. Backup termina por volta de **11h50**, restore roda até por volta de
> **16h40** — nesse intervalo (~12h–16h40) o banco **não aceita conexões** ("quiescent mode").
> Fora desse intervalo (17h ~ meio-dia do dia seguinte) o banco fica disponível. Por isso a
> extração de pessoal está agendada para começar às 17h30, dando margem de quase 19h antes do
> próximo bloqueio.

---

## Automação — Agendador de Tarefas do Windows

O script `atualizar_dados.bat` roda automaticamente todo **dia 10 às 17h30** via Agendador de Tarefas do Windows, executando, em sequência, `extrair_dados.py`, `extrair_pt.py` e `extrair_pessoal.py`. O horário foi escolhido para cair dentro da janela de disponibilidade do Informix (ver nota acima) com folga suficiente mesmo em execuções lentas.

### Configuração (já realizada)

- **Nome:** `Atualização Dashboard Custos`
- **Gatilho:** Mensalmente, dia 10, às 09:00
- **Ação:** `C:\dashboard-custos\atualizar_dados.bat`
- **Pasta de trabalho:** `C:\dashboard-custos`

### Verificar se a tarefa existe

```
Win + R → taskschd.msc → Biblioteca do Agendador → "Atualização Dashboard Custos"
```

### Logs de execução

```
C:\dashboard-custos\logs\atualizacaoAAAAMMDD.txt
```

### Executar manualmente

```cmd
C:\dashboard-custos\atualizar_dados.bat
```

---

## Reverter dados para versão anterior

Como o repositório não usa clone/push local (upload é feito via API do GitHub), a forma mais simples de reverter é restaurar o conteúdo de um arquivo específico direto pela interface do GitHub (histórico de commits do arquivo) ou pedir ao Claude Code para reenviar uma versão anterior salva localmente.

---

## Navegação dos dashboards

```
index.html  (Página inicial)
├── ug.html          → Custos por Unidade Gestora
├── pt.html          → Custos por Programa de Trabalho
├── ra.html          → Custo por Habitante (mapa DF)
└── pessoal.html     → Custos de Pessoal
```

---

## Contato e responsável

**Responsável:** Bruno V. Maciel
**Setor:** Secretaria de Estado de Economia — Distrito Federal
**Organização GitHub:** https://github.com/sistema-custos-gdf
**Repositório:** https://github.com/sistema-custos-gdf/dashboards
**Dashboard:** https://sistema-custos-gdf.github.io/dashboards/
