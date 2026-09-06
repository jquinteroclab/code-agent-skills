---
name: code-review
description: >-
  Self-audits the LOCAL working tree before pushing: bugs, security, code smells,
  coverage, duplication and contracts; then fixes what it finds through a mandatory
  RED-GREEN test cycle. Runs entirely offline against the local diff and is the only
  review skill that MODIFIES code.
  Trigger phrases (ES): "revisa mi código", "audita el diff antes del PR",
  "resuelve los hallazgos de la revisión", "arregla lo que encontró el review",
  "checklist de calidad".
  Does NOT touch GitHub, does NOT publish reviews, does NOT review other people's
  remote PRs (use `pr-review`), does NOT run the quality suite (use `quality-gates`).
allowed-tools: Read, Grep, Glob, Edit, Write, Bash
metadata:
  version: 1.0.0
  owner: platform-engineering
  stability: stable
  pipeline-stage: "2,7"
  modes:
    - pre-flight
    - remediation
  anti-triggers:
    - "revisa el PR #N -> usar pr-review"
    - "publica el review en GitHub -> usar pr-review"
    - "corre los tests / pasa los gates -> usar quality-gates"
    - "haz el commit -> usar git-workflow"
  requires:
    - quality-gates@^1.0.0
  provides:
    - findings_resolved
    - self_review_report
  consumes:
    - branch_name
    - findings          # solo en modo `remediation`, procedente de pr-review
---

# Code Review (auto-auditoría local)

> **Una frase:** el autor audita su propio diff antes de que exista un PR, y corrige
> cada hallazgo con una prueba que primero se vio fallar.

---

## 1. Contexto y Propósito

### 1.1 Qué hace

- Inspeccionar el diff **local** contra el checklist de calidad.
- Clasificar hallazgos por categoría y severidad, anclados a `archivo:línea`.
- **Corregir** los hallazgos mediante el ciclo RED -> GREEN.
- Invocar `quality-gates` para la verificación integral.
- Emitir un reporte de auto-revisión con el estado de cada hallazgo.

### 1.2 Qué NO hace

| Fuera de alcance | Skill responsable |
| --- | --- |
| Leer, comentar o aprobar PRs remotos | `pr-review` |
| Publicar cualquier cosa en GitHub | `pr-review` |
| Descubrir y ejecutar linter, tipos, pruebas o build | `quality-gates` |
| Crear ramas, commits o hacer push | `git-workflow` |
| Crear el PR o asignar revisores | `pr-workflow` |

### 1.3 Posición en el pipeline

**Etapa 2:** `⟨desarrollo⟩` -> **`code-review [pre-flight]`** -> `quality-gates`
**Etapa 7:** `pr-review (request-changes)` -> **`code-review [remediation]`** -> `quality-gates` -> `git-workflow` -> `pr-review`

---

## 2. Activación

### 2.1 Activar cuando

- El usuario dice: "revisa mi código", "audita el diff antes del PR", "resuelve los
  hallazgos", "arregla lo que encontró el review", "checklist de calidad".
- Se detecta el estado: una funcionalidad, bugfix o refactor está terminado y aún no
  se ha commiteado o pusheado.

### 2.2 Modos de operación

| Modo | Etapa | Se activa cuando | Protocolo |
| --- | --- | --- | --- |
| `pre-flight` | 2 | Antes de commitear/abrir PR: auditoría preventiva | §4.A |
| `remediation` | 7 | Hay hallazgos de una revisión previa que corregir | §4.B |

### 2.3 NO activar cuando

| Situación | Skill correcta |
| --- | --- |
| "revisa el PR #12" / "analiza este diff de PR" | `pr-review` |
| "sube el review a GitHub" / "aprueba el PR" | `pr-review` |
| "corre los tests" / "pasa los gates" | `quality-gates` |
| "haz el commit" / "crea la rama" | `git-workflow` |

---

## 3. Prerrequisitos y Entradas Esperadas

### 3.1 Contrato de entrada

| Entrada | Tipo | Requerido | Origen | Default | Si falta |
| --- | --- | --- | --- | --- | --- |
| `mode` | `enum` | Sí | intención del usuario | `pre-flight` | usar default |
| `diff_scope` | `string` | No | argumento del usuario | `origin/main...HEAD`, o `git diff HEAD` si no hay remoto | usar default |
| `issue_id` | `string` | No | argumento / nombre de rama | — | Revisar sin criterio de cierre y **declararlo** -> §6.3 |
| `findings` | `array` | Sí (modo `remediation`) | `pr-review` / usuario | — | **PREGUNTAR — no inventar hallazgos** |

### 3.2 Precondiciones verificables

```bash
git rev-parse --show-toplevel
git diff --stat <diff_scope>          # esperado: hay cambios que revisar
git diff --numstat <diff_scope> | wc -l   # tamaño del diff -> §3.4
```

### 3.3 Archivos a leer obligatoriamente

