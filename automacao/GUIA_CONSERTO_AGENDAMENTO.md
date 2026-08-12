# Guia rápido — consertar a atualização automática dos dados

**Para quem vai executar:** qualquer pessoa com acesso à estação de trabalho onde ficam
os scripts (`C:\dashboard-custos\`) e a rede interna do GDF. Leva uns 15-20 minutos.

**O problema encontrado:** a atualização mensal (todo dia 10) parou de rodar sozinha desde
julho. Ela deveria disparar via Agendador de Tarefas do Windows, mas alguma coisa quebrou
nesse elo — a tarefa some, está desativada, ou a máquina estava desligada/deslogada na hora.

---

## Passo 1 — Verificar se a tarefa existe

1. Aperte `Win + R`, digite `taskschd.msc` e Enter.
2. No painel da esquerda, clique em **Biblioteca do Agendador de Tarefas**.
3. Procure por uma tarefa chamada **"Atualização Dashboard Custos"**.

**Se ela existir:**
- Clique nela e olhe embaixo, na aba **Histórico** — veja se aparece alguma execução em
  10/06, 10/07 ou 10/08 e se deu erro.
- Confira na aba **Disparadores** se está marcada como **Habilitado** e configurada para
  **Mensalmente, dia 10, às 09:00**.
- Confira na aba **Ações** se aponta para `C:\dashboard-custos\atualizar_dados.bat`.
- Clique com o botão direito → **Executar** para testar agora.

**Se ela NÃO existir** (foi apagada ou nunca foi criada de fato), pule para o Passo 2.

---

## Passo 2 — Recriar a tarefa (caso não exista ou esteja quebrada)

1. No Agendador de Tarefas, clique em **Ação → Criar Tarefa Básica...**
2. Nome: `Atualização Dashboard Custos`
3. Disparador: **Mensalmente** → marque **dia 10** → horário **09:00**
4. Ação: **Iniciar um programa**
5. Programa/script: `C:\dashboard-custos\atualizar_dados.bat`
6. Pasta de trabalho (campo "Iniciar em"): `C:\dashboard-custos`
7. Na tela final, marque **Abrir a caixa de diálogo Propriedades...** e confirme:
   - Aba **Geral**: marque **"Executar mesmo que o usuário não esteja conectado"**
     (evita depender de alguém estar logado no horário certo)
   - Aba **Configurações**: marque **"Executar a tarefa assim que possível após uma
     inicialização agendada perdida"** (se o PC estiver desligado às 09h do dia 10,
     ela roda assim que ligar)
8. Clique OK. Se pedir senha do Windows, informe a senha do usuário que tem acesso
   à rede do GDF e ao Oracle.

---

## Passo 3 — Testar

1. Clique com o botão direito na tarefa → **Executar**.
2. Aguarde alguns minutos.
3. Confira se apareceu um log novo em `C:\dashboard-custos\logs\`.
4. Confira no GitHub se houve um commit novo:
   https://github.com/brunorvmaciel/custos-ug-df/commits/main

Se der erro, o mais comum é:
- **Token do GitHub expirado** → gerar um novo em https://github.com/settings/tokens
  e atualizar `GITHUB_TOKEN` no topo de `extrair_dados.py` e `extrair_pt.py`
  (veja instruções na seção "Gerar novo token GitHub" do `README.md` principal do repositório).
- **Sem acesso à rede do GDF** (10.69.1.118) → precisa estar na rede interna/VPN.
- **Python ou bibliotecas não instaladas** → rodar `pip install oracledb requests`.

---

## Alternativa (opcional) — usar o Claude Code em vez do .bat puro

Se além de rodar os scripts vocês quiserem que a atualização seja **validada automaticamente**
antes de subir pro GitHub (conferindo se os dados não vieram vazios ou quebrados), existem dois
scripts prontos em `automacao/` neste mesmo repositório:

- `automacao/atualizar_dados.ps1`
- `automacao/registrar_tarefa_agendada.ps1`
- `automacao/README.md` (passo a passo)

Isso é opcional — o Passo 1-3 acima já resolve o problema sozinho, sem precisar de Claude Code
na máquina local.
