# Code Agent Skills

Skills agnósticas para estandarizar el flujo de Git, Pull Requests, Code Review y Quality Gates en cualquier proyecto y stack tecnológico del equipo (Python, Go, Rust, Java, Node/TS, etc.).

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

- `git-workflow`: ramas, commits y checks locales.
- `pr-workflow`: creación, revisión y merge de Pull Requests.
- `pr-review`: revisión de PRs con gates y publicación en GitHub.
- `code-review`: auditoría y checklist exhaustivo de calidad durante el desarrollo y remediación con ciclo RED-GREEN.
- `quality-gates`: validación y ejecución de la suite de calidad local (linter, tipado, pruebas y build) y sanitización de diffs.
