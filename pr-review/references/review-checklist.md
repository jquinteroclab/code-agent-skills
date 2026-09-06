# Checklist de Revisión de PR

> **COPIA SINCRONIZADA — NO EDITAR EL BLOQUE COMPARTIDO AQUÍ.**
> La fuente única de verdad del bloque delimitado por `SHARED-CHECKLIST` es
> `code-review/references/quality-checklist.md`. Se mantiene una copia porque las
> skills se instalan de forma independiente (`npx skills add --skill pr-review`).
> `scripts/validate-skills.sh` falla si ambas copias divergen.
>
> Cambios en el bloque compartido: editarlos en `code-review` y propagarlos.
> El **delta específico de revisión remota** vive al final de este archivo y sí se
> edita aquí.

Guía mental durante el análisis del diff. No es obligatorio marcar cada ítem en el
informe; **solo se incluyen hallazgos reales**, anclados a `archivo:línea`.

<!-- SHARED-CHECKLIST:BEGIN -->

## 🐛 Bugs y Lógica

- [ ] Métodos o funciones añadidos que no están en el puerto/interfaz y nadie llama (código muerto).
- [ ] Firmas que violan convenciones documentadas del proyecto.
- [ ] Operaciones que reportan éxito sin verificar su resultado o efecto esperado.
- [ ] Se salta la máquina de estados o las validaciones de dominio de la entidad.
- [ ] Propagación o traducción de errores incompleta que oculta la causa relevante.
- [ ] Docblocks o comentarios que no coinciden con el comportamiento real (status codes, contratos).
- [ ] Errores de infraestructura o dependencias expuestos, ocultados indebidamente o sin trazabilidad suficiente.
- [ ] Regresiones respecto al comportamiento anterior o a issues previas.
- [ ] Condiciones de carrera, estados inconsistentes o falta de comprobación de filas afectadas.

## 🔒 Seguridad y Privacidad

- [ ] Detalles de esquema, infraestructura o implementación expuestos en mensajes públicos.
- [ ] Valores internos o datos sensibles potencialmente interpolables en respuestas o registros accesibles.
- [ ] Secretos, tokens o credenciales en el diff.
- [ ] Entradas no validadas o no escapadas que permitan inyección o ejecución no deseada.
- [ ] Falta de controles de acceso, aislamiento de datos o autorización por recurso.
- [ ] Stack traces o mensajes internos expuestos al cliente.
- [ ] Configuraciones débiles o rutas de escalada de privilegios.
- [ ] Violación de políticas explícitas del repo (`CLAUDE.md`, `SECURITY.md`, `AGENTS.md`).

## 🦨 Code Smells y Mantenibilidad

- [ ] Nombres que no describen el efecto principal de una función o componente.
- [ ] Bloques de manejo de errores idénticos repetidos.
- [ ] Lógica de validación, filtrado o traducción de errores copiada en varios lugares.
- [ ] Comentarios contextuales valiosos borrados en el diff.
- [ ] Campos públicos añadidos que nadie consume todavía.
- [ ] Alcance de los cambios inconsistente con el objetivo, el título o el issue.
- [ ] Docblocks incorrectos (status HTTP, tipos, contratos).

## 🧪 Cobertura y Pruebas Automatizadas

- [ ] Archivos tocados con porcentaje bajo o nulo de cobertura de statements/branches.
- [ ] Casos de uso o requerimientos prometidos sin prueba automatizada.
- [ ] Pruebas con dobles/mocks cuando el requerimiento exige integración real o componentes reales.
- [ ] Criterio de aceptación del issue no cumplido por falta de prueba adecuada.
- [ ] Nivel de prueba insuficiente para validar el cambio (ej. solo snapshots en lugar de aserciones de comportamiento).

## ♻️ Duplicación y Reutilización

- [ ] Bloques estructurales idénticos.
- [ ] Funciones que resuelven el mismo problema copiadas.
- [ ] Oportunidad clara de extraer un componente o función utilitaria compartida.

## 🚦 Gates y Proceso

- [ ] `quality-gates` ejecutado con los 4 pilares en verde (o OMITIDO con evidencia).
- [ ] El análisis estático aplicable no introduce advertencias nuevas.
- [ ] Sin supresores injustificados introducidos en el diff (`ts-ignore`, `noqa`, `.skip`…).
- [ ] Issue asociada leída y todos sus criterios de aceptación verificados.
- [ ] Diff libre de trazas de depuración y de trailing whitespace (`git diff --check`).

<!-- SHARED-CHECKLIST:END -->

---

# Delta específico de revisión remota

Lo anterior es común con `code-review`. Lo que sigue **solo aplica al revisar un PR
de otra persona**, y es propiedad de esta skill.

## Contexto del PR

- [ ] Se trabaja sobre el **SHA del head** del PR, no sobre `main` ni sobre el worktree local.
- [ ] El alcance del PR es coherente con su **título** y con el issue.
- [ ] Los commits de la rama permiten seguir la evolución del cambio.
- [ ] El PR tiene revisor y assignee asignados (política de `pr-workflow`).

## Cobertura medida

- [ ] Cobertura ejecutada **acotada a los archivos del PR**, no del repo completo.
- [ ] Porcentaje de statements y branches registrado por archivo.
- [ ] Líneas sin cubrir relacionadas explícitamente con el criterio de cierre del issue.

## Anclaje de evidencia remota

- [ ] Cada hallazgo enlaza al blob de GitHub con el SHA del head:
      `https://github.com/<owner>/<repo>/blob/<SHA>/<ruta>#L<inicio>-L<fin>`
- [ ] Las cifras citadas (suites, tests, warnings, porcentajes) proceden de salida real.

> Un hallazgo sin URL verificable al blob **no se publica**. La URL es el mecanismo
> anti-alucinación: un hallazgo inventado no produce un enlace válido.

## Decisión de veredicto

| # | Pregunta | Si la respuesta es NO |
| --- | --- | --- |
| 1 | ¿Cumple el criterio de cierre del issue? | **Bloqueante** |
| 2 | ¿Gates verdes sobre el head del PR? | **Bloqueante** |
| 3 | ¿Libre de código muerto y de regresiones de seguridad? | **Bloqueante** |
| 4 | ¿Solo hay smells o mejoras menores de cobertura? | Comentario, no `--request-changes` |

- [ ] Veredicto decidido: `--request-changes` | `--comment` | `--approve`.
- [ ] Verificado que el autor del PR **no** es el usuario autenticado antes de `--approve`.
- [ ] **Confirmación explícita del usuario obtenida antes de publicar.**
