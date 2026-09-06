# Política de Nombres de Rama

## 1. Estructura de ramas

- **`main`** es la única rama principal. Todo lo que está en `main` debe estar listo
  para desplegar.
- Las ramas de trabajo se crean desde `main`, viven poco y se eliminan tras el merge.
- **Prohibido** `develop`, `release/*` y `hotfix/*`.

---

## 2. Prefijo por procedencia

El prefijo declara **quién produjo el cambio**. Es metadato de trazabilidad, no
decoración: permite auditar qué proporción de `main` proviene de agentes.

| Origen | Prefijo permitido | Ejemplo |
| --- | --- | --- |
| Trabajo manual | `feature/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/` | `feature/crear-contacto` |
| Claude Code | `claude/` | `claude/agregar-campos-personalizados` |
| Codex | `codex/` | `codex/fix-validacion-email` |
| Otras herramientas AI | Prefijo de la herramienta | `cursor/…`, `aider/…` |

> Un agente **nunca** usa un prefijo de trabajo manual. Si el cambio lo genera Claude
> Code, la rama es `claude/…` aunque el usuario haya pedido "una rama feature".
> Falsear la procedencia rompe la auditoría de responsabilidad.

---

## 3. Reglas de formato

| Regla | Verificación |
| --- | --- |
| Solo minúsculas y guiones `-` | `[[ "$b" =~ ^[a-z0-9]+/[a-z0-9-]+$ ]]` |
| Corto y descriptivo (<= 40 caracteres tras el prefijo) | `[[ ${#b} -le 60 ]]` |
| Una rama = un solo propósito | Revisión humana |
| Prefijo de la tabla §2 | `[[ "$b" =~ ^(feature\|fix\|chore\|refactor\|docs\|test\|claude\|codex\|cursor\|aider)/ ]]` |

Comprobación completa antes de crear la rama:

```bash
b="<nombre-propuesto>"
[[ "$b" =~ ^(feature|fix|chore|refactor|docs|test|claude|codex|cursor|aider)/[a-z0-9-]+$ ]] \
  && [[ ${#b} -le 60 ]] && echo "OK: $b" || echo "RECHAZADO: $b"
```

---

## 4. Reglas de `main`

Localmente aplica **una sola regla**:

> **Nunca `git push origin main`. Nunca commitear estando en `main`.**

Las reglas de merge y protección de `main` (checks de CI, aprobaciones requeridas,
revisor y assignee obligatorios, estrategia de merge, borrado de rama) son propiedad
de **`pr-workflow` §5**, que es su fuente única de verdad. No se duplican aquí.

---

## 5. Buenas prácticas

- Las ramas viven poco: idealmente menos de 2–3 días.
- Commits pequeños y frecuentes.
- Si una rama se queda vieja, sincronizarla con `main` antes de abrir el PR.
- Revisar el código de los demás, incluido el generado por AI.
