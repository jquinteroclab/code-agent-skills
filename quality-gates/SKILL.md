---
name: quality-gates
description: Ejecuta y valida la suite completa de calidad local (linter, tipado estático, pruebas unitarias y de integración, build de producción) y sanitiza trailing whitespaces antes de commitear o abrir un PR. Usar al ejecutar checks locales, preparar commits, validar calidad de código o cuando el usuario pida pasar los gates de verificación.
---

# Quality Gates & Verificación de Código

Guía agnóstica para descubrir, ejecutar y validar la suite de calidad local de cualquier proyecto antes de confirmar commits (`git commit`), subir cambios a ramas remotas (`git push`) o abrir Pull Requests hacia `main`.

Alineado con el flujo de trabajo del equipo y el mandato de la sección 4 de `git-workflow`.

---

## 1. Descubrimiento Dinámico del Proyecto

En lugar de asumir comandos fijos, el agente debe inspeccionar el repositorio actual para descubrir las herramientas y scripts configurados:

### A. Detección de Runtime / Gestor de Dependencias
- Para proyectos JavaScript/TypeScript:
  - Si existe `bun.lockb`, `bun.lock` o `bunfig.toml` $\rightarrow$ Usar **`bun`** (`bun run <script>`, `bun test`).
  - En cualquier otro caso con `package.json` $\rightarrow$ Usar **`npm`** (`npm run <script>`, `npm test`).
  - *(Nota: No utilizar `yarn` ni `pnpm`)*.
- Para proyectos Python:
  - Buscar `pyproject.toml`, `requirements.txt` o `Pipfile` $\rightarrow$ Usar `pytest`, `ruff`, `mypy` según esté configurado.
- Para proyectos con `Makefile` o scripts dedicados:
  - Inspeccionar targets como `make check`, `make test`, `make lint`, `make verify`.

### B. Mapeo de los 4 Pilares de Calidad
Revisar `package.json` (sección `scripts`), `Makefile` o configuración de CI (`.github/workflows/`) para mapear cada pilar:

| Pilar de Calidad | Scripts / Comandos Típicos a Identificar | Propósito |
| :--- | :--- | :--- |
| **1. Formato & Whitespace** | `git diff --check`, `lint:format`, `format:check` | Evitar espacios en blanco sobrantes y errores de formato. |
| **2. Linter & Tipos** | `typecheck`, `check-types`, `tsc`, `lint`, `lint:fix` | Validar sintaxis, tipos estáticos y reglas del linter. |
| **3. Pruebas** | `test`, `test:unit`, `test:integration`, `test:e2e` | Asegurar que no existan regresiones en lógica de negocio. |
| **4. Compilación / Build** | `build`, `compile`, `typecheck` | Validar que los artefactos de producción compilen limpiamente. |

> Si un proyecto no cuenta con algún script específico (ej. no tiene suite de E2E o no requiere build), se omitirá ese pilar sin bloquear el flujo.

---

## 2. Pipeline de Ejecución (Fail-Fast)

Ejecutar las validaciones en orden de costo computacional (de más rápido a más pesado) para detectar y corregir problemas de inmediato:

```
┌────────────────────────────────────────────────────────┐
│ 1. Sanitización de Trailing Whitespaces                │
│    git diff --check origin/main...HEAD (o diff local)  │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 2. Linter y Análisis Estático / Tipado                 │
│    <comando-tipado> && <comando-linter>                │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 3. Pruebas Automatizadas                               │
│    <comando-pruebas-unitarias> && <comando-e2e>        │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 4. Build de Producción / Compilación                   │
│    <comando-build>                                     │
└────────────────────────────────────────────────────────┘
```

---

## 3. Sanitización de Trailing Whitespaces

Cualquier espacio en blanco innecesario al final de línea o conflicto de formato debe corregirse antes del commit:

1. Ejecutar el chequeo de diff:
   ```bash
   git diff --check origin/main...HEAD
   ```
   *(o `git diff --check` si la rama aún no se compara con `main`)*.
2. Si se detectan líneas con espacios en blanco sobrantes:
   - Limpiar los espacios finales en los archivos reportados.
   - Reejecutar `git diff --check` hasta que la salida sea 100% limpia (código de salida 0).

---

## 4. Ciclo de Diagnóstico y Corrección

Cuando un check falle durante el pipeline:

1. **Aislar la Falla:** Leer el stack trace o mensaje del linter/test para comprender la causa raíz.
2. **Corregir el Código / Prueba:** Resolver el problema en el archivo correspondiente (sin silenciar con `@ts-ignore` o `eslint-disable` injustificados).
3. **Re-ejecutar:** Correr nuevamente el comando afectado hasta que pase en verde.
4. **Validación Integral Final:** Una vez corregido, correr la cadena completa en un solo comando para confirmar que no se introdujeron regresiones colaterales.

---

## 5. Principios Innegociables

1. **Ejecución Real:** Nunca reportar un check como superado sin haber ejecutado el comando en la terminal y verificado su código de salida exitoso.
2. **Cero Commits Rotos:** Ningún commit debe realizarse si alguno de los gates falla.
3. **Mensajes Semánticos:** Una vez pasados todos los checks, generar el commit siguiendo Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`) según el propósito del cambio.
