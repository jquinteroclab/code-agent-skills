---
name: skill-name
description: >-
  <EN> What this skill does + WHEN to use it, in 1-3 sentences. Then list the
  verbatim phrases a user would say to trigger it, in the team's working language.
  If a sibling skill overlaps, state explicitly what this skill does NOT do.
  Trigger phrases (ES): "<frase literal>", "<frase literal>".
  Does NOT: <responsabilidad ajena> (use `<otra-skill>`).
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: 1.0.0
  owner: platform-engineering
  stability: stable
  pipeline-stage: "N"
  modes:
    - <modo>            # si la skill se invoca en más de un momento del pipeline
  anti-triggers:
    - "<frase> -> usar <otra-skill>"
  requires:
    - <skill>@^1.0.0
  provides:
    - <artefacto/estado declarado en 5.3>
  consumes:
    - <artefacto/estado producido por la skill anterior>
---

# <Título Legible>

> **Una frase:** qué problema resuelve y para quién.

---

## 1. Contexto y Propósito

### 1.1 Qué hace

- <capacidad 1, verbo en infinitivo>
- <capacidad 2>

### 1.2 Qué NO hace

> Sección **obligatoria**. Es el mecanismo primario de prevención de solapamiento.

| Fuera de alcance | Skill responsable |
| --- | --- |
| <responsabilidad ajena> | `<otra-skill>` |

### 1.3 Posición en el pipeline

`<skill-anterior>` -> **`<esta-skill>`** -> `<skill-siguiente>`

---

## 2. Activación

### 2.1 Activar cuando

- El usuario dice: "<frase literal>", "<frase literal>".
- Se detecta el estado: <condición observable del repo o del entorno>.

### 2.2 Modos de operación

> Omitir esta subsección si la skill tiene un único modo.

| Modo | Etapa | Se activa cuando | Protocolo |
| --- | --- | --- | --- |
| `<modo-a>` | N | <condición> | §4.A |
| `<modo-b>` | M | <condición> | §4.B |

### 2.3 NO activar cuando

| Situación | Skill correcta |
| --- | --- |
| <situación> | `<otra-skill>` |

---

## 3. Prerrequisitos y Entradas Esperadas

### 3.1 Contrato de entrada

| Entrada | Tipo | Requerido | Origen | Default | Si falta |
| --- | --- | --- | --- | --- | --- |
| `<nombre>` | `string` | Sí | argumento del usuario | — | **PREGUNTAR — no inferir** |
| `<nombre>` | `path` | No | `<comando>` | `<valor>` | usar default |

### 3.2 Precondiciones verificables

Ejecutar y confirmar **antes** de entrar al Protocolo. Si alguna falla, ir a §6.

```bash
<comando de verificación>   # esperado: <condición observable>
```

### 3.3 Archivos a leer obligatoriamente

| Ruta | Cuándo | Por qué |
| --- | --- | --- |
| `references/<archivo>.md` | Paso N | <razón> |

---

## 4. Protocolo de Ejecución

> **Determinismo:** ejecutar los pasos EN ORDEN. No saltar pasos. No paralelizar salvo
> indicación explícita. Cada paso declara su **condición de completitud**; si no se
> cumple, ir a §6 antes de avanzar.

### Paso 1 — <Acción en imperativo>

**Objetivo:** <una frase>

**Acción:**

```bash
<comando exacto, o placeholder <descrito> cuando dependa del proyecto>
```

**Condición de completitud:** <hecho observable, no una impresión>

**Si falla:** -> §6.<caso>

### Paso 2 — <Acción en imperativo>

…

### Diagrama de flujo

```
[Paso 1] ──OK──> [Paso 2] ──OK──> [Paso 3] ──> SALIDA (§5)
    │                │
   FALLO            FALLO
    ▼                ▼
  §6.1             §6.2
```

---

## 5. Contrato de Salida

### 5.1 Artefacto producido

**Formato:** <Markdown | comando ejecutado | commit | archivo>
**Plantilla:** `assets/<archivo>-template.md` — **rellenar sin alterar el esqueleto**

<bloque con la estructura EXACTA de la salida, incluidos encabezados y tablas>

### 5.2 Efectos laterales

| Efecto | Reversible | Requiere confirmación explícita |
| --- | --- | --- |
| <ej. push a remoto> | No | **Sí** |

### 5.3 Estado de handoff

Al terminar, emitir **siempre** este bloque, literalmente:

```
STATUS: SUCCESS | BLOCKED | PARTIAL
ARTIFACTS: <rutas o IDs producidos>
BLOCKERS: <lista o "ninguno">
NEXT: <skill-siguiente> | <acción humana requerida>
```

---

## 6. Manejo de Errores y Edge Cases

| # | Caso | Detección | Acción | Nunca hacer |
| --- | --- | --- | --- | --- |
| 6.1 | Falta una entrada requerida | §3.1 sin valor | **Preguntar al usuario y detener** | Inventar el valor |
| 6.2 | Gate en rojo | `exit_code != 0` | Reportar salida literal; `STATUS: BLOCKED` | Declarar verde sin ejecutar |
| 6.3 | Diff excede el presupuesto | > 50 archivos o > 3000 líneas | Priorizar por riesgo, declarar cobertura parcial y listar lo NO revisado | Fingir revisión completa |
| 6.4 | Herramienta o comando no disponible | comando no encontrado | Declarar NO EJECUTABLE con evidencia | Marcarlo como "omitido / OK" |
| 6.5 | Acción irreversible o externa | efecto listado en §5.2 | Confirmar con el usuario antes de ejecutar | Ejecutar sin confirmación |

### 6.6 Regla de degradación

Si el protocolo no puede completarse: **entregar lo completado, declarar explícitamente
lo omitido y por qué, y emitir `STATUS: PARTIAL`.** Nunca fabricar el tramo faltante.

---

## 7. Reglas Innegociables

1. **Evidencia > afirmación.** Todo estado reportado procede de una salida de comando,
   una lectura de archivo o un grep. Cero inferencias presentadas como hechos.
2. **Cero invención.** Comandos, usuarios, rutas, cifras y hallazgos: si no se
   observaron, no se escriben. Ante duda, preguntar.
3. **Sin efectos irreversibles sin confirmación** (push, publicar review, merge, borrar).
4. **Idioma de la salida = idioma del usuario.**
5. **Responsabilidad humana no delegable** sobre lo que llega a `main`, aunque el
   cambio lo haya generado una herramienta de AI.

---

## 8. Recursos

| Ruta | Tipo | Cuándo cargar |
| --- | --- | --- |
| `references/<x>.md` | Conocimiento (se lee) | Paso N |
| `assets/<y>-template.md` | Plantilla de salida (se rellena) | Paso M (§5) |
