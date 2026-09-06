---
name: pr-workflow
description: >-
  Creates and completes Pull Requests under the team's rules: title format, mandatory
  description template fed by the local gate report, non-negotiable reviewer and
  assignee assignment resolved from CODEOWNERS or the collaborators API (never
  invented), check polling, squash merge and branch deletion.
  Trigger phrases (ES): "abre el PR", "crea el pull request", "asigna revisor",
  "rellena la descripción del PR", "mergea el PR", "título del PR".
  Does NOT create branches or commits (use `git-workflow`), does NOT review the code
  itself (use `pr-review`), does NOT run quality gates (use `quality-gates`).
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: 1.0.0
  owner: platform-engineering
  stability: stable
  pipeline-stage: "5,8"
  modes:
    - create
    - merge
  anti-triggers:
    - "crea la rama / haz el commit -> usar git-workflow"
    - "revisa el PR / analiza el diff -> usar pr-review"
    - "corre los checks locales -> usar quality-gates"
  requires:
    - git-workflow@^1.0.0
    - quality-gates@^1.0.0
  provides:
    - pr_number
    - pr_url
    - head_sha
  consumes:
    - branch_name
    - gate_report
    - verdict            # solo en modo `merge`, procedente de pr-review
---

# PR Workflow

> **Una frase:** gobierna el objeto Pull Request remoto — creación, asignación, checks
> y merge — con comandos exactos y cero invención de personas.

---

## 1. Contexto y Propósito

### 1.1 Qué hace

- Componer el título del PR en formato `tipo: descripción`.
- Rellenar la plantilla de descripción, alimentando "¿Cómo probarlo?" con el `gate_report`.
- **Resolver** revisor y assignee desde fuentes verificables, nunca por inferencia.
- Crear el PR y **verificar** que la asignación se aplicó realmente.
- Sondear los checks de CI con `gh pr checks --watch`.
- Hacer **Squash and merge** y borrar la rama.

### 1.2 Qué NO hace

| Fuera de alcance | Skill responsable |
| --- | --- |
| Crear ramas, commits o hacer push | `git-workflow` |
| Descubrir y ejecutar linter, tipos, pruebas o build | `quality-gates` |
| Leer el diff y juzgar bugs, seguridad, cobertura o duplicación | `pr-review` |
| Publicar un review o aprobar el PR | `pr-review` |
| Corregir hallazgos de una revisión | `code-review [remediation]` |

### 1.3 Posición en el pipeline

**Etapa 5:** `git-workflow [commit]` -> **`pr-workflow [create]`** -> `pr-review`
**Etapa 8:** `pr-review (verdict: approve)` -> **`pr-workflow [merge]`** -> `[fin]`

---

## 2. Activación

### 2.1 Activar cuando

- El usuario dice: "abre el PR", "crea el pull request", "asigna revisor",
  "rellena la descripción del PR", "mergea el PR", "título del PR".
- Se detecta el estado: hay una rama pusheada sin PR asociado.

### 2.2 Modos de operación

| Modo | Etapa | Se activa cuando | Protocolo |
| --- | --- | --- | --- |
| `create` | 5 | Rama pusheada, gates en verde, sin PR abierto | §4.A |
| `merge` | 8 | PR aprobado y checks verdes | §4.B |

### 2.3 NO activar cuando

| Situación | Skill correcta |
| --- | --- |
| "crea la rama" / "haz el commit" | `git-workflow` |
| "revisa el PR #N" / "analiza este diff" | `pr-review` |
| "corre los checks" | `quality-gates` |

---

## 3. Prerrequisitos y Entradas Esperadas

### 3.1 Contrato de entrada

| Entrada | Tipo | Requerido | Origen | Default | Si falta |
| --- | --- | --- | --- | --- | --- |
| `branch_name` | `string` | Sí | `git-workflow` / `git rev-parse` | rama actual | usar default |
| `gate_report` | `json` | Sí (modo `create`) | `quality-gates` | — | **No abrir el PR -> §6.1** |
| `reviewer` | `login` | Sí (modo `create`) | cadena de resolución §3.4 | — | **PREGUNTAR Y DETENER -> §6.2** |
| `assignee` | `login` | Sí (modo `create`) | cadena de resolución §3.4 | — | **PREGUNTAR Y DETENER -> §6.2** |
| `issue_id` | `string` | No | argumento del usuario / rama | — | Omitir la referencia, declararlo |
| `pr_number` | `int` | Sí (modo `merge`) | `pr-workflow [create]` / `gh pr list` | — | **PREGUNTAR** |

### 3.2 Precondiciones verificables

```bash
gh auth status                                   # esperado: autenticado
gh repo view --json nameWithOwner -q .nameWithOwner
git ls-remote --exit-code --heads origin "<branch_name>"    # rama pusheada
gh pr list --head "<branch_name>" --json number,url         # esperado: vacío en modo create
```

### 3.3 Archivos a leer obligatoriamente

