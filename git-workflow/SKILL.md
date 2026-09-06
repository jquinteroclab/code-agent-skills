---
name: git-workflow
description: >-
  Applies the team's official Git flow (GitHub Flow) in the local worktree: branch
  creation from main with provenance-based prefixes, Conventional Commits, and the
  mandatory quality gate before any commit. Enforces that AI-generated work is
  traceable and human-reviewed.
  Trigger phrases (ES): "crea una rama", "haz el commit", "sube la rama",
  "cómo nombro esta rama", "convención de commits", "flujo de git del equipo".
  Does NOT run the quality suite itself (delegates to `quality-gates`), does NOT
  create or merge Pull Requests (use `pr-workflow`), does NOT review code.
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: 1.0.0
  owner: platform-engineering
  stability: stable
  pipeline-stage: "1,4"
  modes:
    - branch
    - commit
  anti-triggers:
    - "abre el PR -> usar pr-workflow"
    - "corre los checks -> usar quality-gates"
    - "revisa el código -> usar code-review"
    - "reglas de merge de main -> usar pr-workflow"
  requires:
    - quality-gates@^1.0.0   # solo en modo `commit`
  provides:
    - branch_name
    - commit_sha
    - pushed
  consumes:
    - gate_report            # solo en modo `commit`
---

# Git Workflow

> **Una frase:** gobierna todo lo que ocurre en el worktree local — ramas, commits y
> push — con trazabilidad de procedencia humano/agente.

---

## 1. Contexto y Propósito

### 1.1 Qué hace

- Crear ramas desde `main` actualizado, con prefijo de procedencia.
- Validar el nombre de rama contra la política antes de crearla.
- Generar commits en Conventional Commits, verificando el formato.
- **Bloquear el commit** si no existe un `gate_report` verde de `quality-gates`.
- Publicar la rama en el remoto.

### 1.2 Qué NO hace

| Fuera de alcance | Skill responsable |
| --- | --- |
| Descubrir y ejecutar linter, tipos, pruebas o build | `quality-gates` |
| Reglas de merge y protección de `main` | `pr-workflow` (fuente única) |
| Crear, describir, asignar o mergear Pull Requests | `pr-workflow` |
| Auditar bugs, seguridad, cobertura o duplicación | `code-review` |
| Publicar reviews en GitHub | `pr-review` |

### 1.3 Posición en el pipeline

**Etapa 1:** `[inicio]` -> **`git-workflow [branch]`** -> `⟨desarrollo⟩`
**Etapa 4:** `quality-gates` -> **`git-workflow [commit]`** -> `pr-workflow [create]`

---

## 2. Activación

### 2.1 Activar cuando

- El usuario dice: "crea una rama", "haz el commit", "sube la rama", "cómo nombro
  esta rama", "convención de commits", "flujo de git del equipo", "GitHub Flow".
- Se detecta el estado: se va a empezar un trabajo nuevo, o hay cambios listos para
  commitear.

### 2.2 Modos de operación

| Modo | Etapa | Se activa cuando | Protocolo |
| --- | --- | --- | --- |
| `branch` | 1 | Empieza un trabajo nuevo | §4.A |
| `commit` | 4 | Los cambios están listos y `quality-gates` pasó | §4.B |

### 2.3 NO activar cuando

| Situación | Skill correcta |
| --- | --- |
| "abre el PR" / "asigna revisor" / "mergea" | `pr-workflow` |
| "corre los checks" / "pasa los gates" | `quality-gates` |
| "revisa este código" / "resuelve los hallazgos" | `code-review` |

---

## 3. Prerrequisitos y Entradas Esperadas

### 3.1 Contrato de entrada

| Entrada | Tipo | Requerido | Origen | Default | Si falta |
| --- | --- | --- | --- | --- | --- |
| `mode` | `enum` | Sí | intención del usuario | — | Inferir de §2.2; si es ambiguo, **preguntar** |
| `purpose` | `string` | Sí (modo `branch`) | argumento del usuario | — | **PREGUNTAR — no inferir del diff** |
| `origin_prefix` | `enum` | Sí (modo `branch`) | quién ejecuta la skill | `claude/` si lo ejecuta Claude Code | usar default |
| `gate_report` | `json` | Sí (modo `commit`) | `quality-gates` | — | **Invocar `quality-gates` AHORA -> §6.1** |
| `commit_type` | `enum` | Sí (modo `commit`) | naturaleza del cambio | — | Derivar del diff; si es ambiguo, **preguntar** |

