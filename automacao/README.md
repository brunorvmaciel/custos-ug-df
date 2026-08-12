# Automação via Claude Code + PowerShell + Agendador de Tarefas

Alternativa ao runner self-hosted do GitHub Actions (`.github/workflows/atualizar_dados.yml`):
em vez de o GitHub Actions disparar um runner na estação local, o **Agendador de Tarefas do
Windows** dispara diretamente um script PowerShell que usa o **Claude Code** para rodar o ETL,
validar a saída e publicar os dados.

## Arquivos

| Arquivo | Função |
|---|---|
| `atualizar_dados.ps1` | Roda `extrair_dados.py` e `extrair_pt.py` via Claude Code, valida `dados/` e `dados_pt/`, faz commit e push. |
| `registrar_tarefa_agendada.ps1` | Registra a tarefa mensal (dia 10, 09:00) no Agendador de Tarefas do Windows. |

## Instalação (uma vez, na estação de trabalho)

1. Copie os dois arquivos `.ps1` para `C:\dashboard-custos\` (mesma pasta de `extrair_dados.py` e `extrair_pt.py`).
2. Garanta que o Claude Code CLI está instalado e autenticado com o usuário que vai rodar a tarefa:
   ```powershell
   claude login
   ```
3. Abra um PowerShell **como Administrador** e rode:
   ```powershell
   cd C:\dashboard-custos
   .\registrar_tarefa_agendada.ps1
   ```
4. Teste manualmente:
   ```powershell
   Start-ScheduledTask -TaskName "Atualizacao Dashboard Custos (Claude Code)"
   ```
5. Confira o log gerado em `C:\dashboard-custos\logs\`.

## Observações

- Este método **substitui** a necessidade do runner self-hosted do GitHub Actions para essa
  rotina — o workflow em `.github/workflows/atualizar_dados.yml` pode continuar existindo
  como *fallback* manual (`workflow_dispatch`), sem precisar do runner ativo o tempo todo.
- Só funciona rodando na máquina com acesso à rede interna do GDF e ao Oracle
  (`10.69.1.118:1521`), pelos mesmos motivos já documentados no README principal do repositório.
- Ninguém remoto (incluindo sessões do Claude Code na nuvem) consegue rodar essa automação —
  ela depende do acesso local à rede interna do GDF.
