# Production Readiness

Rules that keep an app working once real data and real content arrive. Agents design against what they see in development: an empty database and short sample strings. Volume and content-length problems stay invisible until production. These rules are **on by default**. Nobody has to ask for them.

Which sections apply: **Core** always. **Web** in the standard profile. If the project profile is `game` (as passed by the invoking command, else `_LOUIE-output/runbook.md` § Project Profile; absent = `standard`), read `_LOUIE_/profiles/game/guidelines/production-readiness.md` instead of the Web section.

The numbers below are defaults. A project may change one in `architecture.md`, with a one-line reason. Do not drop a rule silently.

## Core

- **Classify every collection as bounded or unbounded.** The question is not "how many rows now?" but **"does this grow with usage?"**
  - **Bounded** (settings, enums, fixed menus, a user's handful of projects): no special handling. Do not paginate or virtualize these.
  - **Unbounded** (logs, tasks, history, messages, comments, sessions, inventories): every rule below applies.
  - Tom records the class and the expected volume after one year in `requirements.md` § Data Entities. Every later agent works from that table. When an entity is missing from it, treat it as unbounded and say so.
- **No unbounded reads.** Code never loads all rows of an unbounded collection into memory, into a response, or onto a page.
- **Data growth is not hypothetical scale.** A table that grows with usage *will* be large, so design for it from day one. Infrastructure scale (clusters, caching layers, sharding, queues) stays YAGNI.
- **Seed with volume.** Dev and test fixtures for unbounded entities hold at least ~1,000 rows, plus long strings (see Content robustness). Problems then show up in development.

## Web

### Data loading

- Every list endpoint for unbounded data is **server-side paginated**. Cursor/keyset pagination is preferred; limit/offset is acceptable.
- **No list query without a LIMIT.** Use a default page size of 25–50 and a hard maximum of 100–200. A client that asks for more gets the maximum.
- Filtering, sorting and search happen **on the server**, never on a client-side copy of the full set.
- Columns used for filtering or sorting get an **index**.
- **No N+1 queries.** Load related data with a join, a batch or a preload, never with one query per row.
- The first page loads **only what is visible**. Counts, aggregates and secondary panels load lazily, or are cached when they are expensive.

### Lists

- Virtualize any list that can exceed **~100 items**, or page it on the server or with infinite scroll.
- Debounce search and filter inputs by **250–300 ms**. Cancel or ignore stale responses.
- Lazy-load images below the fold. Give every image explicit dimensions or an aspect ratio, so the layout doesn't jump.

### Content robustness

- **Every text field has an explicit rule:** clamp (N lines), truncate with an ellipsis and show the full text on demand, or wrap. "Unspecified" is not a rule.
- User-generated text gets `overflow-wrap: anywhere`, for long URLs, IDs and unbroken strings.
- Flex and grid children that hold text get `min-width: 0`, so they can shrink instead of overflowing.
- **No fixed heights on content containers.** Use `min-height` or clamp the content instead.
- Card grids must tolerate uneven heights. Use `align-items: start`, clamp card text, or use a layout where one long card cannot stretch the whole row into white gaps.
- Design and test against the **longest plausible value**, one **long unbroken string**, and **empty, 1 and 10,000 items**.

### Responsive layout

There are three deliberate layouts, not one design that shrinks:

- **Desktop (≥ 1200 px)** uses the extra space: multiple columns, side panels, wider tables. Set a sensible max-width (~1440–1600 px), not a narrow centered column.
- **Tablet (~768–1199 px)** is a layout of its own, not a stretched phone or a squeezed desktop.
- **Mobile (< 768 px)** re-arranges content by priority for the mobile user. Primary content and the primary action come first. Secondary info is collapsed or tabbed. Touch targets are **≥ 44 × 44 px**. There are no hover-only actions.

### Loading states

- Every list and async view has a loading state and an empty state.