| Ruta | Cuándo | Por qué |
| --- | --- | --- |
| `references/reviewer-assignment-policy.md` | §4.A Paso 2 | Cadena de resolución y prohibiciones |
| `references/pr-commands.md` | §4.A Paso 4, §4.B | Sintaxis exacta de `gh` |
| `assets/pr-description-template.md` | §4.A Paso 3 | Estructura del cuerpo del PR |

### 3.4 Resolución de revisor y assignee

Ver `references/reviewer-assignment-policy.md`. Resumen del orden:
**1)** valor dado por el usuario -> **2)** `CODEOWNERS` sobre las rutas del diff ->
**3)** `gh api repos/<owner>/<repo>/collaborators` -> **4)** **preguntar y detener**.

---

## 4. Protocolo de Ejecución

### §4.A — Modo `create`

#### Paso 1 — Verificar el gate report

```bash
jq -r '.status' .agent/handoff/quality-gates.json
```

**Condición de completitud:** `SUCCESS`.
**Si falla:** **no abrir el PR.** Devolver el control a `quality-gates`. -> §6.1

#### Paso 2 — Resolver revisor y assignee

**Acción:** aplicar la cadena de `references/reviewer-assignment-policy.md` §1.

**Condición de completitud:** un login de revisor **y** uno de assignee, ambos
verificados contra una fuente real, con el revisor distinto del autor.

**Si ninguna fuente resuelve:** **PREGUNTAR AL USUARIO Y DETENER.** -> §6.2

#### Paso 3 — Componer título y cuerpo

**Título:** `tipo: descripción corta del cambio`, con los tipos de
`git-workflow/references/commit-message-policy.md` §1. Aplica igual aunque la rama sea
`claude/…` o `codex/…`.

**Cuerpo:** rellenar `assets/pr-description-template.md` en un archivo temporal.
La tabla de "¿Cómo probarlo?" se alimenta del `gate_report` — **no se transcribe a
mano ni se estima**.

> Si el cambio es muy simple se puede resumir, pero **la estructura se mantiene**.
> Nunca colapsar las 4 secciones.

#### Paso 4 — Crear el PR (requiere confirmación)

**Acción irreversible y pública.** Mostrar al usuario título, cuerpo, revisor y
assignee, y **esperar confirmación explícita** antes de ejecutar.

```bash
gh pr create --base main --head "<branch_name>" \
  --title "<tipo>: <descripción>" --body-file <ruta.md> \
  --reviewer <login> --assignee <login>
```

#### Paso 5 — Verificar la asignación (obligatorio)

`gh pr create` puede crear el PR y fallar en silencio la asignación.

```bash
gh pr view <N> --json number,url,reviewRequests,assignees,isDraft
```

**Condición de completitud:** `reviewRequests` y `assignees` **no vacíos**.
**Si vienen vacíos:** `gh pr edit <N> --add-reviewer <login> --add-assignee <login>`. -> §6.3

#### Paso 6 — Sondear los checks

```bash
gh pr checks <N> --watch --interval 30; echo "exit_code=$?"
```

**Condición de completitud:** `exit_code 0`.
**Si `8` (pendientes) tras 15 min:** `STATUS: PARTIAL`, listar los checks pendientes
por nombre. -> §6.4
**Si otro valor:** algún check falló -> `STATUS: BLOCKED`, devolver a
`code-review [remediation]`. -> §6.5

---

### §4.B — Modo `merge`

#### Paso 1 — Verificar las condiciones de merge

```bash
gh pr view <N> --json reviewDecision,mergeable,mergeStateStatus,statusCheckRollup
```

**Condición de completitud:** `reviewDecision == APPROVED`, `mergeable == MERGEABLE`,
`mergeStateStatus == CLEAN`. Las tres, observadas. -> §6.6 / §6.7 si no.

#### Paso 2 — Mergear (requiere confirmación)

**Acción irreversible.** Mostrar el título final (que será el mensaje en `main`) y
**esperar confirmación explícita**.

```bash
gh pr merge <N> --squash --delete-branch
```

#### Paso 3 — Limpiar en local

```bash
git checkout main && git pull origin main && git branch -d <branch_name>
```

### Diagrama de flujo

```
[gate verde] ──> [resolver revisor] ──> [componer] ──CONFIRMA──> [gh pr create]
                        │                                              │
                   no resuelve                                         ▼
                        ▼                                    [verificar asignación]
              PREGUNTAR Y DETENER                                      │
                                                                       ▼
                                                            [gh pr checks --watch]
                                        rojo ◄──────────────────────┤ verde
                                          │                          ▼
                              [code-review remediation]        [pr-review]
                                                                     │ approve
                                                                     ▼
                                                    CONFIRMA ──> [merge --squash]
```

---

## 5. Contrato de Salida

### 5.1 Artefacto producido

**Formato:** PR creado o mergeado en GitHub, más el JSON de handoff.
**Plantilla del cuerpo:** `assets/pr-description-template.md`.

