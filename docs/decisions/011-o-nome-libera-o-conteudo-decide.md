# AD-011 — O nome libera, o conteúdo decide

- **Status**: aceito — 2026-09-15, suíte do guard verde (26 PASS)
- **Date**: 2026-09-15
- **Scope**: `scripts/patterns/filenames-allow.txt` e três casos novos em
  `scripts/test-github-guard.sh`. Não muda o `github-guard.sh` nem a lista de bloqueio.

## O que estava quebrado

A regra de liberação era `\.env\.(example|template|sample)$`: ela ancorava `.env`
diretamente no sufixo, então só casava a forma nua `.env.example`. Qualquer
`.env.<sabor>.example` — `.env.xtts.example`, `.env.prod.template` — caía no bloqueio
`(^|/)\.env($|\.)` e era recusado como "arquivo de credenciais (pelo nome)".

Arquivo de placeholder, recusado por parecer segredo. E a convenção do sabor no meio é tão
comum quanto a forma nua.

## O custo real, que não é o arquivo

`scan_git` resolve o worktree a partir do `cwd` do hook — a pasta da **sessão**, não a do
repositório que está sendo enviado — e, quando o ramo não tem upstream, cai em
`git ls-tree -r HEAD`, ou seja, **todos os arquivos rastreados**. Um `.env.xtts.example`
versionado em um repo qualquer passa então a barrar `git push` de **qualquer** repo
enquanto a sessão estiver naquela pasta.

Medido em 2026-09-15: um push de `plataforma-product-ops` foi bloqueado por um arquivo de
`whisper-agent`, que nem estava no envio. O falso positivo não custa um arquivo, custa a
credibilidade do guard — guard que erra vira guard que se desliga, e aí ele não guarda mais
nada.

## A decisão

`\.env[^/]*\.(example|template|sample)$` — `[^/]*` entre as duas metades, preso ao mesmo
segmento de caminho.

O que sustenta alargar a liberação **por nome** é que ela não desliga a verificação de
**conteúdo**: `check_name` e `check_content` são chamadas independentes no laço de
`scan_git`. Um `.env.xtts.example` com uma chave de verdade dentro continua bloqueado — por
`content-block.txt`, que é quem tem competência para isso. O nome nunca foi evidência de
segredo; é heurística de intenção, e a intenção de `.example` é "preencha isto".

Três testes fixam as três metades da regra, porque só a primeira é óbvia:

- `O2` — `.env.<sabor>.example` passa;
- `O3` — um `ghp_…` de verdade **dentro** de um template ainda bloqueia (é este que prova
  que alargar o nome não abriu buraco);
- `O4` — `.env.production` continua bloqueado: não é template, é o arquivo real.

## Consequência

`.env.local` e `.env.production` seguem bloqueados, que é o caso que importa. A lista de
bloqueio não mudou. Quem quiser burlar precisa nomear o arquivo de template **e** manter o
segredo fora dele — e aí não é mais burla, é o comportamento correto.
