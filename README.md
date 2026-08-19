# Code Agent Skills

Skills agnósticas para estandarizar el flujo de Git, Pull Requests y Code Review en cualquier proyecto y stack tecnológico del equipo (Python, Go, Rust, Java, Node/TS, etc.).

## Instalacion

```bash
npx skills add jquinteroclab/code-agent-skills
```

Para instalar una skill concreta:

```bash
npx skills add jquinteroclab/code-agent-skills --skill git-workflow
npx skills add jquinteroclab/code-agent-skills --skill pr-workflow
npx skills add jquinteroclab/code-agent-skills --skill pr-review
```

## Skills

- `git-workflow`: ramas, commits y checks locales.
- `pr-workflow`: creacion, revision y merge de Pull Requests.
- `pr-review`: revision de PRs con gates y publicacion en GitHub.
