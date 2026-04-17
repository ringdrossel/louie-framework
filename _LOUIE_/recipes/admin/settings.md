A searchable, DB-backed settings store organized by section + key, with a full admin UI for browsing, filtering, editing, creating, and deleting settings at runtime.

# Settings Management

## Overview

Most applications accumulate a handful of runtime-tunable values — feature flags, thresholds, default behaviors, integration keys — that live uncomfortably between hardcoded constants and full-blown configuration systems. This recipe builds a proper home for them:

- A **DB-backed store** organized as `(section, key)` pairs with a typed value.
- An **admin UI** for browsing, filtering, searching, editing, creating, and deleting settings without a redeploy.
- A **server-side search** layer so the list stays responsive even as settings grow.

### Use this when

- The app needs values that admins/developers should change at runtime without a deploy.
- You want a clear audit surface for "what's currently configured" instead of grepping env files.
- You already have a database (any kind — SQL, NoSQL, embedded) and an authenticated admin audience.

### Do not use this for

- Secrets that must never appear in a DB (API keys, credentials) — use a secret manager or env vars. See *Variations* for a hybrid `secret` type that stores references only.
- Per-user preferences — those belong in a user-scoped table, not a global settings store.
- High-frequency, high-volume config (feature flags with millions of evaluations per second) — use a dedicated feature-flag service.

## Requirements Seed

### Functional

1. Each setting is identified by a composite key `(section, key)` — both non-empty strings, lowercase-kebab-case recommended.
2. A setting has a typed value. Supported types at minimum: `string`, `number`, `boolean`, `json`. See *Variations* for extending.
3. A setting has an optional `description` (plain text, shown in the admin UI).
4. CRUD operations: create, read, update, delete — all performed via the admin UI.
5. The admin UI shows all settings in a table with columns: section, key, value, type, description, actions (edit / delete).
6. Users can **filter by section** (dropdown: "All Sections" + one entry per distinct section).
7. Users can **search by free text** — type-ahead, debounced. The search matches against section, key, value, and description.
8. **Server-side search** whenever there is an API layer. Do not load all settings into the browser and filter client-side.
9. Delete always **confirms with the user** before executing.
10. Edit opens a **dialog** with the full setting detail. Create opens the same dialog in "new" mode.
11. All changes are persisted to the DB immediately on Save — no separate "publish" step.

### Non-Functional

- Search UX: debounce ~250ms. Show a loading indicator only if the request exceeds ~300ms.
- Type safety: the stored `value` is validated against the declared `type` before being written to the DB. A type mismatch rejects the write with a clear error.
- Concurrency: last-write-wins is acceptable. No optimistic locking unless the project specifically needs it (see *Variations*).
- Access control: delegated to the project's existing auth. The recipe assumes admin-only access to all endpoints and UI routes.

### Out of Scope

