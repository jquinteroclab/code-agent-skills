# Code Agent Skills

Skills agnósticas para estandarizar el flujo de Git, Pull Requests, Code Review y
Quality Gates en cualquier proyecto y stack del equipo (Python, Go, Rust, Java,
Node/TS, PHP, .NET, Ruby…).

Las 5 skills cumplen una **plantilla canónica única** ([`_template/SKILL.md`](_template/SKILL.md)),
verificada en CI por [`scripts/validate-skills.sh`](scripts/validate-skills.sh).

## Instalación

```bash
npx skills add jquinteroclab/code-agent-skills
```

Para instalar una skill concreta:

```bash
npx skills add jquinteroclab/code-agent-skills --skill git-workflow
npx skills add jquinteroclab/code-agent-skills --skill pr-workflow
npx skills add jquinteroclab/code-agent-skills --skill pr-review
npx skills add jquinteroclab/code-agent-skills --skill code-review
npx skills add jquinteroclab/code-agent-skills --skill quality-gates
```

## Skills

| Skill | Etapa | Dominio | Modifica código | Toca GitHub |
| --- | --- | --- | --- | --- |
| [`git-workflow`](git-workflow/) | 1, 4 | Worktree local: ramas, commits, push | No | No |
| [`code-review`](code-review/) | 2, 7 | Auto-auditoría del diff local + ciclo RED→GREEN | **Sí** | No |
| [`quality-gates`](quality-gates/) | 3 | Descubre y ejecuta los 4 pilares de calidad | Solo para poner un gate en verde | No |
| [`pr-workflow`](pr-workflow/) | 5, 8 | Objeto PR remoto: crear, asignar, mergear | No | **Sí** |
| [`pr-review`](pr-review/) | 6 | Revisión remota del PR y publicación del veredicto | **No (read-only)** | **Sí** |

## Pipeline

```
 ① git-workflow [branch]      Rama desde main con prefijo de procedencia
        ▼  ⟨desarrollo⟩
 ② code-review [pre-flight]   Auto-auditoría del diff local; fixes RED→GREEN
        ▼                     PROVIDES: findings_resolved
 ③ quality-gates              4 pilares en verde, exit_code verificado
        ▼                     PROVIDES: gate_report   ⟲ BLOCKED vuelve a ②
 ④ git-workflow [commit]      Conventional Commit + push
        ▼                     Rechaza el commit si gate_report no está verde
 ⑤ pr-workflow [create]       Título, plantilla, revisor y assignee resueltos
        ▼                     PROVIDES: pr_number, head_sha
 ⑥ pr-review                  Informe anclado al head SHA + veredicto publicado
        ▼                     ⟲ request-changes → ⑦ code-review [remediation] → ③ → ④ → ⑥
 ⑧ pr-workflow [merge]        Squash and merge + borrar rama
```

Cada skill declara `provides` / `consumes` en su frontmatter y emite un bloque de
handoff (`STATUS` / `ARTIFACTS` / `BLOCKERS` / `NEXT`) para que el traspaso no dependa
del contexto conversacional. La CI verifica que el grafo sea coherente.

## ¿`code-review` o `pr-review`?

Son complementarias, no intercambiables:

| | `code-review` | `pr-review` |
| --- | --- | --- |
| **Rol** | Autor (auto-auditoría) | Revisor (auditoría de terceros) |
| **Momento** | Pre-push | Post-push |
| **Sujeto** | Working tree / diff local | PR remoto en el SHA del head |
| **Modifica código** | **Sí** — aplica fixes vía RED→GREEN | **No** — read-only |
| **Efectos remotos** | Ninguno | Publica el review en GitHub |
| **Requiere `gh`** | No | Sí |

Comparten el checklist de calidad: la fuente única de verdad es
[`code-review/references/quality-checklist.md`](code-review/references/quality-checklist.md);
`pr-review` mantiene una copia sincronizada del bloque marcado, más su delta de
revisión remota. La CI falla si divergen.

## Contribuir

Toda skill nueva o modificada parte de [`_template/SKILL.md`](_template/SKILL.md) y
cumple [`CONTRIBUTING.md`](CONTRIBUTING.md). Antes de abrir el PR:

```bash
./scripts/validate-skills.sh
```