### 3.2 Precondiciones verificables

**Modo `branch`:**

```bash
git status --porcelain          # esperado: vacío. Si no -> §6.2
git rev-parse --abbrev-ref HEAD # esperado: main. Si no -> §6.3
git remote -v                   # esperado: origin presente
```

**Modo `commit`:**

```bash
git rev-parse --abbrev-ref HEAD   # esperado: NO main. Si es main -> §6.4 (BLOQUEANTE)
git diff --cached --stat          # esperado: hay algo staged, o hay cambios que stagear
cat .agent/handoff/quality-gates.json 2>/dev/null   # esperado: existe y status SUCCESS
```

### 3.3 Archivos a leer obligatoriamente

| Ruta | Cuándo | Por qué |
| --- | --- | --- |
| `references/branch-naming-policy.md` | §4.A Paso 1 | Prefijos por procedencia y reglas de formato |
| `references/commit-convention.md` | §4.B Paso 2 | Tipos permitidos y reglas verificables |

---

## 4. Protocolo de Ejecución

### §4.A — Modo `branch`

#### Paso 1 — Componer y validar el nombre

**Acción:** aplicar `references/branch-naming-policy.md` §2 y §3.

```bash
b="<prefijo>/<proposito-en-kebab-case>"
[[ "$b" =~ ^(feature|fix|chore|refactor|docs|test|claude|codex|cursor|aider)/[a-z0-9-]+$ ]] \
  && [[ ${#b} -le 60 ]] && echo "OK: $b" || echo "RECHAZADO: $b"
```

**Condición de completitud:** el nombre imprime `OK`.
**Si falla:** recomponer. -> §6.5 si el nombre ya existe.

#### Paso 2 — Actualizar `main` y crear la rama

```bash
git checkout main && git pull origin main
git checkout -b "$b"
```

**Condición de completitud:** `git rev-parse --abbrev-ref HEAD` devuelve `$b`.
**Si falla:** conflicto al sincronizar -> §6.6.

#### Paso 3 — Emitir el handoff

`STATUS: SUCCESS` con `branch_name` y `base_sha`.

---

### §4.B — Modo `commit`

#### Paso 1 — Gate de Commit (bloqueante)

**Objetivo:** garantizar que ningún commit entra con gates en rojo.

```bash
jq -r '.status, (.pillars[] | "\(.name)=\(.exit_code)")' .agent/handoff/quality-gates.json
```

**Condición de completitud:** `status == "SUCCESS"` y todo `exit_code` es `0` o `null`
(pilar OMITIDO con evidencia).

**Si falla o el archivo no existe:** **detener e invocar `quality-gates` AHORA.**
No commitear "para no perder el trabajo": usar `git stash` si hace falta. -> §6.1

#### Paso 2 — Componer y validar el mensaje

**Acción:** aplicar `references/commit-convention.md` §1 y §2.

```bash
s="<tipo>: <descripción en imperativo>"
[[ "$s" =~ ^(feat|fix|chore|refactor|docs|test|style|perf):\ [a-záéíóúñ] ]] \
  && [[ ${#s} -le 72 ]] && [[ "$s" != *. ]] && echo "OK: $s" || echo "RECHAZADO: $s"
```

**Condición de completitud:** el asunto imprime `OK`.

#### Paso 3 — Commitear

```bash
git add <rutas-explícitas>     # nunca `git add -A` a ciegas: ver §6.7
git diff --cached --check       # esperado: sin salida
git commit -m "$s" -m "<cuerpo opcional>" -m "Co-Authored-By: <Agente> <noreply@…>"
```

**Condición de completitud:** `git log -1 --format=%H` devuelve un SHA nuevo.
**Prohibido** `--no-verify`.

#### Paso 4 — Publicar la rama

**Acción irreversible hacia el exterior: requiere confirmación explícita del usuario.**

```bash
git push -u origin "$(git rev-parse --abbrev-ref HEAD)"
```

**Condición de completitud:** el push devuelve `exit_code 0` y la rama existe en `origin`.

### Diagrama de flujo

```
[branch] ──> ⟨desarrollo⟩ ──> [code-review] ──> [quality-gates]
                                                      │
                                              SUCCESS │ BLOCKED ──> vuelve a code-review
                                                      ▼
                            [commit: gate ──> mensaje ──> commit ──> push]
                                                      │
                                                      ▼
                                              [pr-workflow: create]
```

---

## 5. Contrato de Salida