| Ruta | Cuándo | Por qué |
| --- | --- | --- |
| `references/quality-checklist.md` | §4.A Paso 3 | Categorías, anclaje de evidencia y regla de severidad |
| `references/remediation-protocol.md` | §4.B | Ciclo RED -> GREEN |
| `assets/self-review-report-template.md` | §5 | Estructura exacta del reporte |

### 3.4 Presupuesto de diff

Si el diff supera **50 archivos** o **3.000 líneas**:

1. Priorizar por riesgo: **seguridad/auth > lógica de dominio > I/O > tests > docs/config**.
2. Revisar hasta agotar el presupuesto.
3. **Declarar explícitamente los archivos NO revisados** en el reporte.
4. Emitir `STATUS: PARTIAL`.

> **PROHIBIDO** presentar una cobertura parcial como completa. Es la forma más común y
> más dañina de alucinación en revisión de código.

---

## 4. Protocolo de Ejecución

### §4.A — Modo `pre-flight`

#### Paso 1 — Delimitar el alcance

```bash
git diff --stat <diff_scope>
git diff --name-only <diff_scope>
```

**Condición de completitud:** lista de archivos tocados y tamaño del diff conocidos.
Si excede el presupuesto -> §3.4.

#### Paso 2 — Leer el criterio de cierre

Leer el issue asociado: objetivo, criterios de aceptación, nivel de prueba exigido
(¿pide integración real o basta con dobles?).

**Si no hay acceso al gestor:** pedir el contenido al usuario. Si no está disponible,
continuar **declarando en el reporte que se revisó sin criterio de cierre**. -> §6.3

#### Paso 3 — Inspeccionar contra el checklist

**Acción:** recorrer `references/quality-checklist.md` sobre los archivos tocados y el
contexto mínimo necesario del código existente.

**Condición de completitud:** cada hallazgo está anclado a `archivo:línea` y tiene
severidad asignada.

> **Solo hallazgos reales.** Un ítem del checklist que se cumple no se reporta.
> Un hallazgo que no se puede anclar a una línea concreta **no se incluye**.

#### Paso 4 — Corregir

Aplicar `references/remediation-protocol.md`: cada corrección de un bug pasa por
**RED -> GREEN**, con ambos `exit_code` observados.

#### Paso 5 — Verificación integral

**Invocar `quality-gates`.** No reimplementar el pipeline aquí.

**Condición de completitud:** `gate_report` con `status: SUCCESS`.
**Si `BLOCKED`:** volver al Paso 4.

#### Paso 6 — Emitir el reporte

Rellenar `assets/self-review-report-template.md`.

---

### §4.B — Modo `remediation`

Aplicar `references/remediation-protocol.md` completo, hallazgo por hallazgo:

1. **Triage y causa raíz** — reproducir antes de corregir.
2. **Diseño defensivo** — guardas fail-closed al inicio de los handlers.
3. **RED -> GREEN** — prueba que falla primero, luego código hasta el verde.
4. **`quality-gates`** — verificación integral.
5. **Documentar** — causa, corrección, prueba, evidencia.

Un hallazgo puede **rechazarse motivadamente** (ver el protocolo, sección final), pero
nunca ignorarse en silencio.

**Condición de completitud:** todo hallazgo de entrada está en estado `CORREGIDO` o
`RECHAZADO` con motivo documentado. Ninguno queda en `PENDIENTE` sin declararlo.

### Diagrama de flujo

```
[alcance] ──> [criterio de cierre] ──> [checklist] ──> [hallazgos anclados]
    │                                                          │
 > presupuesto                                                 ▼
    ▼                                              [RED --> GREEN por hallazgo]
 PARTIAL + lista de                                            │
 archivos no revisados                                         ▼
                                                       [quality-gates]
                                                  BLOCKED │ SUCCESS
                                                     ◄────┤    ▼
                                                          [reporte + handoff]
```

---

## 5. Contrato de Salida

### 5.1 Artefacto producido

**Formato:** Markdown + código corregido en el worktree + JSON de handoff.
**Plantilla:** `assets/self-review-report-template.md` — **rellenar sin alterar el esqueleto.**

La estructura es deliberadamente paralela a la de `pr-review/assets/review-report-template.md`
para que las rondas de revisión sean comparables entre sí.

```json
// .agent/handoff/code-review.json
{
  "skill": "code-review",
  "version": "1.0.0",
  "mode": "pre-flight",
  "status": "SUCCESS",
  "diff_scope": "origin/main...HEAD",
  "files_reviewed": 12,
  "files_total": 12,
  "files_skipped": [],
  "issue_id": "PROJ-157",
  "findings": [
    {
      "id": 1, "category": "bug", "severity": "alto", "blocking": true,
      "location": "src/x.ts:42", "title": "<título>",
      "state": "CORREGIDO",
      "test": "tests/x.spec.ts::no acepta estado inválido",
      "red_exit_code": 1, "green_exit_code": 0
    }
  ],
  "gate_report_ref": ".agent/handoff/quality-gates.json"
}
```

