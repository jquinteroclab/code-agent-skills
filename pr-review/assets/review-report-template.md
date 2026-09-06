## Revisión — <ISSUE-ID>

**Gates verificados en local sobre `<SHA>`:** `<comando de validación>` ✅ · `<comando de análisis estático>` sobre los N archivos ✅ (sin advertencias nuevas) · `<comando de pruebas>` ✅ X suites / Y tests.

<Resumen ejecutivo de 2-4 frases: dirección del PR, puntos del issue que resuelve, hallazgos principales y qué se considera bloqueante. Debe dejar claro si el PR se puede aprobar o no.>

---

## 🐞 Bugs

### 1. <título corto y claro> — Alto | Medio | Bajo

[`archivo:línea`](https://github.com/<owner>/<repo>/blob/<SHA>/<ruta>#L123-L130) — descripción precisa del problema, por qué es un bug, impacto y propuesta de arreglo.

### 2. …

---

## 🔒 Seguridad

- **<título>** — Alto | Medio | Bajo. [`archivo:línea`](<url-al-blob>) — descripción. Indicar si filtra información, expone secretos o viola políticas del proyecto.

---

## 🦨 Code smells

| # | Dónde | Qué |
| --- | --- | --- |
| 1 | [`archivo:línea`](<url-al-blob>) | Descripción breve del smell y por qué dificulta el mantenimiento |

---

## 🧪 Cobertura

Medido con `<comando de cobertura>` acotado a los archivos del PR:

| Archivo | % Stmts | % Branch | Líneas sin cubrir |
| --- | --- | --- | --- |
| `<ruta>` | 88 | 79 | 75-93 |

<Interpretación de los huecos y relación con el criterio de cierre del issue, especialmente si exige integración o extremo a extremo.>

---

## ♻️ Duplicación

- <bloques o patrones duplicados + sugerencia concreta de refactorización>

---

## Cobertura de la revisión

**Archivos revisados:** `<N>` de `<M>`.
**No revisados:** `<lista explícita>` — <razón>. <!-- omitir esta sección si N == M -->

---

## Resumen de cambios pedidos

1. <cambio concreto> **Bloqueante**
2. <cambio concreto>
3. …