### 5.1 Artefacto producido

**Formato:** rama creada, o commit + push ejecutados, más el JSON de handoff.

```json
// .agent/handoff/git-workflow.json
{
  "skill": "git-workflow",
  "version": "1.0.0",
  "mode": "commit",
  "status": "SUCCESS",
  "branch_name": "claude/agregar-campos-personalizados",
  "base_sha": "<sha>",
  "commit_sha": "<sha>",
  "commit_subject": "feat: agregar campos personalizados a contactos",
  "pushed": true,
  "gate_report_ref": ".agent/handoff/quality-gates.json"
}
```

### 5.2 Efectos laterales

| Efecto | Reversible | Requiere confirmación explícita |
| --- | --- | --- |
| Crear rama local | Sí | No |
| `git checkout main` + `pull` | Sí | No — pero exige worktree limpio (§3.2) |
| Crear commit | Sí (`git reset`) | No |
| **`git push` al remoto** | **Difícilmente** | **Sí** |

### 5.3 Estado de handoff

```
STATUS: SUCCESS | BLOCKED | PARTIAL
ARTIFACTS: .agent/handoff/git-workflow.json
BLOCKERS: <razón, o "ninguno">
NEXT: pr-workflow [modo: create] | ⟨desarrollo⟩
```

---

## 6. Manejo de Errores y Edge Cases

| # | Caso | Detección | Acción | Nunca hacer |
| --- | --- | --- | --- | --- |
| 6.1 | Sin `gate_report` verde | archivo ausente o `status != SUCCESS` | **Detener e invocar `quality-gates`** | Commitear igualmente |
| 6.2 | Worktree sucio al crear rama | `git status --porcelain` no vacío | Proponer `git stash` y confirmar con el usuario | `git checkout main` a ciegas (pierde contexto) |
| 6.3 | Ya se está en una rama de trabajo | `HEAD != main` en modo `branch` | Preguntar: ¿nueva rama desde `main`, o seguir en la actual? | Crear una rama anidada sin avisar |
| 6.4 | Intento de commit en `main` | `HEAD == main` | **DETENER.** Crear rama y mover los cambios | Commitear en `main` |
| 6.5 | El nombre de rama ya existe | `git rev-parse --verify` OK | Preguntar: ¿reutilizar o renombrar? | Sobrescribir |
| 6.6 | Conflicto al sincronizar con `main` | `git pull` falla | Reportar los archivos en conflicto y detener | Resolver conflictos sin revisión humana |
| 6.7 | Archivos ajenos en el worktree | `git status` con archivos no relacionados | Stagear **rutas explícitas**; listar lo excluido | `git add -A` arrastrando cambios ajenos |
| 6.8 | Push rechazado (non-fast-forward) | `git push` falla | Reportar; proponer `git pull --rebase` y confirmar | `--force` sin autorización explícita |
| 6.9 | Push a `main` solicitado | destino `main` | **DETENER.** `main` solo se alcanza vía PR | Ejecutarlo |

### 6.10 Regla de degradación

Si el protocolo no puede completarse: entregar lo hecho (rama creada, commit local
sin push), declarar lo omitido y emitir `STATUS: PARTIAL`.

---

## 7. Reglas Innegociables

1. **Evidencia > afirmación.** Todo estado reportado procede de una salida de comando,
   una lectura de archivo o un grep. Cero inferencias presentadas como hechos.
2. **Cero invención.** Comandos, rutas y nombres: si no se observaron, no se escriben.
   Ante duda, preguntar.
3. **Sin efectos irreversibles sin confirmación** (push, publicar review, merge, borrar).
4. **Idioma de la salida = idioma del usuario.**
5. **Responsabilidad humana no delegable** sobre lo que llega a `main`, aunque el
   cambio lo haya generado una herramienta de AI. **Todo commit generado por un
   agente requiere revisión humana antes del merge.**

### Reglas específicas de esta skill

6. **Gate de Commit:** prohibido `git commit` sin un `gate_report` verde de esta misma
   sesión. Prohibido `--no-verify`.
7. **`main` es intocable localmente:** nunca commit ni push directo.
8. **Procedencia veraz:** un agente nunca usa un prefijo de trabajo manual.

---

## 8. Recursos

| Ruta | Tipo | Cuándo cargar |
| --- | --- | --- |
| `references/branch-naming-policy.md` | Conocimiento | §4.A Paso 1 |
| `references/commit-convention.md` | Conocimiento | §4.B Paso 2 |
