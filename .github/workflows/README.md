# CI Workflows (`.github/workflows`)

Este diretório contém os pipelines de **CI** dos 5 microserviços do ToggleMaster.

## Objetivo

Os workflows aqui fazem apenas **validação de código**:

- Build
- Testes
- Lint
- Security scan

> O **build/push de imagens para ECR não é feito por esses workflows**.
> A publicação de imagem é manual via `scripts/build-push-ecr.sh`.

---

## Workflows existentes

- `analytics-service.yml` (Python)
- `auth-service.yml` (Go)
- `evaluation-service.yml` (Go)
- `flag-service.yml` (Python)
- `targeting-service.yml` (Python)

---

## Quando cada workflow roda

Cada workflow dispara em:

1. `push` na branch `main` (somente quando há mudança no serviço correspondente)
2. `pull_request` para `main` (somente quando há mudança no serviço correspondente)
3. `workflow_dispatch` (execução manual)

Exemplo de filtro por path:

- `Kubernetes/<service>/**`
- `.github/workflows/<service>.yml`

---

## Estrutura padrão dos jobs

Todos os workflows seguem 3 jobs sequenciais:

1. **Build & Test**
2. **Lint**
3. **Security Scan**

Configurações comuns:

- `permissions: contents: read` (mínimo necessário)
- `concurrency` por serviço/branch com `cancel-in-progress: true`
- `run-name` descritivo (`<Service> CI • <event> • <ref>`)

---

## Ferramentas usadas

### Python services

- `pytest`
- `flake8`
- `bandit`
- `trivy-action` (filesystem scan)
- `docker build` (somente validação local de build)

### Go services

- `go build`, `go test`
- `golangci-lint`
- `gosec`
- `trivy-action` (filesystem scan)
- `docker build` (somente validação local de build)

---

## Relatório (Job Summary)

Cada job gera resumo em `GITHUB_STEP_SUMMARY` com:

- contexto do pipeline (service, event, ref, commit)
- tabela `Step | Result` com resultado por etapa
- status final `Overall` (`✅ SUCCESS` ou `❌ FAILURE`)

Mesmo em falha, o resumo final é gerado com `if: always()`.

---

## Como rodar manualmente

No GitHub:

1. Abra **Actions**
2. Selecione o workflow do serviço
3. Clique em **Run workflow**
4. Escolha a branch e execute

---

## Convenções para manutenção

Ao criar/alterar workflow:

- manter escopo CI (não incluir push de imagem)
- manter 3 estágios (`Build & Test` → `Lint` → `Security Scan`)
- manter summary com tabela por etapa
- manter filtros por path para evitar execução desnecessária

---

## Troubleshooting rápido

- **Workflow não dispara**
  - Verifique se os arquivos alterados batem no `paths` do workflow

- **Resumo sem status claro**
  - Verifique se o step final `... result` com `if: always()` foi mantido

- **Falha no Trivy/gosec/bandit**
  - Corrija as vulnerabilidades reportadas, ou ajuste severidade conforme política do time