- Per-user or per-tenant settings (global only).
- Setting history / audit log (see *Variations* — often a separate recipe).
- Rollback / versioning.
- Realtime propagation to running instances (clients re-fetch on next use; cache TTL is the project's choice).
- Bulk import / export.

## Architecture Notes

### Data Model

A single table/collection named `settings` (or `app_settings` if the project uses a prefix). One logical record per setting:

| Field | Type | Notes |
|-------|------|-------|
| `section` | string | Required, non-empty. Part of the composite key. |
| `key` | string | Required, non-empty. Unique within a section. |
| `value` | string (raw storage) | Serialized form of the typed value. Parsing is determined by `type`. |
| `type` | enum / string | One of `string`, `number`, `boolean`, `json`. |
| `description` | string, nullable | Optional admin-facing note. |
| `updated_at` | timestamp | Maintained by the store. |

**Uniqueness:** composite unique constraint on `(section, key)`. In SQL: `UNIQUE(section, key)`. In Mongo: compound unique index on `{section: 1, key: 1}`.

**Value storage:** always serialized as a string in storage. Parsing happens at the service layer based on `type`. This keeps the schema portable across SQL and document stores — Sophie should validate that this fits the project's DB.

### Integration Points

- **DB layer:** uses whatever DB and ORM/driver the project's `_LOUIE-output/tech-stack.md` already specifies. Recipe is stack-agnostic; Sophie adapts the data model to the existing DB conventions (naming, migrations, indexes).
- **API layer (if applicable):** one resource, e.g. `/admin/settings`, with standard REST (list, get, create, update, delete) or equivalent in the project's RPC style. Search/filter are query parameters on list: `?section=...&q=...`.
- **Auth:** recipe does **not** implement auth. All endpoints/routes assumed to be admin-gated by existing project mechanisms. If the project has no auth, Sophie must flag this and either defer the recipe or layer it on auth (see *Variations*).
- **Frontend framework:** UI description is framework-agnostic. Nina maps the layout to the project's UI framework (React, Vue, Svelte, server-rendered templates, etc.).

### Things Sophie Should Validate

- DB of the project supports unique composite indexes (all mainstream DBs do, but flag if unusual).
- Existing auth mechanism can gate a new admin route/endpoint.
- Project's API style (REST / GraphQL / tRPC / server actions) — recipe assumes REST; adapt if different.
- Whether the project uses a migration tool — if so, the settings table goes through migrations, not ad-hoc DDL.
- Whether there is an existing admin shell (layout, nav) the settings view should plug into.

## Implementation Guidance

### Service Layer (for Nina)

Build a single service module (e.g. `settings-service`) with this surface:

- `list({section?, query?, limit?, offset?}) -> Setting[]` — filters by section and full-text query, paginates. Query matches `section`, `key`, `value`, and `description` with DB-native LIKE / regex / text-search.
- `get(section, key) -> Setting | null`
- `create(setting) -> Setting` — validates value against type, enforces uniqueness.
- `update(section, key, patch) -> Setting` — validates value against type if type changes.
- `delete(section, key) -> void`
- `distinctSections() -> string[]` — powers the section dropdown.

Validation helper: `parseValue(value, type)` and `serializeValue(value, type)`. Keep parsing logic centralized — UI, API, and service all go through it.

### API Layer (if the project has one)

- `GET /admin/settings?section=&q=&limit=&offset=` — list with server-side filter + search.
- `GET /admin/settings/sections` — list distinct sections (for the dropdown).
- `GET /admin/settings/:section/:key`
- `POST /admin/settings`
- `PUT /admin/settings/:section/:key`
- `DELETE /admin/settings/:section/:key`

Server-side search is **required** when an API exists. Debounce on the client (~250ms), send each request, cancel in-flight on a new keystroke.

### UI — Settings View (required)

**Top bar** (one row, aligned with the table below):

- **Left:** dropdown labeled "All Sections" — options are "All Sections" + each distinct section from the store.
- **Middle:** free-text search input with type-ahead. Placeholder: "Search settings…". Debounced ~250ms.
- **Right:** primary button **"+ New Setting"**. Opens the edit dialog in create mode.

**Table** (below the top bar):

| Column | Content |
|--------|---------|
| Section | `section` |
| Key | `key` |
| Value | `value` rendered by type (booleans as a badge/toggle, json truncated, long strings ellipsized) |
| Type | `type` badge |
| Description | `description` (ellipsized if long, full on hover) |
| Actions | Edit icon, Delete icon |

- Empty state: "No settings found." If filtered, add "Try a different section or clear your search."
- Loading state: table skeleton or spinner while the search request is in flight.
- Pagination: required only if the project expects >100 settings. Otherwise load the full filtered set.

### UI — Edit/Create Dialog

Header: **"Edit Setting"** (edit mode) or **"New Setting"** (create mode).

Body fields (in order):

1. **Section** — text input. In edit mode, disabled (changing the composite key requires delete + create).
2. **Key** — text input. Same disabled-in-edit rule.
3. **Type** — dropdown: `string` / `number` / `boolean` / `json`. Changing type re-validates the current value.
4. **Value** — input adapts to the selected type:
   - `string` → text input
   - `number` → numeric input
   - `boolean` → toggle or radio
   - `json` → multi-line code input with JSON syntax highlighting if the project has a code-editor component; otherwise plain monospace textarea with validation
5. **Description (optional)** — textarea, small.

Footer:

- **Left:** **Delete** button (danger style). Visible only in edit mode. Clicking triggers the confirmation flow, then closes the dialog on success.
- **Right:** **Cancel** (secondary) and **Save** (primary). Save is disabled until required fields are filled and the value parses against the chosen type.

### Delete Confirmation

Delete is never one-click. When the user clicks delete (from the table row or inside the edit dialog):

1. Show a confirmation dialog: *"Delete `<section>:<key>`? This cannot be undone."*
2. Buttons: Cancel (secondary) and Delete (danger).
3. On confirm, delete via the service / API, then remove from the list and show a transient toast "Setting deleted."

### Pitfalls

- **Don't let the UI trust the client's view of `type`.** Always re-validate on the server before writing.
- **Don't store raw booleans or numbers in the DB if you're using SQL with a string column** — stick to the serialize/parse helpers so the format is consistent.
- **Don't forget to update `distinctSections`** when the section dropdown is populated — a newly created setting in a new section must appear after create.
- **Don't swallow type-parse errors.** Surface them inline next to the Value field in the dialog.

## Test Guidance

### Service layer

- Unit tests for `parseValue` / `serializeValue` across every supported type, including edge cases (empty string, zero, negative numbers, nested JSON, unicode).
- CRUD happy path for each operation.
- Uniqueness enforcement: creating `(section, key)` twice errors.
- Type mismatch: creating a setting whose value doesn't parse for the chosen type errors.
- Search: given a seeded set, `list({q: "foo"})` returns only matching records; `list({section: "x"})` filters correctly; combined filter + search works.

### API layer (if applicable)

- Each endpoint returns the expected status codes and shapes.
- `q` and `section` query params are applied server-side (verify by sending a query that would return different results if filtered vs. unfiltered).
- Auth: endpoints reject unauthenticated / non-admin requests (regression test against the project's existing auth guard).

### UI

- Table renders all columns, including correct rendering per type (booleans as toggles, json truncated).
- Section dropdown populates from the store and adds newly created sections after a create.
- Search debounces — typing quickly issues one request, not one per keystroke.
- Delete shows confirmation; canceling does nothing; confirming removes the row.
- Edit dialog disables section/key in edit mode; enables them in create mode.
- Value input adapts to type selection.
- Save is disabled until the form is valid.

### Regression

- Create → edit → delete round-trip.
- Changing a setting's type and saving re-validates the value.
- Filtering by a section that no longer has settings (after deletion) shows the empty state.

## Variations

### `secret` type

Add a `secret` value type for credential-like values. Storage options:

1. **Encrypt at rest** with a project-level key. Admin UI shows `••••••••` and a "Reveal" button.
2. **Store a reference** to an external secret manager (AWS Secrets Manager, Vault, etc.) — the DB holds only the reference, not the value.

Prefer option 2 when a secret manager is already in the stack.

### Audit log

Add a `settings_audit` table logging every create/update/delete with timestamp, actor, before/after values. Surface as a "History" tab on the settings view. Often extracted as its own recipe (`admin:audit-log`).

### Optimistic locking

Add a `version` or `updated_at` column; include it in update requests; reject on mismatch. Use when multiple admins may edit the same setting concurrently.

### Caching for read-heavy apps

Wrap `get` in an in-process cache with a short TTL (30–60s) or a pub/sub invalidation channel. Only needed if settings are read on every request.

### Realtime UI updates

If the project has a websocket / SSE layer, push updates to connected admin clients so concurrent edits are visible without refresh. Skip otherwise.

### Grouped section dropdown

If sections grow beyond ~20, switch the dropdown to a searchable combobox or add a second dimension (category → section).

### Typed schema per section

For stricter applications, define a schema per section (e.g. `auth` section must have `session_timeout: number` and `mfa_enabled: boolean`). Adds a schema registry and reduces the settings table to a constrained set of known keys. Significant scope increase — treat as a separate recipe (`admin:typed-settings`) rather than a variation here.