### 5.2 Efectos laterales

| Efecto | Reversible | Requiere confirmación explícita |
| --- | --- | --- |
| Modificar archivos del worktree | Sí (`git checkout`) | No |
| Crear archivos de prueba | Sí | No |
| Escribir `.agent/handoff/code-review.json` | Sí | No |

Esta skill **no** hace commit, push, ni ninguna operación de red saliente.

### 5.3 Estado de handoff

```
STATUS: SUCCESS | BLOCKED | PARTIAL
ARTIFACTS: .agent/handoff/code-review.json
BLOCKERS: <hallazgos bloqueantes no resueltos, o "ninguno">
NEXT: quality-gates | git-workflow [modo: commit]
```

| STATUS | Cuándo |
| --- | --- |
| `SUCCESS` | Todos los hallazgos CORREGIDOS o RECHAZADOS con motivo; gates verdes |
| `BLOCKED` | Hallazgo bloqueante sin resolver, o gates en rojo |
| `PARTIAL` | Diff excedió el presupuesto: hay archivos declarados como no revisados |

---

## 6. Manejo de Errores y Edge Cases

| # | Caso | Detección | Acción | Nunca hacer |
| --- | --- | --- | --- | --- |
| 6.1 | Diff excede el presupuesto | > 50 archivos o > 3000 líneas | Priorizar por riesgo, listar lo NO revisado, `STATUS: PARTIAL` | Presentar cobertura parcial como completa |
| 6.2 | Diff vacío | `git diff --stat` sin salida | Informar que no hay nada que revisar y detener | Inventar hallazgos para justificar la ejecución |
| 6.3 | Sin issue asociada | No se resuelve `issue_id` | Revisar igualmente y **declarar** que no hubo criterio de cierre | Suponer los criterios de aceptación |
| 6.4 | Hallazgo no reproducible | Paso 1 del protocolo falla | Marcar PENDIENTE con la evidencia de la investigación | Corregir una causa supuesta |
| 6.5 | La prueba RED no llega a GREEN | 3 iteraciones sin progreso | `STATUS: BLOCKED`, reportar lo intentado | Ajustar la prueba para que pase |
| 6.6 | La prueba RED no falla al escribirla | `exit_code 0` en fase RED | La prueba no demuestra el bug: rehacerla | Aceptarla como válida |
| 6.7 | Gates en rojo tras corregir | `gate_report` BLOCKED | Volver al ciclo de corrección | Commitear igualmente |
| 6.8 | Archivos generados o vendored en el diff | rutas `dist/`, `vendor/`, `*.lock` | Excluirlos y declararlo | Revisarlos línea a línea gastando el presupuesto |
| 6.9 | Se pide revisar un PR remoto | número de PR o URL de GitHub | **Detener e invocar `pr-review`** | Ejecutar comandos `gh` desde esta skill |

### 6.10 Regla de degradación

Si el protocolo no puede completarse: entregar los hallazgos resueltos, declarar
explícitamente los pendientes y los archivos no revisados, y emitir `STATUS: PARTIAL`.
Nunca fabricar el tramo faltante.

---

## 7. Reglas Innegociables

1. **Evidencia > afirmación.** Todo hallazgo se ancla a `archivo:línea`. Todo estado
   procede de una salida de comando o una lectura de archivo.
2. **Cero invención.** Un hallazgo que no se puede anclar no se escribe. Ante duda,
   preguntar. **No inventar hallazgos para justificar la revisión.**
3. **Sin efectos irreversibles sin confirmación** (push, publicar review, merge, borrar).
4. **Idioma de la salida = idioma del usuario.**
5. **Responsabilidad humana no delegable** sobre lo que llega a `main`, aunque el
   cambio lo haya generado una herramienta de AI.

### Reglas específicas de esta skill

6. **Cero suposiciones:** todo comportamiento corregido está respaldado por una prueba
   automatizada **que se vio fallar antes** (fase RED con `exit_code` observado).
7. **Frontera con `pr-review`:** esta skill opera sobre el working tree local y es la
   única de las dos que **modifica** código. **Nunca** ejecutar `gh pr review`,
   `gh pr comment` ni ningún comando que publique en GitHub. Si el usuario pide revisar
   un PR remoto por número o URL, **detener e invocar `pr-review`**.
8. **Diff limpio:** sin archivos temporales, código comentado innecesario ni trailing
   whitespace.
9. **Cobertura declarada:** el reporte siempre dice cuántos archivos se revisaron de
   cuántos, y nombra los omitidos.

---

## 8. Recursos

| Ruta | Tipo | Cuándo cargar |
| --- | --- | --- |
| `references/quality-checklist.md` | Conocimiento (fuente única de verdad) | §4.A Paso 3 |
| `references/remediation-protocol.md` | Conocimiento | §4.A Paso 4, §4.B |
| `assets/self-review-report-template.md` | Plantilla de salida | §4.A Paso 6, §5 |
