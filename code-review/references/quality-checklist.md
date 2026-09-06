# Checklist de Calidad de Código

> **FUENTE ÚNICA DE VERDAD.** Este archivo es propiedad de la skill `code-review`.
> `pr-review/references/review-checklist.md` mantiene una copia sincronizada del
> bloque delimitado más abajo, porque las skills se instalan de forma independiente.
> **Editar aquí; la CI (`scripts/validate-skills.sh`) falla si las copias divergen.**

Guía mental durante la inspección del diff o de los archivos modificados.
**Solo incluir en el reporte hallazgos reales que requieran corrección.** Un checklist
completo con ítems marcados "OK" no es un hallazgo: es ruido.

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

## Regla de anclaje de evidencia

Todo hallazgo debe citar `archivo:línea` verificable. Un hallazgo que no se puede
anclar a una línea concreta del diff **no se incluye en el reporte**: es una intuición,
no un hallazgo.

## Regla de severidad

| Severidad | Criterio |
| --- | --- |
| **Alto** | Rompe en runtime, expone datos, o incumple el criterio de cierre del issue |
| **Medio** | Degrada mantenibilidad o cobertura de forma medible |
| **Bajo** | Mejora deseable sin impacto funcional |

**Bloqueante** = bugs de lógica, regresiones de seguridad, incumplimiento del criterio
de cierre del issue, gates rotos, código muerto que contradice el diseño.
**No bloqueante** = code smells, mejoras menores de cobertura, docblocks, refactors sugeridos.
