<#
.SYNOPSIS
    Atualiza os dashboards de custos GDF (dados/ e dados_pt/) usando o Claude Code
    para rodar extrair_dados.py e extrair_pt.py, validar a saída e dar push no GitHub.

.DESCRIPTION
    Substitui o antigo atualizar_dados.bat. Em vez de só chamar os scripts Python
    diretamente, delega a execução ao Claude Code (modo headless / "print mode"),
    que roda os ETLs, confere se dados/ e dados_pt/ foram atualizados corretamente
    e só então commita e dá push.

    Pré-requisitos na máquina que executa este script:
      - Claude Code CLI instalado e autenticado (claude login) com o usuário
        que vai rodar a tarefa agendada.
      - Python 3.10+ com oracledb e requests instalados.
      - Acesso à rede interna do GDF (10.69.1.118) e ao Oracle Client.
      - Repositório custos-ug-df clonado em C:\dashboard-custos com um remote
        configurado com permissão de push (token GitHub com escopo repo).

.NOTES
    Chamado pela tarefa agendada "Atualizacao Dashboard Custos (Claude Code)".
    Ver registrar_tarefa_agendada.ps1 para o registro da tarefa.
#>

$ErrorActionPreference = "Stop"

$RepoPath  = "C:\dashboard-custos"
$LogDir    = Join-Path $RepoPath "logs"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile   = Join-Path $LogDir "atualizacao_$Timestamp.log"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Write-Output $line
    Add-Content -Path $LogFile -Value $line
}

Log "=== Iniciando atualizacao mensal de dados (dados/ e dados_pt/) ==="

if (-not (Test-Path $RepoPath)) {
    Log "ERRO: diretorio do repositorio nao encontrado em $RepoPath"
    exit 1
}

Set-Location $RepoPath

# Garante que o repo local esta atualizado antes de rodar o ETL
try {
    Log "Atualizando branch local (git pull)..."
    git pull origin main 2>&1 | ForEach-Object { Log $_ }
}
catch {
    Log "AVISO: falha ao dar git pull antes de comecar: $($_.Exception.Message)"
}

$prompt = @"
Rode extrair_dados.py e extrair_pt.py neste diretorio (C:\dashboard-custos).
Depois confira se os arquivos em dados/ e dados_pt/ do repositorio custos-ug-df
foram atualizados corretamente (novo mes/ano presente, index.json coerente com
os arquivos existentes, JSONs validos e nao vazios).

Se tudo estiver correto:
  - faca commit com mensagem no padrao "Atualizacao - DD/MM/AAAA HH:MM"
  - de push para o branch main do repositorio custos-ug-df

Se algum dos dois scripts falhar, ou se os dados gerados parecerem invalidos
(vazios, incompletos ou com erro), NAO faca commit nem push. Em vez disso,
explique claramente qual foi o problema encontrado.
"@

Log "Chamando Claude Code para executar o ETL e o push..."

try {
    $result = claude -p $prompt `
        --allowedTools "Bash,Edit,Read,Write" `
        --permission-mode acceptEdits 2>&1

    $result | ForEach-Object { Log $_ }

    if ($LASTEXITCODE -ne 0) {
        Log "ERRO: Claude Code retornou codigo de saida $LASTEXITCODE"
        exit 1
    }

    Log "=== Atualizacao concluida ==="
}
catch {
    Log "ERRO: $($_.Exception.Message)"
    exit 1
}
