# Tech Stack

Last Updated: YYYY-MM-DD

## Backend (if applicable)

- **Language:** [e.g., TypeScript, C#, Go]
- **Framework:** [e.g., NestJS, ASP.NET Core 8, Gin]
  - **Rationale:** [why]
- **Database:** [e.g., PostgreSQL, MongoDB]
  - **Rationale:** [why]
- **ORM/Data Access:** [e.g., Prisma, EF Core]
- **Authentication:** [e.g., Auth.js, ASP.NET Identity + JWT]
- **Validation:** [e.g., Zod, FluentValidation]
- **Testing:** [e.g., Vitest, xUnit]
- **Background Jobs:** [e.g., BullMQ, Hangfire]

## Frontend (if applicable)

- **Framework:** [e.g., React 18, Vue 3, SvelteKit]
  - **Rationale:** [why]
- **Language:** [e.g., TypeScript]
- **Styling:** [e.g., TailwindCSS, CSS Modules]
- **State Management:** [e.g., TanStack Query + Context, Redux, Pinia]
- **Routing:** [e.g., React Router v6, Next.js App Router]
- **Testing:** [e.g., Vitest + React Testing Library]
- **Build Tool:** [e.g., Vite, Next.js]

## Infrastructure

- **Containerization:** [e.g., Docker]
- **Deployment Target:** [e.g., AWS ECS, Vercel, self-hosted]
- **CI/CD:** [e.g., GitHub Actions]

## Key Libraries

| Library | Purpose | Rationale |
|---------|---------|-----------|
| [name] | [what it does] | [why chosen] |

## Development Tools

- **Linter:** [e.g., ESLint, dotnet format]
- **Formatter:** [e.g., Prettier]
- **Package Manager:** [e.g., pnpm, NuGet]

## Version Requirements

- [e.g., Node.js >= 20, .NET >= 8]

## Per-Package Commands (monorepos only)

> Fill this in only for a monorepo (multiple packages in one repo). One `_LOUIE-output/` still governs the whole repo — domains (`architecture.md` / `codebase-map.md`) carry the backend/frontend/mobile partitioning, and a feature that spans packages is still *one* feature. This table tells Nina and Ava **which package's commands to run** for a given path; work-package `Files:` scopes map the change to its package. See `_LOUIE-internals/core.md` § Monorepo Direction for the single-vs-per-product decision rule.

| Package | Path root | Install | Lint | Test | Build |
|---------|-----------|---------|------|------|-------|
| [name] | [e.g., packages/api] | [cmd] | [cmd] | [cmd] | [cmd] |
