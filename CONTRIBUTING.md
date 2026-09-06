# Guía de Contribución — `code-agent-skills`

Este repositorio publica skills para agentes de código. Todas cumplen **un único
estándar canónico**. El scaffold vive en [`_template/SKILL.md`](_template/SKILL.md)
y la CI lo hace cumplir.

---

## 1. Estructura de una skill

```
<skill-name>/
├── SKILL.md          # ÚNICO archivo obligatorio. Entry point. <= 500 líneas.
├── references/       # ENTRADA de razonamiento — el agente LEE. Nunca se emite.
├── assets/           # SALIDA rellenable — el agente COPIA y RELLENA.
└── scripts/          # (opcional) Ejecutables deterministas. El agente EJECUTA.
```

### Regla de discriminación `references/` vs `assets/`

> **¿El contenido de este archivo aparecerá, total o parcialmente, en el artefacto
> final entregado al usuario?**
>
> **Sí -> `assets/`. No -> `references/`.**

| Ejemplo | Test | Carpeta |
| --- | --- | --- |
| Checklist de inspección | Guía el razonamiento, no se emite | `references/` |
| Plantilla de descripción de PR | Se rellena y se publica como cuerpo del PR | `assets/` |
| Matriz de descubrimiento de comandos | Se consulta para decidir | `references/` |
| Plantilla de informe de review | Se rellena y se publica en GitHub | `assets/` |

`scripts/` es para código que el agente **ejecuta sin interpretar**. Si el agente
necesita leer y razonar sobre el contenido, no es un script: es una `reference`.

---

## 2. Nombres e idioma

| Elemento | Idioma | Formato | Razón |
| --- | --- | --- | --- |
| Carpetas y archivos | **Inglés** | `kebab-case` | Son API pública: rutas de CI, `npx skills add --skill <name>`, greps |
| `name:` del frontmatter | **Inglés** | `kebab-case`, idéntico al nombre de carpeta | Identificador del router |
| `description:` del frontmatter | **Inglés + triggers literales en español** | prosa | Ver §2.1 |
| Cuerpo de `SKILL.md`, `references/`, `assets/` | **Español** | prosa | Idioma operativo del equipo |
| Salida al usuario | **Idioma del usuario** | — | Regla innegociable nº 4 |

### 2.1 Por qué la `description` es bilingüe

`description` es **lo único que ve el router en el momento de decidir si activa la
skill**. La prosa en inglés maximiza el recall del matching semántico; las frases
disparadoras literales en español garantizan el match exacto cuando el usuario
escribe en su idioma. Un trigger que solo existe en `metadata.triggers`
**no dispara nada**.

### 2.2 Sufijos canónicos

| Sufijo | Uso | Carpeta |
| --- | --- | --- |
| `-template.md` | Esqueleto a rellenar y emitir | `assets/` |
| `-checklist.md` | Lista de inspección | `references/` |
| `-policy.md` | Reglas normativas no negociables | `references/` |
| `-matrix.md` | Tablas de decisión o mapeo | `references/` |
| `-examples.md` | Ejemplos few-shot | `references/` |
| `-commands.md` | Comandos exactos, copiables | `references/` |

Prohibido: nombres genéricos (`checklist.md`, `template.md`, `notes.md`) y nombres
en español (`plantilla-pr.md`).

---

## 3. Frontmatter

El loader de skills consume de forma fiable **`name`**, **`description`** y
**`allowed-tools`**. Cualquier otra clave va anidada bajo **`metadata:`**, para no
depender del comportamiento del parser ante claves desconocidas.

```yaml
---
name: skill-name
description: >-
  <EN prosa> ... Trigger phrases (ES): "...", "...". Does NOT: ... (use `otra-skill`).
allowed-tools: Read, Grep, Glob, Bash
metadata:
  version: 1.0.0          # SemVer
  owner: platform-engineering
  stability: stable | beta | deprecated
  pipeline-stage: "N"
  modes: [...]
  anti-triggers: [...]
  requires: [...]         # skills que deben ejecutarse ANTES
  provides: [...]         # artefacto/estado que deja al siguiente
  consumes: [...]         # artefacto/estado que espera del anterior
---
```

### 3.1 `allowed-tools`: superficie mínima suficiente

Declarar solo lo que la skill necesita. Una skill de auditoría *read-only* **no**
lleva `Edit` ni `Write`: la ausencia de la herramienta es una garantía más fuerte
que una instrucción en prosa.

### 3.2 SemVer

| Incremento | Cuándo |
| --- | --- |
| **MAJOR** | Cambia el contrato de salida (§5) o el de entrada (§3.1) |
| **MINOR** | Nueva capacidad, nuevo modo, nueva `reference` |
| **PATCH** | Redacción, ejemplos, correcciones sin efecto en los contratos |

