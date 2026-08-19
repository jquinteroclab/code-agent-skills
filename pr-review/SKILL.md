---
name: pr-review
description: Revisa pull requests de GitHub con foco en bugs, seguridad, code smells, cobertura y duplicación. Usa cuando el usuario pida revisar un PR, hacer code review, analizar un diff de PR, o mencione gh pr diff, un issue asociado o subir review/aprobación en GitHub. Incluye el flujo completo de ejecución de gates locales, lectura del issue y publicación del comentario o review con plantilla estructurada.
---

# PR Review

Skill para realizar revisiones exhaustivas de Pull Requests. Produce un informe estructurado y, al final, publica el review o la aprobación en GitHub.

## Cuándo activar

- Usuario pide revisar un PR (`revisa el PR #N`, `review PR`, `analiza este diff`).
- Se menciona `gh pr diff`, un issue asociado o subir comentario/review en GitHub.

## Entrada esperada

El usuario normalmente indica:
- Número de PR y repo (`gh pr diff 12 --repo org/repo` o equivalente).
- Issue asociada (ej. `PROJ-157` o enlace al gestor de trabajo).
- Opcionalmente el commit SHA o branch base.

Si falta el número de PR o el repo, pregunta antes de continuar.

## Flujo de trabajo (obligatorio)

Ejecuta los pasos en orden. No saltes pasos críticos.

### 1. Obtener el diff y contexto del PR

```bash
gh pr diff <N> --repo <owner/repo>
gh pr view <N> --repo <owner/repo> --json title,body,baseRefName,headRefName,commits,files,author,url
```

- Guarda el SHA del head commit (ej. `9d5d154`).
- Lista los archivos tocados.

### 2. Leer el issue asociado

Usa la herramienta, CLI o enlace disponible para leer el issue (ej. `PROJ-157`):

- Objetivo del ticket.
- Criterios de aceptación / cierre.
- Acciones recomendadas o puntos pendientes.

Si no hay acceso al gestor de trabajo, pide al usuario el contenido o el enlace.

### 3. Ejecutar gates locales (cuando el código esté disponible)

En el directorio del repo (checkout del head del PR si es necesario), identifica los comandos documentados para validación, análisis estático, pruebas y cobertura. Consulta primero las instrucciones, archivos de configuración y documentación del repositorio. Ejecuta los gates aplicables y no inventes comandos.

```bash
<comando-de-validacion>
<comando-de-analisis-estatico> <archivos-del-PR>
<comando-de-pruebas>
# Opcional y recomendado cuando el proyecto lo soporte:
<comando-de-cobertura> <archivos-del-PR>
```

Registra resultados exactos (número de suites/tests, warnings, fallos). Si algún gate falla, márcalo como bloqueante.

### 4. Análisis del diff

Revisa **solo** los cambios del PR (y el contexto mínimo necesario del código existente). Clasifica hallazgos en estas categorías:

#### Bugs (Errores)
- Fallos lógicos o de funcionamiento que producirán comportamiento incorrecto en runtime.
- Código muerto / métodos inalcanzables.
- Violaciones de contratos (puertos, interfaces, convenciones documentadas).
- Regresiones respecto al comportamiento anterior o a los criterios del issue.
- Falta de comprobación de filas afectadas, race conditions, estados inconsistentes.

#### Vulnerabilidades y Seguridad
- Entradas no confiables que permitan inyección, ejecución no deseada o manipulación de datos.
- Secretos expuestos.
- Filtración de información sensible al cliente (PII, trazas, mensajes internos).
- Configuraciones débiles, controles de acceso ausentes o escalada de privilegios.
- Exposición de detalles internos de almacenamiento, infraestructura o dependencias en respuestas públicas.

#### Code Smells
- Código confuso, redundante o difícil de mantener.
- Nombres engañosos (`try*` que lanza, etc.).
- Duplicación estructural (bloques try/catch idénticos, listas blancas copiadas).
- Comentarios útiles borrados o docblocks incorrectos (status codes, contratos).
- Alcance del PR inconsistente con el título o el issue.
- Campos públicos no consumidos.

#### Cobertura de código
- Porcentaje de statements/branches de los archivos tocados.
- Líneas/casos sin cubrir que el issue o el PR prometen cubrir.
- Especial atención al nivel de fidelidad de las pruebas cuando el issue exige integración, extremo a extremo o componentes reales.
- Criterio de cierre del issue: si pide e2e o integración real, verifica que exista.

