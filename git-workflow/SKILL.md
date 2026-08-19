---
name: git-workflow
description: Aplica el flujo oficial de Git del equipo. Cubre estructura de ramas (solo main), convención de nombres con prefijos, Conventional Commits, checks locales obligatorios y reglas de la rama main. Usar al crear o nombrar ramas, hacer commits, correr checks antes de commit, o cuando el usuario mencione GitHub Flow, convenciones de ramas, mensajes de commit o el flujo diario de Git del equipo.
---

# Git Workflow

Flujo oficial del equipo (GitHub Flow). Aplica igual a trabajo manual y generado por AI (Claude Code, Codex, Cursor, etc.).

## 1. Estructura de ramas

- **`main`** es la única rama principal. Todo lo que está en `main` debe estar listo para desplegar.
- Las ramas de trabajo se crean desde `main`, viven poco tiempo y se eliminan después del merge.
- **No usar** `develop`, `release/*` ni `hotfix/*`.

## 2. Convención de nombres de ramas

| Origen | Prefijo permitido | Ejemplo |
| --- | --- | --- |
| Trabajo manual | `feature/`, `fix/`, `chore/`, `refactor/`, `docs/`, `test/` | `feature/crear-contacto` |
| Claude Code | `claude/` | `claude/agregar-campos-personalizados` |
| Codex | `codex/` | `codex/fix-validacion-email` |
| Otras herramientas AI | Prefijo de la herramienta | `cursor/…`, `aider/…` |

Reglas:
- Siempre en minúsculas y con guiones (`-`).
- Nombre corto y descriptivo.
- Una rama = un solo propósito o funcionalidad.

## 3. Flujo para crear rama y trabajar

### Trabajo manual

1. Actualizar `main`:
   ```bash
   git checkout main && git pull origin main
   ```
2. Crear la rama con un nombre descriptivo:
   ```bash
   git checkout -b feature/nombre-descriptivo
   ```
3. Trabajar y hacer commits siguiendo la convención de la sección 5.
4. Correr los checks locales (sección 4) antes de cada commit relevante.
5. Subir la rama:
   ```bash
   git push -u origin feature/nombre-descriptivo
   ```

### Trabajo con Claude Code, Codex u otras AI

1. La herramienta crea la rama (ejemplo: `claude/agregar-campos-personalizados`).
2. La herramienta realiza los cambios y commits.
3. **Revisión humana obligatoria**: revisar el código generado, corregir o mejorar si hace falta, y ajustar commits genéricos si es necesario.
4. El desarrollador es responsable del código que llega a `main`, aunque lo haya generado una herramienta de AI.

## 4. Checks locales antes de commitear

Identifica y ejecuta los comandos de validación, linter, análisis estático/tipado, pruebas y compilación configurados para el proyecto específico (consultando la documentación del repositorio, `Makefile`, scripts de CI, etc.).

Ejecutar y dejar en verde **antes de commitear**:

```bash
<comando-linter> && <comando-analisis-estatico-o-tipos> && <comando-pruebas> && <comando-build>
```

Nunca reportar un check como pasado sin haberlo corrido en el entorno correspondiente.

## 5. Convención de mensajes de commit

**Conventional Commits**: `tipo: descripción en imperativo`

| Tipo | Uso |
| --- | --- |
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `chore` | Mantenimiento / configuración |
| `refactor` | Mejoras de código sin cambiar comportamiento |
| `docs` | Solo documentación |
| `test` | Agregar o modificar tests |
| `style` | Formato (espacios, comas, etc.) |
| `perf` | Mejoras de rendimiento |

Ejemplos:
```
feat: agregar campos personalizados a contactos
fix: corregir validación de email en formularios
chore: actualizar dependencias
refactor: separar lógica de permisos
test: agregar tests del servicio de pipeline
docs: documentar endpoints de contactos
```

Reglas:
- Modo imperativo ("agregar", "corregir"…).
- Primera línea máximo 72 caracteres.
- Empezar con minúscula después de los dos puntos.
- No terminar con punto.

> Si Claude Code o Codex generan commits genéricos, se pueden dejar: el **Squash and merge** usará el título del Pull Request como mensaje final en `main`.

## 6. Reglas de la rama `main`

- Está protegida; nunca se hace push directo.
- Solo se llega a ella mediante Pull Request.
- Debe pasar todos los checks de GitHub Actions.
- Requiere al menos 1 aprobación.
- Debe tener al menos un revisor y un responsable asignado.
- Merge recomendado: **Squash and merge**.

## 7. Buenas prácticas

- Las ramas viven poco: idealmente menos de 2–3 días.
- Commits pequeños y frecuentes.
- Si una rama se queda vieja, actualizarla con `main` antes de abrir el PR.
- Revisar el código de los demás, incluyendo el generado por AI.