Si cambias el `provides` de una skill, sube MAJOR **y** actualiza el `consumes` de
todas las que dependen de ella.

---

## 4. Secciones obligatorias de `SKILL.md`

Copiar [`_template/SKILL.md`](_template/SKILL.md) y rellenarlo. La CI falla si falta
alguna de estas:

| § | Sección | Por qué es obligatoria |
| --- | --- | --- |
| 1.1 | Qué hace | — |
| **1.2** | **Qué NO hace** | Mecanismo primario de prevención de solapamiento |
| 1.3 | Posición en el pipeline | Hace explícito el orden de invocación |
| 2.1 | Activar cuando | — |
| **3.1** | **Contrato de entrada** | Define qué preguntar en vez de inventar |
| 4 | Protocolo de Ejecución | Flujo determinista con condición de completitud por paso |
| **5.1** | **Contrato de salida** | Estructura exacta del artefacto |
| **5.3** | **Estado de handoff** | Traspaso auditable entre skills |
| **6** | **Manejo de errores** | Sin esto, el agente improvisa ante el primer fallo |
| **7** | **Reglas Innegociables** | Las 5 reglas base son idénticas en todas las skills |

Presupuesto: `SKILL.md` **<= 500 líneas**. Lo que exceda migra a `references/`.

---

## 5. Handoff entre skills

Toda skill emite al terminar, literalmente:

```
STATUS: SUCCESS | BLOCKED | PARTIAL
ARTIFACTS: <rutas o IDs producidos>
BLOCKERS: <lista o "ninguno">
NEXT: <skill-siguiente> | <acción humana requerida>
```

El traspaso **no puede depender de que sobreviva el contexto conversacional**. Los
artefactos estructurados se materializan en `.agent/handoff/<skill>.json`
(gitignored) para que el estado sea auditable en sesiones largas o multi-agente.

`provides` de una skill debe coincidir con `consumes` de la siguiente. La CI lo verifica.

---

## 6. Reglas Innegociables (idénticas en las 5 skills)

Copiar textualmente en §7 de cada `SKILL.md`:

1. **Evidencia > afirmación.** Todo estado reportado procede de una salida de comando,
   una lectura de archivo o un grep. Cero inferencias presentadas como hechos.
2. **Cero invención.** Comandos, usuarios, rutas, cifras y hallazgos: si no se
   observaron, no se escriben. Ante duda, preguntar.
3. **Sin efectos irreversibles sin confirmación** (push, publicar review, merge, borrar).
4. **Idioma de la salida = idioma del usuario.**
5. **Responsabilidad humana no delegable** sobre lo que llega a `main`, aunque el
   cambio lo haya generado una herramienta de AI.

---

## 7. Antipatrones prohibidos

| Antipatrón | Por qué | En su lugar |
| --- | --- | --- |
| Duplicar conocimiento entre skills | Diverge en el primer cambio de política | Una fuente de verdad + referencia cruzada marcada |
| Reimplementar lo que hace otra skill | Versión degradada y desincronizada | Invocar la skill propietaria |
| Prosa sin comandos ejecutables | El agente improvisa la sintaxis | Comandos exactos en `references/*-commands.md` |
| Exigir un dato sin declarar su fuente | El agente lo inventa | Cadena de resolución + "preguntar y detener" |
| Cláusulas de omisión sin evidencia | Camino de mínimo esfuerzo: declarar ausente lo difícil | Exigir el comando de búsqueda y su salida |
| Reglas auto-anulantes | Neutralizan la política que acaban de definir | Regla + consecuencia declarada |
| Comandos de un stack en una skill agnóstica | Rompe la portabilidad prometida | Descubrimiento dinámico, placeholders `<comando-x>` |
| LaTeX en Markdown (`$\rightarrow$`) | Se renderiza literal, gasta tokens | `->` |

---

## 8. Checklist de PR para una skill nueva o migrada

- [ ] Copiada de `_template/SKILL.md`; todas las secciones obligatorias presentes.
- [ ] `metadata.version` en SemVer; `requires` / `provides` / `consumes` coherentes.
- [ ] `allowed-tools` con la superficie mínima suficiente.
- [ ] `description` con prosa EN + frases disparadoras literales ES + cláusula "Does NOT".
- [ ] §1.2 "Qué NO hace" nombra explícitamente la skill propietaria de cada exclusión.
- [ ] Archivos en `references/` vs `assets/` según el test de §1; sufijos de §2.2.
- [ ] Cero duplicación con otra skill; las referencias cruzadas están marcadas.
- [ ] Todo comando externo aparece con su sintaxis exacta, no descrito en prosa.
- [ ] `SKILL.md` <= 500 líneas.
- [ ] `scripts/validate-skills.sh` pasa en verde.
