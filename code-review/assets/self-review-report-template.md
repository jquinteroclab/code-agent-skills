# Auto-revisión — `<rama>` <!-- modo: pre-flight | remediation -->

**Alcance:** `<N>` archivos, `<M>` líneas · **Base:** `<base_ref>` · **HEAD:** `<sha>`
**Issue:** `<ISSUE-ID>` — <criterio de cierre en una frase, o "sin issue asociada">

<Resumen de 2-4 frases: qué hace el cambio, si cumple el criterio del issue, hallazgos
principales y qué queda bloqueante.>

---

## 🐞 Bugs

### 1. <título corto y claro> — Alto | Medio | Bajo

`archivo:línea` — <descripción precisa, por qué es un bug, impacto y arreglo aplicado.>

**Estado:** CORREGIDO | PENDIENTE | RECHAZADO (<motivo>)

---

## 🔒 Seguridad

- **<título>** — <severidad>. `archivo:línea` — <descripción>. **Estado:** <…>

## 🦨 Code smells

| # | Dónde | Qué | Estado |
| --- | --- | --- | --- |
| 1 | `archivo:línea` | <descripción breve> | CORREGIDO |

## 🧪 Cobertura

| Archivo | % Stmts | % Branch | Líneas sin cubrir |
| --- | --- | --- | --- |
| `<ruta>` | | | |

<Relación con el criterio de cierre del issue.>

## ♻️ Duplicación

- <bloques o patrones duplicados + refactor aplicado o propuesto>

---

## Ciclo RED -> GREEN <!-- solo en modo remediation -->

| # | Hallazgo | Causa raíz | Corrección | Prueba | RED | GREEN |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | <título> | <causa> | <qué cambió> | `<ruta::test>` | `exit 1` | `exit 0` |

## Hallazgos rechazados

| # | Hallazgo | Motivo documentado |
| --- | --- | --- |

---

## Cobertura de la revisión

**Archivos revisados:** `<N>` de `<M>`.
**No revisados:** `<lista explícita>` — <razón: presupuesto de diff, generados, etc.>

---

```
STATUS: SUCCESS | BLOCKED | PARTIAL
ARTIFACTS: .agent/handoff/code-review.json
BLOCKERS: <lista de hallazgos bloqueantes, o "ninguno">
NEXT: quality-gates | git-workflow [modo: commit]
```
