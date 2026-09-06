#!/usr/bin/env bash
# Valida que todas las skills cumplan la plantilla canónica (docs/skill-template.md).
# Uso: scripts/validate-skills.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FAIL=0
pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=1; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

SKILLS=()
for d in */; do
  [[ -f "${d}SKILL.md" ]] && SKILLS+=("${d%/}")
done

# ── 1. Secciones obligatorias ────────────────────────────────────────────────
REQUIRED_SECTIONS=(
  "## 1. Contexto y Propósito"
  "### 1.1 Qué hace"
  "### 1.2 Qué NO hace"
  "### 1.3 Posición en el pipeline"
  "## 2. Activación"
  "### 2.1 Activar cuando"
  "## 3. Prerrequisitos y Entradas Esperadas"
  "### 3.1 Contrato de entrada"
  "## 4. Protocolo de Ejecución"
  "## 5. Contrato de Salida"
  "### 5.1 Artefacto producido"
  "### 5.2 Efectos laterales"
  "### 5.3 Estado de handoff"
  "## 6. Manejo de Errores y Edge Cases"
  "## 7. Reglas Innegociables"
  "## 8. Recursos"
)

head_ "1. Secciones obligatorias"
for s in "${SKILLS[@]}"; do
  missing=()
  for sec in "${REQUIRED_SECTIONS[@]}"; do
    grep -qF "$sec" "$s/SKILL.md" || missing+=("$sec")
  done
  if [[ ${#missing[@]} -eq 0 ]]; then pass "$s"
  else fail "$s — faltan: ${missing[*]}"; fi
done

# ── 2. Frontmatter ───────────────────────────────────────────────────────────
head_ "2. Frontmatter"
for s in "${SKILLS[@]}"; do
  fm="$(awk '/^---$/{n++; next} n==1' "$s/SKILL.md")"
  errs=()
  [[ "$(grep -m1 '^name:' <<<"$fm" | sed 's/^name:[[:space:]]*//')" == "$s" ]] \
    || errs+=("name != carpeta")
  grep -q '^description:' <<<"$fm"   || errs+=("sin description")
  grep -q '^allowed-tools:' <<<"$fm" || errs+=("sin allowed-tools")
  grep -q '^metadata:' <<<"$fm"      || errs+=("sin metadata")
  grep -qE '^  version: [0-9]+\.[0-9]+\.[0-9]+$' <<<"$fm" || errs+=("version no SemVer")
  grep -q '^  pipeline-stage:' <<<"$fm" || errs+=("sin pipeline-stage")
  grep -qi 'Does NOT' <<<"$fm"       || errs+=("description sin cláusula 'Does NOT'")
  grep -qi 'Trigger phrases' <<<"$fm" || errs+=("description sin trigger phrases")
  if [[ ${#errs[@]} -eq 0 ]]; then pass "$s"; else fail "$s — ${errs[*]}"; fi
done

# ── 3. Convención de archivos ────────────────────────────────────────────────
head_ "3. Convención de archivos (references/ vs assets/, sufijos, idioma)"
for s in "${SKILLS[@]}"; do
  errs=()
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    b="$(basename "$f")"
    [[ "$b" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?\.[a-z]+$ ]] || errs+=("$b: no kebab-case ASCII")
    case "$f" in
      */references/*)
        [[ "$b" =~ -(checklist|policy|matrix|examples|commands|protocol)\.md$ ]] \
          || errs+=("$b: sufijo no canónico en references/") ;;
      */assets/*)
        [[ "$b" =~ -template\.[a-z]+$ ]] \
          || errs+=("$b: assets/ exige sufijo -template") ;;
    esac
  done < <(find "$s" -type f ! -name SKILL.md 2>/dev/null)
  if [[ ${#errs[@]} -eq 0 ]]; then pass "$s"; else fail "$s — ${errs[*]}"; fi
done

# ── 4. Presupuesto de líneas ─────────────────────────────────────────────────
head_ "4. Presupuesto (SKILL.md <= 500 líneas)"
for s in "${SKILLS[@]}"; do
  n=$(wc -l < "$s/SKILL.md" | tr -d " ")
  if [[ $n -le 500 ]]; then pass "$s ($n líneas)"; else fail "$s ($n > 500)"; fi
done

# ── 5. Coherencia provides/consumes ──────────────────────────────────────────
head_ "5. Coherencia del grafo provides/consumes"
yaml_list() {  # $1=archivo  $2=clave
  awk -v k="  $2:" '$0==k{f=1;next} /^  [a-z-]+:/{f=0} f&&/^    - /{
    sub(/^    - /,""); sub(/ *#.*/,""); print}' "$1"
}
PROVIDED=""
for s in "${SKILLS[@]}"; do
  PROVIDED="$PROVIDED $(yaml_list "$s/SKILL.md" provides | tr '\n' ' ')"
done
for s in "${SKILLS[@]}"; do
  errs=()
  for c in $(yaml_list "$s/SKILL.md" consumes); do
    [[ " $PROVIDED " == *" $c "* ]] || errs+=("consume '$c' que nadie provee")
  done
  for r in $(yaml_list "$s/SKILL.md" requires); do
    dep="${r%%@*}"
    [[ -d "$dep" ]] || errs+=("requires '$dep' que no existe")
  done
  if [[ ${#errs[@]} -eq 0 ]]; then pass "$s"; else fail "$s — ${errs[*]}"; fi
done

# ── 6. Sincronización del checklist compartido ───────────────────────────────
head_ "6. Bloque SHARED-CHECKLIST sincronizado"
SRC=code-review/references/quality-checklist.md
COPY=pr-review/references/review-checklist.md
extract() { sed -n '/SHARED-CHECKLIST:BEGIN/,/SHARED-CHECKLIST:END/p' "$1"; }
if [[ -f "$SRC" && -f "$COPY" ]]; then
  if diff -q <(extract "$SRC") <(extract "$COPY") >/dev/null; then
    pass "code-review (fuente) == pr-review (copia)"
  else
    fail "divergencia entre $SRC y $COPY — editar en code-review y propagar"
    diff <(extract "$SRC") <(extract "$COPY") | head -20
  fi
else
  fail "falta $SRC o $COPY"
fi

# ── 7. Antipatrones ──────────────────────────────────────────────────────────
head_ "7. Antipatrones prohibidos"
for s in "${SKILLS[@]}"; do
  errs=()
  grep -rqF '$\rightarrow$' "$s" 2>/dev/null && errs+=("LaTeX en Markdown")
  grep -rqE '\bplantilla-' "$s" 2>/dev/null && errs+=("nombre de archivo en español")
  if [[ ${#errs[@]} -eq 0 ]]; then pass "$s"; else fail "$s — ${errs[*]}"; fi
done


# ── 8. Descubrimiento del instalador ─────────────────────────────────────────
# `npx skills add` descubre skills buscando carpetas con un SKILL.md dentro.
# Cualquier SKILL.md que no sea una skill real se instala como una skill fantasma.
head_ "8. Descubrimiento del instalador (npx skills add)"
errs=()
while IFS= read -r f; do
  d="$(dirname "${f#./}")"
  [[ "$d" == */* ]] && errs+=("$f: SKILL.md anidado, no es una skill de primer nivel")
  nm="$(awk '/^---$/{n++;next} n==1&&/^name:/{sub(/^name:[[:space:]]*/,"");print;exit}' "$f")"
  [[ "$nm" == "skill-name" || "$nm" == "<"* ]] \
    && errs+=("$f: name placeholder '$nm' — se instalaría como skill fantasma")
done < <(find . -name SKILL.md -not -path './.git/*')

[[ -f docs/skill-template.md ]] || errs+=("falta docs/skill-template.md")
[[ -f _template/SKILL.md ]] && errs+=("_template/SKILL.md reintroducido: el instalador lo listaría como skill")

n_found=$(find . -name SKILL.md -not -path './.git/*' | wc -l | tr -d ' ')
[[ "$n_found" -eq "${#SKILLS[@]}" ]] \
  || errs+=("hay $n_found archivos SKILL.md pero ${#SKILLS[@]} skills declaradas")

if [[ ${#errs[@]} -eq 0 ]]; then
  pass "${#SKILLS[@]} SKILL.md = ${#SKILLS[@]} skills reales; la plantilla no es descubrible"
else
  for e in "${errs[@]}"; do fail "$e"; done
fi

# ── Resultado ────────────────────────────────────────────────────────────────
printf '\n'
if [[ $FAIL -eq 0 ]]; then
  printf '\033[32mTodas las skills cumplen la plantilla canónica.\033[0m (%d skills)\n' "${#SKILLS[@]}"
else
  printf '\033[31mHay incumplimientos de la plantilla canónica.\033[0m\n'
fi
exit $FAIL
