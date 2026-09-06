# Gate Report

**Repositorio:** `<owner/repo>` · **Rama:** `<branch>` · **Base:** `<base_ref>`
**HEAD:** `<sha>` · **Alcance:** `full | changed-files` · **Fecha:** `<ISO-8601>`

## Resultado por pilar

| # | Pilar | Estado | Comando ejecutado | exit_code | Evidencia |
| --- | --- | --- | --- | --- | --- |
| 1 | Formato y Whitespace | PASS \| FAIL \| OMITIDO | `<comando>` | `0` | `<salida literal resumida>` |
| 2 | Linter y Tipos | | `<comando>` | | |
| 3 | Pruebas | | `<comando>` | | `<X suites / Y tests>` |
| 4 | Build | | `<comando>` | | |

> `OMITIDO` exige la evidencia de ausencia (comando de búsqueda + salida vacía).
> Un pilar que existe y falla es `FAIL`, nunca `OMITIDO`.

## Supresores introducidos en el diff

| Archivo:línea | Supresor | Justificación |
| --- | --- | --- |
| `<ruta:N>` | `<directiva>` | `<razón>` — o "ninguno" |

## Fallos y correcciones aplicadas

| Pilar | Causa raíz | Corrección | Reejecución |
| --- | --- | --- | --- |
| `<n>` | `<descripción>` | `<qué se cambió>` | `exit_code 0` |

---

```
STATUS: SUCCESS | BLOCKED | PARTIAL
ARTIFACTS: .agent/handoff/quality-gates.json
BLOCKERS: <pilar + salida literal, o "ninguno">
NEXT: git-workflow [modo: commit] | code-review [modo: remediation]
```
