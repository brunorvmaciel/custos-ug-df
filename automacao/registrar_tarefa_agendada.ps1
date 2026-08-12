<#
.SYNOPSIS
    Registra no Agendador de Tarefas do Windows a tarefa mensal que roda
    atualizar_dados.ps1 (Claude Code) para atualizar dados/ e dados_pt/.

.DESCRIPTION
    Execute este script UMA VEZ, localmente, como Administrador, na mesma
    maquina/usuario onde o Claude Code CLI ja esta autenticado (claude login)
    e onde o repositorio esta clonado em C:\dashboard-custos.

    Ele cria a tarefa "Atualizacao Dashboard Custos (Claude Code)", agendada
    para todo dia 10 do mes as 09:00, executando atualizar_dados.ps1.

.NOTES
    Rode em um PowerShell "Executar como administrador":
        cd C:\dashboard-custos
        .\registrar_tarefa_agendada.ps1
#>

$ErrorActionPreference = "Stop"

$TaskName    = "Atualizacao Dashboard Custos (Claude Code)"
$ScriptPath  = "C:\dashboard-custos\atualizar_dados.ps1"
$WorkDir     = "C:\dashboard-custos"

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Nao encontrei $ScriptPath. Copie atualizar_dados.ps1 para C:\dashboard-custos antes de registrar a tarefa."
    exit 1
}

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" `
    -WorkingDirectory $WorkDir

# Todo dia 10 de cada mes, as 09:00 - mesmo horario do agendamento atual
$Trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth 10 -At 9am

# Roda com o usuario atual, apenas quando ele estiver logado (evita ter que
# guardar senha para "rodar mesmo deslogado"). Ajuste -LogonType se preferir
# rodar a tarefa mesmo com a sessao fechada (nesse caso use -LogonType Password
# e informe -User/-Password no Register-ScheduledTask).
$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Tarefa '$TaskName' ja existe. Removendo versao antiga antes de recriar..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description "Executa o Claude Code para rodar extrair_dados.py e extrair_pt.py, validar e publicar dados/ e dados_pt/ do dashboard de custos GDF."

Write-Host "Tarefa '$TaskName' registrada com sucesso."
Write-Host "Confira em: taskschd.msc -> Biblioteca do Agendador de Tarefas"
Write-Host "Para testar agora: Start-ScheduledTask -TaskName `"$TaskName`""
