# Checklist de revisión PR

Usa esta lista como guía mental durante el análisis del diff. No es obligatorio marcar cada ítem en el informe; solo incluye hallazgos reales.

## Bugs

- [ ] Métodos o funciones añadidos que no están en el puerto/interfaz y nadie llama (código muerto)
- [ ] Firmas que violan convenciones documentadas del proyecto
- [ ] Operaciones que reportan éxito sin verificar su resultado o efecto esperado
- [ ] Se salta la máquina de estados / validaciones de dominio de la entidad
- [ ] Propagación o traducción de errores incompleta que oculta la causa relevante
- [ ] Docblocks o comentarios del PR que no coinciden con el comportamiento real (status codes, contratos)
- [ ] Errores de infraestructura o dependencias expuestos, ocultados indebidamente o sin trazabilidad suficiente
- [ ] Regresiones respecto al comportamiento anterior o a issues previas

## Seguridad

- [ ] Detalles de esquema, infraestructura o implementación expuestos en mensajes públicos
- [ ] Valores internos o datos sensibles potencialmente interpolables en respuestas o registros accesibles
- [ ] Secretos, tokens o credenciales en el diff
- [ ] Entradas no validadas o no escapadas que permitan inyección o ejecución no deseada
- [ ] Falta de controles de acceso, aislamiento de datos o autorización por recurso
- [ ] Stack traces o mensajes internos expuestos al cliente
- [ ] Violación de políticas explícitas del repo (CLAUDE.md, SECURITY.md, etc.)

## Code smells

- [ ] Nombres que no describen el efecto principal de una función o componente
- [ ] Bloques de manejo de errores idénticos repetidos
- [ ] Lógica de validación, filtrado o traducción de errores copiada en varios lugares
- [ ] Comentarios contextuales valiosos borrados en el PR
- [ ] Campos públicos añadidos que nadie consume todavía
- [ ] Alcance del PR inconsistente con el título o con el issue
- [ ] Docblocks incorrectos (status HTTP, contratos, etc.)

## Cobertura

- [ ] Archivos tocados con % bajo o 0 % de cobertura de statements/branches
- [ ] Casos prometidos por el PR o el issue sin prueba
- [ ] Pruebas con dobles cuando el issue exige integración, extremo a extremo o componentes reales
- [ ] Criterio de cierre del issue no cumplido por falta de prueba adecuada
- [ ] Nivel de prueba insuficiente para validar el cambio

## Duplicación

- [ ] Bloques estructurales idénticos
- [ ] Funciones que resuelven el mismo problema copiadas
- [ ] Oportunidad clara de extraer un componente reutilizable

## Gates y proceso

- [ ] Los comandos de validación documentados por el repositorio pasan
- [ ] El análisis estático aplicable no introduce advertencias nuevas
- [ ] La suite de pruebas relevante pasa
- [ ] Cobertura medida cuando es relevante
- [ ] Issue asociada leída y criterios de aceptación verificados
- [ ] Decisión de `--request-changes` / `--comment` / `--approve` tomada según bloqueantes
