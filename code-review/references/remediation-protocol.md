# Protocolo de Remediación de Hallazgos

Se aplica cuando hay que corregir observaciones o bloqueantes detectados en una
revisión previa (propia o de `pr-review`).

```
┌────────────────────────────────────────────────────────┐
│ 1. Triage y Análisis de Causa Raíz                     │
│    Reproducir y entender la falla señalada             │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│ 2. Diseño Defensivo y Contrato                         │
│    Guardas al inicio, validaciones fail-closed         │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│ 3. Ciclo de Prueba RED --> GREEN                       │
│    Escribir prueba que falle demostrando el bug        │
│    Ajustar código fuente hasta que pase en verde       │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│ 4. Verificación Integral (invocar quality-gates)       │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│ 5. Documentación y Cierre de la Corrección             │
└────────────────────────────────────────────────────────┘
```

---

## 1. Triage y causa raíz

Aislar el escenario **exacto**: condiciones de carrera, sentinels nulos o indefinidos,
formato de datos, timeouts, estado residual entre ejecuciones.

**Condición de completitud:** se puede describir el escenario que dispara el fallo en
una frase, y se puede reproducir.

> No avanzar al Paso 2 con una hipótesis sin reproducir. Corregir una causa supuesta
> produce un fix que no arregla nada y una prueba que no prueba nada.

## 2. Diseño defensivo y contrato

Aplicar política **fail-closed**: guardas al inicio de los handlers que aborten la
operación inválida **sin alterar el estado**. Ante duda, denegar.

## 3. Ciclo RED -> GREEN (innegociable)

| Fase | Acción | Condición de completitud |
| --- | --- | --- |
| **RED** | Escribir una prueba automatizada que **falle** demostrando el hallazgo | La prueba se ejecuta y falla, con `exit_code != 0` **observado** |
| **GREEN** | Modificar el código fuente hasta que la prueba pase | La misma prueba pasa, con `exit_code 0` **observado** |

**La fase RED no es opcional.** Una prueba escrita después del fix, que nunca se vio
fallar, no demuestra nada: puede estar pasando por razones ajenas al bug.

**Prohibido** ajustar la prueba para que pase en lugar de corregir el código.

## 4. Verificación integral

**Invocar `quality-gates`** — no reimplementar el pipeline aquí. Adjuntar el
`gate_report` resultante al reporte de remediación.

## 5. Documentación y cierre

Por cada hallazgo resuelto, registrar de forma concisa:

| Campo | Contenido |
| --- | --- |
| Causa raíz | Qué provocaba el fallo |
| Corrección | Qué cambió y por qué esa es la solución correcta |
| Prueba | Ruta y nombre del test que previene la regresión |
| Evidencia | `exit_code` de la fase RED y de la GREEN |

---

## Hallazgos que no se corrigen

Un hallazgo puede rechazarse motivadamente. Rechazar **no** es ignorar: se documenta
con la razón y se comunica al revisor.

| Motivo válido | Motivo inválido |
| --- | --- |
| El hallazgo parte de una premisa incorrecta (con evidencia) | "No me parece importante" |
| El fix excede el alcance del PR y se abre un issue de seguimiento | "Lo arreglamos después" sin issue |
| Es un falso positivo demostrable | Es difícil de corregir |