#### Duplicación de código
- Bloques repetidos dentro del PR o respecto al resto del codebase.
- Funciones de validación, normalización o traducción de errores copiadas en varios lugares.
- Oportunidades claras de extracción de componentes reutilizables.

### 5. Severidad y bloqueantes

Asigna severidad (Alto / Medio / Bajo) y decide qué es **bloqueante**:

- Bloqueante típico: bugs de lógica, regresiones de seguridad, incumplimiento del criterio de cierre del issue, gates rotos, código muerto que contradice el diseño.
- No bloqueante: code smells, mejoras de cobertura menores, docblocks, refactorizaciones sugeridas.

### 6. Generar el informe

Usa **exactamente** esta estructura (adapta secciones vacías omitiéndolas o poniendo "Ninguno"):

```markdown
## Revisión — <ISSUE-ID>
**Gates verificados en local sobre `<SHA>`**: `<comando de validación>` ✅/❌ · `<comando de análisis estático>` sobre los N archivos ✅/❌ · `<comando de pruebas>` ✅/❌ X suites / Y tests.
<Resumen ejecutivo de 2-4 frases: dirección del PR, si resuelve los puntos del issue, hallazgos principales y qué se considera bloqueante.>

---

## 🐞 Bugs
### 1. <título corto y claro> — <Alto|Medio|Bajo>
[`archivo:línea`](url-al-blob) <descripción precisa del problema, por qué es un bug, impacto y, si aplica, propuesta de arreglo.>

### 2. ...

## 🔒 Seguridad
- **<título>** — <severidad>. <descripción + referencia a archivo/línea>.

## 🧹 Code smells
| # | Dónde | Qué |
|---|---|---|
| 1 | `archivo:línea` | Descripción breve |

## 📊 Cobertura
Medido con `<comando de cobertura>` acotado a los archivos del PR (o el comando usado):
| Archivo | % Stmts | % Branch | Líneas sin cubrir |
|---|---|---|---|
| ... | ... | ... | ... |

<Interpretación de los huecos y relación con el criterio de cierre del issue.>

## 📑 Duplicación
- Descripción de bloques o patrones duplicados + sugerencia de refactor.

---

## Resumen de cambios pedidos
1. <cambio> **Bloqueante** (si aplica)
2. ...
```

Reglas de estilo del informe:
- Referencias a código con enlaces al blob de GitHub cuando sea posible (`https://github.com/<owner>/<repo>/blob/<SHA>/path#Lstart-Lend`).
- Sé concreto: cita líneas, nombres de métodos, códigos de error y mensajes relevantes.
- No inventes hallazgos. Si no hay nada en una categoría, indícalo o omite la sección.
- El resumen ejecutivo debe dejar claro si el PR se puede aprobar o no.

### 7. Publicar el review en GitHub

Al final de la revisión **siempre** sube el resultado a GitHub. Elige según el estado:

| Situación | Acción |
|-----------|--------|
| Hay hallazgos **bloqueantes** | `gh pr review <N> --repo <owner/repo> --request-changes --body "..."` |
| No hay bloqueantes pero hay comentarios útiles | `gh pr review <N> --repo <owner/repo> --comment --body "..."` |
| Todo limpio y gates verdes | `gh pr review <N> --repo <owner/repo> --approve --body "..."` |

El `--body` debe contener el informe completo generado en el paso 6 (o un resumen + enlace si es demasiado largo; preferir el informe completo).

Alternativa si se prefiere comentario normal:

```bash
gh pr comment <N> --repo <owner/repo> --body "$(cat <<'EOF'
<informe completo>
EOF
)"
```

Confirma al usuario que el review/comentario se publicó e incluye el enlace al comentario o al review.

## Plantilla de decisión rápida

- ¿Cumple el criterio de cierre del issue? → Si no, bloqueante.
- ¿Gates locales verdes? → Si no, bloqueante.
- ¿Hay código muerto o regresiones de seguridad? → Bloqueante.
- ¿Solo smells / mejoras de cobertura menores? → Comentario, no request-changes.

## Notas de ejecución

- Trabaja siempre sobre el SHA del head del PR.
- Prefiere evidencia real (salida de comandos, grep, lectura de archivos) sobre suposiciones.
- Si el repo no está clonado localmente, clónalo o usa `gh` + API para obtener el contenido necesario.
- Mantén el tono profesional, directo y orientado a acción (como el ejemplo del usuario).
- El idioma del informe debe coincidir con el del usuario (español en el flujo actual).

## Recursos

- Plantilla de ejemplo completa: ver `assets/review-template.md`
- Checklist de seguridad y code smells: ver `references/checklist.md`
