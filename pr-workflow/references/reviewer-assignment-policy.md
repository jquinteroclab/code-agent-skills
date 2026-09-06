# Política de Asignación de Revisor y Responsable

> Cada Pull Request **debe** crearse con al menos **un revisor** y **un responsable
> (assignee)** asignado.
>
> **Un PR sin revisor ni responsable no será revisado.**

Aplica igual a los PRs generados por Claude Code, Codex u otras herramientas AI.

---

## 1. Cadena de resolución (PROHIBIDO INVENTAR)

Resolver **en este orden** y detenerse en la primera fuente que devuelva resultado:

### 1. Valor indicado explícitamente por el usuario

Es siempre la fuente de mayor prioridad.

### 2. `CODEOWNERS` sobre las rutas tocadas

```bash
ls .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS 2>/dev/null
gh pr diff <N> --name-only    # o: git diff --name-only origin/main...HEAD
```

Casar cada ruta del diff con los patrones del archivo y quedarse con los owners
correspondientes. Descartar al autor del PR si aparece.

### 3. Colaboradores del repositorio

```bash
gh api "repos/<owner>/<repo>/collaborators" --jq '.[].login'
```

Si devuelve más de un candidato y no hay criterio para elegir, **no elegir**: pasar
al paso 4 y presentar la lista al usuario.

### 4. Ninguna fuente resuelve

**PREGUNTAR AL USUARIO Y DETENER.** No crear el PR sin asignación.

---

## 2. Prohibiciones

**PROHIBIDO** inferir un login de GitHub a partir de:

- el historial de commits (`git log --format=%an` da nombres, **no** logins),
- el nombre o el email del autor,
- el nombre de la organización o del repositorio,
- convenciones aparentes (`nombre.apellido`, iniciales),
- cualquier suposición no verificada contra la API.

> Un login inventado hace que `gh pr create` falle, o —peor— asigna e interrumpe a
> una persona real equivocada. El coste de preguntar es siempre menor.

---

## 3. Verificación posterior obligatoria

`gh pr create` puede crear el PR y **fallar en silencio la asignación** si el login no
existe o no tiene permisos sobre el repositorio.

```bash
gh pr view <N> --json reviewRequests,assignees
```

Si alguno de los dos viene vacío, corregir antes de dar el PR por creado:

```bash
gh pr edit <N> --add-reviewer <login> --add-assignee <login>
```

---

## 4. Autor ≠ revisor

El autor del PR **no puede ser su propio revisor**: GitHub rechaza la petición y, aun
si la aceptara, anularía el control. Si el único candidato resuelto es el autor,
tratarlo como "ninguna fuente resuelve" (§1.4) y preguntar.

El autor **sí** puede ser el assignee (responsable de llevar el PR a término), pero
debe existir además al menos un revisor distinto.
