---
name: code-review
description: Auditoría y checklist exhaustivo de calidad de código durante el desarrollo o antes de enviar cambios (abrir un PR o solucionar hallazgos de revisión). Evalúa bugs, seguridad, code smells, cobertura, duplicación, contratos y guía la resolución sistemática de bloqueantes con ciclo RED-GREEN. Usar al terminar una funcionalidad, refactorizar, preparar un commit previo a PR o resolver observaciones de revisión.
---

# Code Review: Checklist de Calidad & Remediación de Hallazgos

Guía oficial para auto-auditar el código durante el desarrollo o al finalizar una funcionalidad, asegurando el cumplimiento riguroso de los estándares de calidad antes de enviar cambios (abrir un PR o responder a hallazgos de revisión).

Complementa a `git-workflow`, `pr-workflow` y `quality-gates`.

---

## 1. Cuándo Ejecutar este Code Review

El agente y el desarrollador deben aplicar esta revisión en dos momentos clave:
1. **Antes de crear un nuevo PR:** Al completar una funcionalidad, bugfix o refactor, para certificar que el diff está 100% blindado y limpio.
2. **Al solucionar hallazgos de revisión:** Al abordar observaciones o bloqueantes reportados en rondas de feedback previas.

---

## 2. Checklist Exhaustivo de Calidad de Código

Usa esta lista como guía mental durante la inspección del diff o de los archivos modificados. **Solo incluye en el reporte hallazgos reales que requieran corrección**.

### 🐛 Bugs y Lógica
- [ ] Métodos o funciones añadidos que no están en el puerto/interfaz y nadie llama (código muerto).
- [ ] Firmas que violan convenciones documentadas del proyecto.
- [ ] Operaciones que reportan éxito sin verificar su resultado o efecto esperado.
- [ ] Se salta la máquina de estados o las validaciones de dominio de la entidad.
- [ ] Propagación o traducción de errores incompleta que oculta la causa relevante.
- [ ] Docblocks o comentarios que no coinciden con el comportamiento real (status codes, contratos).
- [ ] Errores de infraestructura o dependencias expuestos, ocultados indebidamente o sin trazabilidad suficiente.
- [ ] Regresiones respecto al comportamiento anterior o a issues previas.

### 🔒 Seguridad y Privacidad
- [ ] Detalles de esquema, infraestructura o implementación expuestos en mensajes públicos.
- [ ] Valores internos o datos sensibles potencialmente interpolables en respuestas o registros accesibles.
- [ ] Secretos, tokens o credenciales en el diff.
- [ ] Entradas no validadas o no escapadas que permitan inyección o ejecución no deseada.
- [ ] Falta de controles de acceso, aislamiento de datos o autorización por recurso.
- [ ] Stack traces o mensajes internos expuestos al cliente.
- [ ] Violación de políticas explícitas del repo (`CLAUDE.md`, `SECURITY.md`, `AGENTS.md`, etc.).

### 🦨 Code Smells y Mantenibilidad
- [ ] Nombres que no describen el efecto principal de una función o componente.
- [ ] Bloques de manejo de errores idénticos repetidos.
- [ ] Lógica de validación, filtrado o traducción de errores copiada en varios lugares.
- [ ] Comentarios contextuales valiosos borrados en el diff.
- [ ] Campos públicos añadidos que nadie consume todavía.
- [ ] Alcance de los cambios inconsistente con el objetivo o issue.
- [ ] Docblocks incorrectos (status HTTP, tipos, contratos, etc.).

### 🧪 Cobertura y Pruebas Automatizadas
- [ ] Archivos tocados con % bajo o 0 % de cobertura de statements/branches.
- [ ] Casos de uso o requerimientos prometidos sin prueba automatizada.
- [ ] Pruebas con dobles/mocks cuando el requerimiento exige integración real o componentes reales.
- [ ] Criterio de aceptación del issue no cumplido por falta de prueba adecuada.
- [ ] Nivel de prueba insuficiente para validar el cambio (ej. solo snapshots en lugar de aserciones de comportamiento).

### ♻️ Duplicación y Reutilización
- [ ] Bloques estructurales idénticos.
- [ ] Funciones que resuelven el mismo problema copiadas.
- [ ] Oportunidad clara de extraer un componente o función utilitaria compartida.

### 🚦 Gates y Proceso
- [ ] Los comandos de validación del proyecto pasan en verde (vía `quality-gates`).
- [ ] El análisis estático/linter aplicable no introduce advertencias nuevas.
- [ ] La suite de pruebas relevante pasa al 100%.
- [ ] Issue asociada leída y todos sus criterios de aceptación verificados.
- [ ] Diff libre de `console.log` de depuración y libre de trailing whitespaces (`git diff --check`).

---

## 3. Protocolo Sistemático para Resolver Hallazgos de Revisión

Cuando se deben corregir observaciones o bloqueantes detectados durante revisiones anteriores:

```
┌────────────────────────────────────────────────────────┐
│ 1. Triage & Análisis de Causa Raíz                     │
│    Reproducir y entender la falla señalada             │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 2. Diseño Defensivo & Contrato                         │
│    Guardas al inicio, validaciones fail-closed         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 3. Ciclo de Prueba RED ──> GREEN                       │
│    Escribir prueba que falle demostrando el bug        │
│    Ajustar código fuente hasta que pase en verde       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 4. Verificación Integral con Quality Gates             │
│    Ejecutar pipeline quality-gates (tests, types, lint)│
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ 5. Documentación y Cierre de la Corrección             │
│    Resumen de causa raíz, solución y test añadido      │
└───────────────────────────┴────────────────────────────┘
```

1. **Triage & Causa Raíz:** Aislar el escenario exacto (carreras de concurrencia, sentinels nulos/indefinidos, formato de datos, timeouts o estado residual).
2. **Diseño Defensivo:** Aplicar política *fail-closed* y guardas al inicio de los handlers para abortar operaciones inválidas sin alterar el estado.
3. **Ciclo RED $\rightarrow$ GREEN:**
   - **RED:** Crear una prueba automatizada que falle demostrando el hallazgo.
   - **GREEN:** Modificar el código hasta que la prueba pase satisfactoriamente.
4. **Quality Gates:** Correr la suite completa (`bun` o `npm` según el proyecto) y verificar `git diff --check origin/main...HEAD`.
5. **Documentación:** Documentar de forma concisa qué causaba el error, qué cambio se implementó y cuál prueba previene futuras regresiones.

---

## 4. Reglas Innegociables

1. **Auto-Revisión Obligatoria:** Nunca crear un PR ni dar por solucionado un hallazgo sin haber evaluado los puntos del checklist contra los archivos editados.
2. **Cero Suposiciones:** Todo comportamiento corregido debe estar respaldado por una prueba automatizada ejecutable.
3. **Diff Limpio:** Asegurar que no se filtren archivos temporales, código comentado innecesario o espacios en blanco al final de línea.
