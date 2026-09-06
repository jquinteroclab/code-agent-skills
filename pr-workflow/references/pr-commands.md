# Comandos Canónicos de Pull Request

**No improvisar la sintaxis de `gh`.** Estos son los comandos exactos.

---

## 0. Precondiciones

```bash
gh auth status                                   # esperado: autenticado
gh repo view --json nameWithOwner -q .nameWithOwner
git rev-parse --abbrev-ref HEAD                  # rama del PR, nunca main
git ls-remote --exit-code --heads origin "$(git rev-parse --abbrev-ref HEAD)"  # rama pusheada
gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --json number,url       # ¿ya existe un PR?
```

---

## 1. Crear el PR

```bash
gh pr create \
  --base main \
  --head "$(git rev-parse --abbrev-ref HEAD)" \
  --title "<tipo>: <descripción corta>" \
  --body-file <ruta-al-cuerpo.md> \
  --reviewer <login> \
  --assignee <login>
```

- `--body-file` sobre `--body`: evita problemas de escapado con Markdown multilínea.
- `--reviewer` y `--assignee` aceptan varios logins separados por coma.
- `--draft` si el trabajo aún no está listo para revisión.

Verificación posterior (obligatoria — `gh pr create` puede crear el PR y **fallar en
silencio la asignación** si el login no tiene permisos sobre el repo):

```bash
gh pr view <N> --json number,url,reviewRequests,assignees,isDraft
```

---

## 2. Esperar los checks

```bash
gh pr checks <N> --watch --interval 30
echo "exit_code=$?"      # 0 = todos verdes · 8 = pendientes · otro = alguno falló
```

- **Nunca** declarar los checks en verde sin la salida de este comando.
- Si el comando no termina en 15 minutos: reportar los checks pendientes por nombre y
  emitir `STATUS: PARTIAL`. No asumir el resultado.

Estado puntual, sin bloquear:

```bash
gh pr checks <N> --json name,state,link
```

---

## 3. Estado de aprobación

```bash
gh pr view <N> --json reviewDecision,reviews,mergeable,mergeStateStatus
```

| Campo | Valor requerido para mergear |
| --- | --- |
| `reviewDecision` | `APPROVED` |
| `mergeable` | `MERGEABLE` |
| `mergeStateStatus` | `CLEAN` |

---

## 4. Mergear

```bash
gh pr merge <N> --squash --delete-branch
```

- **`--squash` siempre.** El título del PR se convierte en el mensaje de `main`.
- `--delete-branch` cierra el ciclo de vida de la rama; no dejarlo para después.
- Limpiar la referencia local tras el merge:

```bash
git checkout main && git pull origin main && git branch -d <rama>
```

---

## 5. Actualizar un PR existente

```bash
gh pr edit <N> --title "<nuevo título>" --body-file <ruta.md>
gh pr edit <N> --add-reviewer <login> --add-assignee <login>
gh pr ready <N>          # sacar de draft
```

---

## 6. Códigos de salida a interpretar

| Comando | exit_code | Significado |
| --- | --- | --- |
| `gh pr checks` | `0` | Todos los checks pasaron |
| `gh pr checks` | `8` | Hay checks pendientes |
| `gh pr checks` | otro | Algún check falló |
| `gh pr merge` | `!= 0` | Leer el mensaje: falta aprobación, conflictos o checks rojos |

Nunca inferir el resultado de un comando `gh` sin haber leído su `exit_code`.
