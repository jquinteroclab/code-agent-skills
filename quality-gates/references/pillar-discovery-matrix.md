# Matriz de Descubrimiento de Pilares

Los **4 pilares** son estables; los **comandos** son variables por stack. Esta matriz
mapea uno a otro. El agente **descubre**, no asume.

---

## 1. Orden de descubrimiento

Consultar en este orden y detenerse en la primera fuente que resuelva el pilar:

1. **Instrucciones del repositorio** — `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`.
2. **Orquestador de tareas** — `Makefile`, `Justfile`, `Taskfile.yml`.
3. **Definición de CI** — `.github/workflows/*.yml`, `.gitlab-ci.yml`. Es la fuente
   más fiable: son los comandos que el repositorio ya exige en verde.
4. **Manifiesto del stack** — ver §3.
5. **Ninguna resuelve** -> el pilar es OMITIDO y requiere la evidencia de §4.

> Si CI y manifiesto discrepan, **gana CI**: es el gate real del merge.

---

## 2. Los 4 pilares

| # | Pilar | Propósito | Coste |
| --- | --- | --- | --- |
| 1 | **Formato y Whitespace** | Sin espacios sobrantes ni ruido de formato en el diff | Muy bajo |
| 2 | **Linter y Tipos** | Sintaxis, tipado estático y reglas del linter | Bajo |
| 3 | **Pruebas** | Sin regresiones en lógica de negocio | Alto |
| 4 | **Build / Compilación** | Los artefactos de producción compilan limpios | Alto |

El orden es el de ejecución: **fail-fast por coste computacional creciente**.

---

## 3. Mapeo por stack

El pilar 1 es universal en todo repositorio Git:
`git diff --check <base>...HEAD` (más el formateador del stack, si existe).

| Stack | Detección | 2 · Linter y Tipos | 3 · Pruebas | 4 · Build |
| --- | --- | --- | --- | --- |
| **JS/TS (bun)** | `bun.lockb`, `bun.lock`, `bunfig.toml` | `bun run typecheck`, `bun run lint` | `bun test` | `bun run build` |
| **JS/TS (npm)** | `package.json` sin lockfile de bun | `npm run typecheck`, `npm run lint` | `npm test` | `npm run build` |
| **Python** | `pyproject.toml`, `requirements.txt`, `Pipfile` | `ruff check .`, `mypy .` | `pytest` | `python -m build` |
| **Go** | `go.mod` | `go vet ./...`, `golangci-lint run` | `go test ./...` | `go build ./...` |
| **Rust** | `Cargo.toml` | `cargo clippy -- -D warnings`, `cargo fmt --check` | `cargo test` | `cargo build --release` |
| **Java (Maven)** | `pom.xml` | `mvn -q checkstyle:check` | `mvn -q test` | `mvn -q package` |
| **Java (Gradle)** | `build.gradle[.kts]` | `./gradlew check` | `./gradlew test` | `./gradlew build` |
| **PHP** | `composer.json` | `vendor/bin/phpstan analyse`, `vendor/bin/php-cs-fixer fix --dry-run` | `vendor/bin/phpunit` | `composer validate` |
| **.NET** | `*.csproj`, `*.sln` | `dotnet format --verify-no-changes` | `dotnet test` | `dotnet build -c Release` |
| **Ruby** | `Gemfile` | `bundle exec rubocop` | `bundle exec rspec` | `bundle exec rake build` |

> Los comandos de la tabla son **candidatos a verificar**, no comandos a ejecutar a
> ciegas. Confirmar que el script o binario existe antes de invocarlo (ej. la clave
> en `scripts` de `package.json`, el target en el `Makefile`).

### 3.1 Monorepos

Si hay más de un manifiesto, acotar el alcance a los paquetes con archivos tocados
en el diff. Declarar en el reporte qué paquetes se validaron y cuáles no.

---

## 4. Regla de Evidencia de Pilar (bloqueante)

Un pilar solo puede declararse **OMITIDO** adjuntando la evidencia de su ausencia:
el comando de búsqueda ejecutado y su salida vacía.

```bash
# Ejemplo de evidencia válida para el pilar 3 en un repo sin pruebas
rg -l --glob '!node_modules' --glob '!vendor' '_test\.|\.test\.|\.spec\.|test_'
# exit_code 1, sin coincidencias -> pilar 3 OMITIDO
```

**PROHIBIDO** declarar un pilar OMITIDO por no haberlo encontrado "a simple vista",
por resultar difícil de ejecutar, o porque falla.

> Un pilar que **existe y falla** es `STATUS: BLOCKED`. Nunca `OMITIDO`.

---

## 5. Prohibición de silenciar

Poner un gate en verde suprimiendo el diagnóstico **no es pasar el gate**.

Prohibido introducir en el diff, sin justificación escrita en el reporte:

`@ts-ignore`, `@ts-expect-error`, `eslint-disable*`, `# type: ignore`, `# noqa`,
`//nolint`, `#[allow(...)]`, `@SuppressWarnings`, `--no-verify`, `.skip` / `xit` /
`@Disabled` sobre pruebas existentes, o ampliar exclusiones en la configuración del
linter para tapar el error en curso.

Detección:

```bash
git diff <base>...HEAD -U0 | grep -nE '^\+.*(ts-ignore|ts-expect-error|eslint-disable|type: ?ignore|noqa|nolint|SuppressWarnings|\.skip\(|xit\(|@Disabled)'
```

Cualquier coincidencia debe aparecer en el reporte con su justificación, o revertirse.
