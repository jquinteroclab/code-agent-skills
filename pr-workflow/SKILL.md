---
name: pr-workflow
description: Aplica las reglas del equipo para crear y completar Pull Requests. Cubre formato de títulos, plantilla de descripción, asignación obligatoria de revisor y assignee, y Squash and merge. Usar al abrir, rellenar o revisar un PR, asignar revisores, o cuando el usuario mencione títulos de PR, plantilla de descripción o flujo de Pull Requests.
---

# Pull Request

Reglas oficiales del equipo para crear, completar y mergear Pull Requests. Complementa el skill `git-workflow` (ramas y commits) y el skill `pr-review` (revisión de código).

## 1. Título del Pull Request

Formato obligatorio:

```
tipo: descripción corta del cambio
```

Ejemplos:
```
feat: agregar campos personalizados a contactos
fix: corregir error al guardar historial de actividades
chore: mejorar configuración de GitHub Actions
```

- Aplica también a PRs abiertos por Claude Code, Codex u otras herramientas AI (aunque la rama se llame `claude/…` o `codex/…`).

## 2. Plantilla de descripción

Todos los PRs deben usar esta estructura. Ver el archivo completo en `references/plantilla-pr.md`.

```markdown
## ¿Qué se hizo?
- Breve descripción de los cambios

## ¿Por qué?
- Motivo del cambio

## ¿Cómo probarlo?
- Pasos para verificar

## Checklist
- [ ] Tests pasan
- [ ] Se revisó el código
- [ ] No rompe funcionalidades existentes
```

Reglas:
- Completar todas las secciones de forma clara y concisa.
- En el Checklist, marcar con `[x]` lo que corresponda.
- Si el cambio es muy simple se puede resumir, pero la estructura se mantiene.

## 3. Asignación de revisores y responsables

> Cada Pull Request **debe** crearse con al menos **un revisor** y **un responsable (assignee)** asignado.

- Un PR sin revisores ni responsables **no será revisado**.
- Nunca dejes un PR sin asignar.
- El autor del PR asigna a al menos una persona del equipo como revisor y como responsable.
- Aplica igual a los PRs generados por Claude Code o Codex.

## 4. Flujo al abrir el PR

1. Abrir Pull Request hacia `main`.
2. Usar el título con formato de la sección 1.
3. Completar la plantilla de descripción.
4. **Asignar al menos 1 revisor y 1 responsable (assignee)**.
5. Esperar checks de GitHub Actions + al menos 1 aprobación.
6. Hacer **Squash and merge**.
7. Borrar la rama después del merge.

## 5. Reglas de merge

- Solo se llega a `main` mediante Pull Request.
- Debe pasar todos los checks de GitHub Actions.
- Requiere al menos 1 aprobación.
- Debe tener al menos un revisor y un responsable asignado.
- Merge recomendado: **Squash and merge**.
- Después del merge: borrar la rama.
