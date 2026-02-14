# Contributing to OvaFlus

Thank you for contributing to OvaFlus! This guide covers our development workflow and standards.

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code. Deploys automatically. |
| `develop` | Integration branch for features. CI runs on every push. |
| `feature/*` | New features. Branch from `develop`, merge back to `develop`. |
| `hotfix/*` | Urgent production fixes. Branch from `main`, merge to both `main` and `develop`. |

### Workflow

1. Create a feature branch from `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-feature
   ```
2. Make your changes and commit following the commit message format below.
3. Push your branch and open a PR targeting `develop`.
4. After review and CI passes, merge via squash merge.

## Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `chore` | Maintenance tasks (deps, config, etc.) |
| `docs` | Documentation changes |
| `refactor` | Code changes that neither fix a bug nor add a feature |
| `test` | Adding or updating tests |
| `ci` | CI/CD pipeline changes |

### Scope

Use the service or app name as scope when applicable:

- `auth-service`, `budget-service`, `transaction-service`, etc.
- `ios`, `android`, `web`, `macos`
- `infra`, `shared-types`, `ui-components`

### Examples

```
feat(budget-service): add recurring budget support
fix(ios): resolve crash on portfolio chart rotation
chore(deps): update typescript to 5.3
docs: add API authentication guide
ci: add Android build caching
```

## Pull Request Process

1. Fill out the PR template completely.
2. Ensure all CI checks pass.
3. Request review from at least one team member.
4. Address all review comments before merging.
5. Use squash merge to keep the commit history clean.

## Code Style

- **TypeScript/JavaScript**: ESLint + Prettier enforce consistent style. Run `npm run lint` before committing.
- **Swift**: Follow Swift API Design Guidelines.
- **Kotlin**: Follow Kotlin coding conventions and use ktlint.

## Testing Requirements

- All new backend features must include unit tests.
- API endpoints must have integration tests.
- Frontend components should have snapshot or interaction tests where appropriate.
- Run `npm test` in the relevant service/app directory before pushing.

## Local Development

Use the provided Makefile for common tasks:

```bash
make dev          # Start all services with Docker Compose
make test         # Run all tests
make lint         # Lint all code
make type-check   # Run TypeScript type checking
make clean        # Remove build artifacts and node_modules
```

Copy `.env.dev.example` to `.env.dev` and fill in your local configuration before running services.

## Getting Help

If you have questions about the codebase or contribution process, open a discussion or reach out to the team.
