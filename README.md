# Code Agent Skills

Skills para estandarizar el flujo de Git y Pull Requests del equipo.

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
