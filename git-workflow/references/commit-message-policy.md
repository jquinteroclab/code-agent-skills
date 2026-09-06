# Convención de Mensajes de Commit

**Conventional Commits:** `tipo: descripción en imperativo`

---

## 1. Tipos permitidos

| Tipo | Uso |
| --- | --- |
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `chore` | Mantenimiento / configuración |
| `refactor` | Mejoras de código sin cambiar comportamiento |
| `docs` | Solo documentación |
| `test` | Agregar o modificar tests |
| `style` | Formato (espacios, comas, etc.) |
| `perf` | Mejoras de rendimiento |

Ejemplos:

```
feat: agregar campos personalizados a contactos
fix: corregir validación de email en formularios
chore: actualizar dependencias
refactor: separar lógica de permisos
test: agregar tests del servicio de pipeline
docs: documentar endpoints de contactos
```

---

## 2. Reglas verificables

| # | Regla | Verificación |
| --- | --- | --- |
| 1 | Tipo de la tabla §1 seguido de `: ` | `^(feat\|fix\|chore\|refactor\|docs\|test\|style\|perf): ` |
| 2 | Primera línea <= 72 caracteres | `${#linea1} -le 72` |
| 3 | Minúscula después de los dos puntos | `: [a-zá-úñ]` |
| 4 | No termina con punto | `[^.]$` |
| 5 | Modo imperativo ("agregar", no "agregado" ni "agrega") | Revisión |

Comprobación del asunto antes de commitear:

```bash
s="<asunto-propuesto>"
[[ "$s" =~ ^(feat|fix|chore|refactor|docs|test|style|perf):\ [a-záéíóúñ] ]] \
  && [[ ${#s} -le 72 ]] && [[ "$s" != *. ]] \
  && echo "OK: $s" || echo "RECHAZADO: $s"
```

---

## 3. Commits generados por agentes

Un commit generado por un agente cumple **exactamente las mismas reglas** que uno
manual. No existe excepción por procedencia.

> El **Squash and merge** usará el título del PR como mensaje final en `main`, pero
> eso **no autoriza** commits genéricos en la rama: el historial de la rama es la
> evidencia que lee el revisor durante el review.

---

## 4. Atribución

Los commits generados por un agente deben declararlo en el trailer, para que la
autoría sea auditable en `git log`:

```
Co-Authored-By: <Agente> <noreply@…>
```

La responsabilidad del código sigue siendo **del desarrollador humano** que lo
mergea a `main`, con independencia de quién lo escribiera.