```json
// .agent/handoff/pr-workflow.json
{
  "skill": "pr-workflow",
  "version": "1.0.0",
  "mode": "create",
  "status": "SUCCESS",
  "pr_number": 42,
  "pr_url": "https://github.com/<owner>/<repo>/pull/42",
  "head_sha": "<sha>",
  "base": "main",
  "title": "feat: agregar campos personalizados a contactos",
  "reviewers": ["<login>"],
  "assignees": ["<login>"],
  "reviewer_source": "CODEOWNERS",
  "checks": { "exit_code": 0, "state": "all green" }
}
```

`reviewer_source` es obligatorio: documenta de qué fuente salió cada persona y hace
auditable el cumplimiento de §3.4.

### 5.2 Efectos laterales

| Efecto | Reversible | Requiere confirmación explícita |
| --- | --- | --- |
| **Crear el PR** (público, notifica) | Cerrable, no borrable | **Sí** |
| **Solicitar review a una persona** | Sí | **Sí** (va en la misma confirmación) |
| **Squash and merge a `main`** | **No** | **Sí** |
| **Borrar la rama remota** | Restaurable poco tiempo | **Sí** (misma confirmación del merge) |

### 5.3 Estado de handoff

```
STATUS: SUCCESS | BLOCKED | PARTIAL
ARTIFACTS: .agent/handoff/pr-workflow.json
BLOCKERS: <checks rojos, falta de aprobación, conflictos, o "ninguno">
NEXT: pr-review | code-review [modo: remediation] | [fin]
```

---

## 6. Manejo de Errores y Edge Cases

| # | Caso | Detección | Acción | Nunca hacer |
| --- | --- | --- | --- | --- |
| 6.1 | Sin `gate_report` verde | `status != SUCCESS` o ausente | **No abrir el PR;** devolver a `quality-gates` | Abrir el PR "para que lo vea CI" |
| 6.2 | Revisor/assignee sin resolver | Cadena §3.4 agotada | **PREGUNTAR Y DETENER** | Inferir un login de commits, nombres o convenciones |
| 6.3 | Asignación silenciosamente vacía | `reviewRequests` o `assignees` vacío | `gh pr edit --add-reviewer/--add-assignee` y reverificar | Dar el PR por creado |
| 6.4 | Checks pendientes indefinidamente | `exit_code 8` tras 15 min | Listar los pendientes por nombre; `STATUS: PARTIAL` | Declarar verde sin salida del comando |
| 6.5 | Checks en rojo | `exit_code` distinto de 0 y 8 | `STATUS: BLOCKED`; devolver a `code-review [remediation]` | Mergear igualmente |
| 6.6 | Conflictos de merge | `mergeable != MERGEABLE` | Reportar; devolver a `git-workflow` para sincronizar con `main` | Resolver conflictos sin revisión humana |
| 6.7 | Sin aprobación | `reviewDecision != APPROVED` | **DETENER.** El PR requiere al menos 1 aprobación humana | Mergear sin aprobación |
| 6.8 | Ya existe un PR para la rama | `gh pr list --head` no vacío | Cambiar a actualizar (`gh pr edit`) e informar | Crear un PR duplicado |
| 6.9 | Sin permisos para asignar | `gh` devuelve 403/422 | Reportar el login rechazado y preguntar por otro | Crear el PR sin asignación |
| 6.10 | Rama no pusheada | `git ls-remote` sin resultado | Devolver a `git-workflow [commit]` Paso 4 | Crear el PR contra una rama inexistente |

### 6.11 Regla de degradación

Si el protocolo no puede completarse: entregar lo hecho (PR creado en draft, o creado
sin merge), declarar lo pendiente y emitir `STATUS: PARTIAL`. Nunca declarar un PR
"listo para mergear" sin haber observado las tres condiciones de §4.B Paso 1.

---

## 7. Reglas Innegociables

1. **Evidencia > afirmación.** Todo estado reportado procede de una salida de comando.
   En concreto: **nunca declarar los checks en verde sin la salida de `gh pr checks`.**
2. **Cero invención.** Logins de GitHub, números de PR y URLs: si no se observaron
   contra una fuente real, no se escriben. Ante duda, preguntar.
3. **Sin efectos irreversibles sin confirmación.** Crear el PR y mergear son públicos
   e irreversibles: mostrar el contenido exacto y esperar el "sí".
4. **Idioma de la salida = idioma del usuario.**
5. **Responsabilidad humana no delegable** sobre lo que llega a `main`, aunque el
   cambio lo haya generado una herramienta de AI.

### Reglas específicas de esta skill

6. **Un PR sin revisor ni responsable no será revisado.** Nunca dejar un PR sin asignar.
7. **`--squash` siempre**, y `--delete-branch` en el mismo comando.
8. **Fuente única:** las reglas de merge y protección de `main` viven aquí (§4.B), no
   en `git-workflow`.

---

## 8. Recursos

| Ruta | Tipo | Cuándo cargar |
| --- | --- | --- |
| `references/reviewer-assignment-policy.md` | Conocimiento | §4.A Paso 2 |
| `references/pr-commands.md` | Conocimiento | §4.A Pasos 4-6, §4.B |
| `assets/pr-description-template.md` | Plantilla de salida | §4.A Paso 3 |
